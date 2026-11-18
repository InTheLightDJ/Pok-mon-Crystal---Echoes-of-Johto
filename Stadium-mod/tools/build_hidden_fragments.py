#!/usr/bin/env python3
"""Turn Stadium's compressed code fragments into ELF sections N64Recomp can recompile.

The decomp leaves ~300 code fragments as data (PERS-SZP blobs in BinArchives), so
they aren't in its ELF. For each unique decompressed fragment this writes an .s:
  * the raw words of code + data (everything before the fragment's reloc table),
  * `.reloc` lines rebuilt from the fragment's own relocation table (the one the
    game's Memmap_RelocateFragment applies), against this blob's start symbol (or
    another fragment's, for cross-fragment references), with the fields rewritten
    to symbol-relative addends,
  * FUNC symbols: code runs from 0x20 to the end of the last function before the
    first data pointer (R_MIPS_32 locations are data); functions start at the
    header entry, at jal (R_MIPS_26) targets, and after each `jr ra` + delay slot.
Then it assembles them, links an extended ELF (the decomp's objects + these
sections, placed after the 32 MB ROM), and writes:
  * recomp/<game>/relocatable_sections_ext.txt (decomp fragments + hidden ones)
  * port/src/<game>_hidden_fragments.inc ({hash of code+data, section rom} for the
    port to recognise which blob the game just loaded).

Run in WSL from the decomp dir with its venv (crunch64):
  python3 tools/build_hidden_fragments.py MOD_ROOT GAME DECOMP_DIR ELF_NAME
"""
import hashlib
import os
import re
import subprocess
import sys

import crunch64

mod_root, game, decomp, elf_name = sys.argv[1:5]
build = os.path.join(mod_root, "build", game)
out = os.path.join(build, "hidden")            # .s files (kept with the mod)
obj_dir = os.path.join(decomp, "build", "hidden")   # .o files: linker scripts can't quote paths with spaces
os.makedirs(out, exist_ok=True)
os.makedirs(obj_dir, exist_ok=True)
rom = open(os.path.join(decomp, "build", f"{elf_name}.z64"), "rb").read()
elf = os.path.join(decomp, "build", f"{elf_name}.elf")

R_MIPS_32, R_MIPS_26, R_MIPS_HI16, R_MIPS_LO16 = 2, 4, 5, 6
RNAME = {R_MIPS_32: "R_MIPS_32", R_MIPS_26: "R_MIPS_26", R_MIPS_HI16: "R_MIPS_HI16", R_MIPS_LO16: "R_MIPS_LO16"}
EXT_ROM_BASE = 0x02000000   # hidden sections go after the 32 MB ROM


def be32(b, o):
    return int.from_bytes(b[o:o + 4], "big")


def run(*cmd, cwd=None):
    return subprocess.run(cmd, check=True, capture_output=True, text=True, cwd=cwd).stdout


# --- decomp fragments: link slot -> start symbol, and covered ROM ranges --------
slot_symbol = {}
covered = []
for line in run("mips-linux-gnu-readelf", "-S", "-W", elf).splitlines():
    m = re.search(r"\]\s+(\.fragment\d+)\s+PROGBITS\s+([0-9a-f]+)\s+([0-9a-f]+)\s+([0-9a-f]+)", line)
    if m:
        name, vram, size = m.group(1), int(m.group(2), 16), int(m.group(4), 16)
        slot_symbol.setdefault(vram & 0xFFF00000, f"{name[1:]}_TEXT_START")
for line in run("mips-linux-gnu-readelf", "-s", "-W", elf).splitlines():
    p = line.split()
    if len(p) >= 8 and re.fullmatch(r"fragment\d+_ROM_START", p[7]):
        covered.append(int(p[1], 16))

# --- find the blobs --------------------------------------------------------------
blobs = {}     # sha1 -> (first rom offset, data)
for m in re.finditer(b"PERS-SZP", rom):
    o = m.start()
    if o % 4:
        continue
    try:
        data = crunch64.yay0.decompress(rom[o + be32(rom, o + 8):o + be32(rom, o + 8) + 0x100000])
    except Exception:
        continue
    if data[8:16] == b"FRAGMENT":
        blobs.setdefault(hashlib.sha1(data).hexdigest(), (o, bytes(data)))
