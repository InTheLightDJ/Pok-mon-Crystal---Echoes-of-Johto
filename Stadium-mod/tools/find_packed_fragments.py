#!/usr/bin/env python3
"""Find code fragments hidden in compressed blobs (PERS-SZP = header + Yay0).

Stadium keeps some code fragments (move animations, minigames...) compressed inside
BinArchives; the decomp leaves those as raw bins, so they aren't in the ELF and
N64Recomp never sees them. This lists (and with --out, extracts) every PERS-SZP blob
in the ROM whose decompressed data starts with a FRAGMENT header, plus uncompressed
FRAGMENTs no recompiled section covers.

Run in WSL with the decomp venv (crunch64):
  python3 tools/find_packed_fragments.py ROM.z64 [recomp_overlays.inl] [--out DIR]
"""
import re
import sys
import os
import crunch64

args = [a for a in sys.argv[1:] if not a.startswith("--")]
out_dir = sys.argv[sys.argv.index("--out") + 1] if "--out" in sys.argv else None
if out_dir in args:
    args.remove(out_dir)
rom = open(args[0], "rb").read()
covered = []
if len(args) > 1:
    inl = open(args[1], encoding="utf-8").read()
    covered = [(int(a, 16), int(b, 16)) for a, b in
               re.findall(r"\.rom_addr = 0x([0-9A-F]+), \.ram_addr = 0x8[0-9A-F]+, \.size = 0x([0-9A-F]+)", inl)]


def be32(b, o):
    return int.from_bytes(b[o:o + 4], "big")


def describe(data):
    j = be32(data, 0)
    link = 0x80000000 | ((j & 0x3FFFFFF) << 2) if j >> 26 == 2 else 0
    return {"link_entry": link, "reloc_off": be32(data, 0x14), "size_in_rom": be32(data, 0x18),
            "size_in_ram": be32(data, 0x1C)}


found = []
for m in re.finditer(b"PERS-SZP", rom):
    o = m.start()
    if o % 4:
        continue
    hdr = be32(rom, o + 8)
    try:
        data = crunch64.yay0.decompress(rom[o + hdr:o + hdr + 0x100000])
    except Exception:
        continue
    if data[8:16] == b"FRAGMENT":
        found.append(("szp", o, data))

for m in re.finditer(b"FRAGMENT", rom):
    o = m.start() - 8
    if o % 4 or any(s <= o < s + z for s, z in covered):
        continue
    size = be32(rom, o + 0x18)
    found.append(("raw", o, rom[o:o + size]))

if out_dir:
    os.makedirs(out_dir, exist_ok=True)
by_link = {}
for kind, o, data in found:
    d = describe(data)
    by_link.setdefault(d["link_entry"] & 0xFFF00000, []).append(o)
    print(f"{kind} rom 0x{o:07X}  entry 0x{d['link_entry']:08X}  len 0x{len(data):X}  "
          f"relocOff 0x{d['reloc_off']:X}  sizeInRom 0x{d['size_in_rom']:X}  sizeInRam 0x{d['size_in_ram']:X}")
    if out_dir:
        with open(os.path.join(out_dir, f"frag_{o:07X}.bin"), "wb") as f:
            f.write(data)
print(f"{len(found)} hidden fragments; link slots: " +
      ", ".join(f"0x{k:08X} x{len(v)}" for k, v in sorted(by_link.items())))