for m in re.finditer(b"FRAGMENT", rom):
    o = m.start() - 8
    if o % 4 or o in covered or any(c == o for c in covered):
        continue
    data = rom[o:o + be32(rom, o + 0x18)]
    # raw fragments the decomp already has start exactly at a fragmentN_ROM_START
    blobs.setdefault(hashlib.sha1(data).hexdigest(), (o, bytes(data)))


def fnv1a64(b):
    """FNV-1a 64 (the port computes the same over the RAM copy at load time)."""
    h = 0xCBF29CE484222325
    for x in b:
        h = ((h ^ x) * 0x100000001B3) & 0xFFFFFFFFFFFFFFFF
    return h


def j_target(w):
    return 0x80000000 | ((w & 0x3FFFFFF) << 2) if w >> 26 == 2 else None


def analyse(data):
    reloc_off = be32(data, 0x14)
    entry = j_target(be32(data, 0))
    base = (entry or 0x8FF00000) & 0xFFF00000
    n = be32(data, reloc_off)
    relocs = []
    for i in range(n):
        r = be32(data, reloc_off + 4 + i * 4)
        relocs.append(((r >> 24) & 0x7F, r & 0xFFFFFF))
    return base, entry, reloc_off, relocs


def text_end(data, relocs, reloc_off):
    code_offs = [o for t, o in relocs if t in (R_MIPS_26, R_MIPS_HI16, R_MIPS_LO16)]
    data_offs = [o for t, o in relocs if t == R_MIPS_32]
    limit = min(data_offs) if data_offs else reloc_off
    last_code = max(code_offs) if code_offs else 0x20
    end = None
    for off in range(0x20, limit - 4, 4):
        if be32(data, off) == 0x03E00008 and off + 8 > last_code:   # jr ra
            end = off + 8
            if off > last_code:
                break
    if end is None:
        for off in range(limit - 8, 0x1C, -4):
            if be32(data, off) == 0x03E00008:
                end = off + 8
                break
    return end or 0x20


sections = []    # (name, base, data_len, rom_off_first, sha1, code+data hash)
for sha, (rom_off, data) in sorted(blobs.items(), key=lambda kv: kv[1][0]):
    base, entry, reloc_off, relocs = analyse(data)
    tag = f"hf_{rom_off:07X}"
    words = [be32(data, i) for i in range(0, reloc_off, 4)]
    reloc_lines = []
    last_hi_sym = None      # symbol of the HI16 a following LO16 belongs to (None: absolute)
    for typ, off in relocs:
        if off + 4 > reloc_off or typ not in RNAME:
            continue
        w = words[off // 4]
        if typ == R_MIPS_32:
            target = w
        elif typ == R_MIPS_26:
            target = 0x80000000 | ((w & 0x3FFFFFF) << 2)
        elif typ == R_MIPS_HI16:
            target = (w & 0xFFFF) << 16       # only the high part; base low half is 0
        else:
            target = (w & 0xFFFF)
        if typ in (R_MIPS_HI16, R_MIPS_LO16):
            # Symbol-relative addend: base addresses have a zero low half, so only
            # the HI16 field changes (minus the slot's high half).
            if typ == R_MIPS_HI16:
                hi = w & 0xFFFF
                slot = (hi << 16) & 0xFFF00000
                if slot == base:
                    sym, sbase = f"{tag}_START", base
                elif slot in slot_symbol:
                    sym, sbase = slot_symbol[slot], slot
                else:
                    last_hi_sym = None
                    continue
                words[off // 4] = (w & 0xFFFF0000) | ((hi - (sbase >> 16)) & 0xFFFF)
                last_hi_sym = sym
            else:
                if last_hi_sym is None:
                    continue
                sym = last_hi_sym
            reloc_lines.append(f".reloc 0x{off:X}, {RNAME[typ]}, {sym}")
            continue
        slot = target & 0xFFF00000
        if slot == base:
            sym, sbase = f"{tag}_START", base
        elif slot in slot_symbol:
            sym, sbase = slot_symbol[slot], slot
        else:
            continue       # main code: absolute, no relocation needed
        rel = target - sbase
        if typ == R_MIPS_32:
            words[off // 4] = rel
        else:
            words[off // 4] = (w & 0xFC000000) | ((rel >> 2) & 0x3FFFFFF)
        reloc_lines.append(f".reloc 0x{off:X}, {RNAME[typ]}, {sym}")

    tend = text_end(data, relocs, reloc_off)
    starts = {0x20}
    if entry and base <= entry < base + tend:
        starts.add(entry - base)
    j_targets = set()        # local `j` targets: labels, not functions
    for typ, off in relocs:
        if typ == R_MIPS_26 and 0 < off and off + 4 <= reloc_off:
            w = be32(data, off)
            t = 0x80000000 | ((w & 0x3FFFFFF) << 2)
            if base <= t < base + tend:
                (starts if w >> 26 == 3 else j_targets).add(t - base)   # jal -> function
    # jump-table case labels: code addresses stored in data (R_MIPS_32)
    case_labels = set()
    for typ, off in relocs:
        if typ == R_MIPS_32 and off + 4 <= reloc_off:
            t = be32(data, off)
            if base + 0x20 <= t < base + tend:
                case_labels.add(t - base)

    def branch_target(off, w):
        op = w >> 26
        rt = (w >> 16) & 0x1F
        is_branch = (op in (4, 5, 6, 7, 20, 21, 22, 23) or
                     (op == 1 and rt in (0, 1, 2, 3, 16, 17, 18, 19)) or
                     (op == 17 and ((w >> 21) & 0x1F) == 8))
        if not is_branch:
            return None
        imm = w & 0xFFFF
        if imm & 0x8000:
            imm -= 0x10000
        return off + 4 + imm * 4

    # A `jr ra` ends a function only if nothing earlier in it branches past it, and
    # the next instruction isn't a case label of a jump table this function uses.
    off = 0x20
    reach = 0              # furthest branch target seen in the current function
    has_jr_reg = False     # current function dispatches through a jump table
    while off < tend - 4:
        w = be32(data, off)
        t = branch_target(off, w)
        if t is not None:
            reach = max(reach, t)
        elif w >> 26 == 2 and (j_target(w) or 0) - base in j_targets:
            reach = max(reach, j_target(w) - base)
        if (w & 0xFC1FFFFF) == 0x00000008 and (w >> 21) & 0x1F != 31:   # jr $reg (not ra)
            has_jr_reg = True
        if w == 0x03E00008:
            nxt = off + 8
            while nxt < tend and be32(data, nxt) == 0:
                nxt += 4
            if nxt >= tend:
                break
            if reach < nxt and not (has_jr_reg and nxt in case_labels) and nxt not in j_targets:
                starts.add(nxt)
                reach = 0
                has_jr_reg = False
            off = nxt
        else:
            off += 4
    starts = sorted(s for s in starts if 0x20 <= s < tend)
    if not starts:
        continue    # data only: nothing to recompile (the port logs it as "no code")

    # `jal 0x80000000` (field 0, nothing relocates it): a call the original link left
    # unresolved (stripped debug print); on hardware it would jump into the exception
    # vectors, so it's never run. Make it a nop so the recompiler doesn't need a target.
    for off in range(0x20, tend, 4):
        if words[off // 4] == 0x0C000000:
            words[off // 4] = 0
            reloc_lines = [l for l in reloc_lines if not l.startswith(f".reloc 0x{off:X},")]

    lines = [f"# {tag}: decompressed fragment from ROM 0x{rom_off:X}, link 0x{base:08X}",
             ".set noreorder", ".set noat", f'.section .{tag}, "ax"', ".align 4",
             f".globl {tag}_START", f"{tag}_START:"]
    func_at = {s: f"{tag}_func_{base + s:08X}" for s in starts}
    func_end = {s: (starts + [tend])[k + 1] for k, s in enumerate(starts)}
    # the header's "j main; nop": the game calls the fragment's load address
    if entry is not None and (entry - base) in func_at:
        func_at[0] = f"{tag}_header"
        func_end[0] = 8
    ends_at = {}
    for s, e in func_end.items():
        ends_at.setdefault(e, []).append(func_at[s])
    for i in range(0, reloc_off, 4):
        if i in func_at:
            nm = func_at[i]
            lines += [f".globl {nm}", f".type {nm}, @function", f"{nm}:"]
        lines.append(f".word 0x{words[i // 4]:08X}")
        for nm in ends_at.get(i + 4, []):
            lines.append(f".size {nm}, . - {nm}")
    lines += reloc_lines
    with open(os.path.join(out, f"{tag}.s"), "w") as f:
        f.write("\n".join(lines) + "\n")
    code_hash = f"{fnv1a64(data[:reloc_off]):016X}"
    sections.append((tag, base, reloc_off, rom_off, code_hash, len(starts)))

# --- assemble ---------------------------------------------------------------------
for tag, *_ in sections:
    run("mips-linux-gnu-as", "-EB", "-mips3", "-mabi=32", "-march=vr4300", "-no-pad-sections",
        "-o", os.path.join(obj_dir, f"{tag}.o"), os.path.join(out, f"{tag}.s"))

# --- extended linker script + link --------------------------------------------------
ld_in = open(os.path.join(decomp, "build", f"{elf_name}.ld")).read()
block = ["", "    /* hidden code fragments (tools/build_hidden_fragments.py) */"]
rom_pos = EXT_ROM_BASE
for tag, base, size, rom_off, h, nf in sections:
    obj = f"build/hidden/{tag}.o"
    block += [f"    .{tag} 0x{base:08X} : AT(0x{rom_pos:08X}) SUBALIGN(16)",
              "    {", f"        {obj}(.{tag});", "    }"]
    rom_pos = (rom_pos + size + 0xF) & ~0xF
i = ld_in.rindex("    /DISCARD/")
ld_out = ld_in[:i] + "\n".join(block) + "\n\n" + ld_in[i:]
ext_ld = os.path.join(decomp, "build", f"{elf_name}-ext.ld")
open(ext_ld, "w").write(ld_out)

scripts = ["build/linker_scripts/us/hardware_regs.ld", "build/linker_scripts/us/undefined_syms.ld",
           "build/linker_scripts/us/unused_syms.ld", "build/linker_scripts/common_undef_syms.ld",
           "build/linker_scripts/us/auto/undefined_syms_auto.ld", "build/linker_scripts/us/auto/undefined_funcs_auto.ld"]
ld_cmd = ["mips-linux-gnu-ld", "--no-check-sections", "--accept-unknown-input-arch", "--emit-relocs",
          "--whole-archive", "-T", f"build/{elf_name}-ext.ld"]
for s in scripts:
    ld_cmd += ["-T", s]
libultra = [l for l in os.listdir(os.path.join(decomp, "build", "lib")) if l.endswith(".a")] if os.path.isdir(os.path.join(decomp, "build", "lib")) else []
ld_cmd += ["-Map", f"build/{elf_name}-ext.map"] + [f"build/lib/{l}" for l in libultra] + ["-o", f"build/{elf_name}-ext.elf"]
subprocess.run(ld_cmd, check=True, cwd=decomp)
run("cp", os.path.join(decomp, "build", f"{elf_name}-ext.elf"), os.path.join(build, f"{elf_name}-ext.elf"))

# --- outputs for the recompiler and the port ---------------------------------------------
base_list = open(os.path.join(mod_root, "recomp", game, "relocatable_sections.txt")).read().split()
with open(os.path.join(mod_root, "recomp", game, "relocatable_sections_ext.txt"), "w", newline="\n") as f:
    f.write("\n".join(base_list + [f".{t[0]}" for t in sections]) + "\n")
rom_pos = EXT_ROM_BASE
inc = [f"// generated by tools/build_hidden_fragments.py: {len(sections)} hidden fragments",
       "// { FNV-1a 64 of the unrelocated code+data (bytes 0..relocOffset), relocOffset, section rom }"]
for tag, base, size, rom_off, h, nf in sections:
    inc.append(f"{{ 0x{h}ULL, 0x{size:X}, 0x{rom_pos:08X} }},   // {tag} link 0x{base:08X}, {nf} functions")
    rom_pos = (rom_pos + size + 0xF) & ~0xF
with open(os.path.join(mod_root, "port", "src", f"{game}_hidden_fragments.inc"), "w", newline="\n") as f:
    f.write("\n".join(inc) + "\n")
print(f"{len(sections)} unique hidden fragments, {sum(s[5] for s in sections)} functions, ext ELF linked")
