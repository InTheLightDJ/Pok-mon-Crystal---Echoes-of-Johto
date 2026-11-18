# Pokémon Stadium 1 & 2 — native PC port for Echoes of Johto

Goal: play Pokémon Stadium (N64) and Pokémon Stadium 2 (N64) from inside
Echoes of Johto, each from its own event script call (as the Pinball games:
`pbPokemonPinball` / `pbPokemonPinballRS`).

## Decisions (2026-11-16)
- **Native PC port**, not a bundled emulator. N64 is far too heavy to
  recompile into Ruby the way Pinball was (3D, 93 MHz MIPS, RSP/RDP), so the
  game code is statically recompiled to C and built into a native program.
- **Later goal, keep in mind from the start: Pokémon transfer.** Take Pokémon
  from the player's Essentials save into Stadium, play, and transfer them back.
  Stadium reads Pokémon through the N64 Transfer Pak from a Game Boy cartridge
  (Stadium 1: Red/Blue/Yellow, Stadium 2: also Gold/Silver/Crystal). Plan: the
  port's Transfer Pak is fed a Gen 1 / Gen 2 save the game writes (party/box
  converted from Essentials Pokémon), and after Stadium closes the game reads
  that save back (anything changed / traded comes home). Needs the matching GB
  ROM (the Transfer Pak checks the cartridge header) and a clear rule for what
  can't convert (moves, abilities, species past Gen 2). Design the Transfer Pak
  layer of the runtime so the cartridge / save can be swapped from outside.

## ROMs (verified)
| Game | File | MD5 | Decomp |
|---|---|---|---|
| Pokémon Stadium (US 1.0) | decomp/pokestadium-master/baseroms/us/baserom.z64 | ed1378bc12115f71209a77844965ba50 | matches |
| Pokémon Stadium 2 (US)   | decomp/pokestadiumgs-master/baseroms/us/baserom.z64 | 1561c75d11cedf356a8ddb1a4a5f9d5d | matches |
Originals: Downloads/Pokemon Stadium (USA).zip, Pokemon Stadium 2 (USA).zip.
Decomps (pret, WIP: still some .s): Downloads/pokestadium-master.zip, pokestadiumgs-master.zip.

## Approach (the Zelda64Recomp route)
1. Build each decomp in WSL (Ubuntu) to a matching ROM -> an ELF with every
   function's symbol (splat yamls + the matching build). Check the md5.
2. N64Recomp (static recompiler): ELF + symbols -> C, one function each.
   Overlays / code loaded at run time need their own sections in the config.
3. N64ModernRuntime (ultramodern + librecomp): the libultra OS (threads,
   messages, timers, PI/SI/VI), controller input, saves (EEPROM / SRAM /
   FlashRAM as the game uses), audio out. The Transfer Pak goes here (see above).
4. RT64: the RDP/RSP graphics (F3DEX microcode family) on the GPU (D3D12 / Vulkan).
   Audio microcode: replaced in C (as Zelda64Recomp).
5. A launcher exe per game; the Essentials plugin starts it (full screen /
   borderless over the game window), waits, and resumes. Later: the transfer save.

## Machine
- Windows 11, RTX 4060 Ti, D: 40 GB free (C: 663 GB).
- Have: git, CMake, Ninja, Python 3.12, Visual Studio Community 2026 (MSVC C++).
- Need (user installs, admin): WSL + Ubuntu; VS components "C++ Clang Compiler
  for Windows" + "MSBuild support for LLVM (clang-cl) toolset".

## Status
- 2026-11-16: workspace set up, decomps unpacked, ROMs placed and verified.
- 2026-11-16: VS Clang installed. WSL enabled, Ubuntu install pending a reboot
  (`wsl --install -d Ubuntu` again after it if `wsl -l -v` shows none).
  N64Recomp cloned to tools/N64Recomp (598ce20, with submodules), not built yet:
  Claude Code's permission check blocked running the CMake build; the user needs
  to allow it (or run it). Build (VS dev prompt or plain shell):
    cmake -S tools/N64Recomp -B tools/N64Recomp/build -G "Visual Studio 18 2026" -A x64 -T ClangCL
    cmake --build tools/N64Recomp/build --config Release
- 2026-11-16: N64Recomp built (Release + an ASan copy in build-asan for crashes).
  Permission rules for cmake/ninja/msbuild/wsl in v21/.claude/settings.local.json.
- 2026-11-16: **Stadium 1 decomp builds in WSL and matches** (build/stadium1:
  pokestadium-us.z64 md5 ed1378bc..., .elf with --emit-relocs, .map). WSL copy:
  ~/stadium/pokestadium. Note: `make init` stops at extract because the asset
  scripts use the system python3: run `source .venv/bin/activate` first, then
  `make extract && make -j32`.
- 2026-11-16: **Stadium 1 recompiles to C**: 7,598 functions, 41 files
  (build/stadium1/RecompiledFuncs + funcs.h, lookup.cpp, recomp_overlays.inl).
  Run: `tools/run_recomp.ps1 stadium1 pokestadium-us` (in PowerShell).
  ELF facts: .text (main, 0x80000400) + 77 relocatable fragments (the game's
  own loader relocates them; .rel.fragmentN sections) + .boot.
  Config: recomp/stadium1/us.toml (hand-written) -> tools/gen_manual_funcs.py ->
  us.gen.toml. The generator adds: functions defined only by address
  (osGbpakReadWrite), sizes for zero-sized FUNC symbols that are called (jal/bal/j;
  others are jump-table case blocks and must stay unsized), and stubs for
  recomp/stadium1/stub_ranges.txt.
  Stubbed for now: __LeoBootGame3 (64DD boot), set_watch_lohi (debug watchpoint),
  and fragment1's hand-written asm = **the Game Boy emulator's CPU core (GB Tower)**:
  its routines branch into each other, which N64Recomp can't split. GB Tower
  needs that core rewritten in C (or a C GB core plugged in) later. The
  Transfer Pak functions (osGbpak*, main code, C) are recompiled normally.
  **N64Recomp patches** (tools/N64Recomp/src, marked "[Stadium-mod patch]"):
  1. main.cpp: skip a static function outside its section / past the ROM (crash).
  2. elf.cpp: relocation types past R_MIPS_GPREL16 (R_MIPS_PC16 from
     --emit-relocs) -> R_MIPS_NONE (crash: reloc_names[] out of range).
  3. recompilation.cpp: `bltzal $zero, X` (hand asm reading the PC) -> just
     `ra = pc + 8`, no call (X is a data table).
  Helpers: tools/inspect_elf.sh, syms_range.sh, disasm_range.sh, reloc_types.sh (WSL).
- 2026-11-16: RSP microcodes recompiled (RSPRecomp, recomp/stadium1/rsp/*.toml ->
  build/stadium1/rsp/): aspMain (audio, ROM 0x68020 size 0xC60, the game's
  &aspMainTextStart) and njpgdspMain (JPEG, ROM 0x68C80 size 0xAF0). Graphics are
  F3DEX2 (ROM 0x66C90), which RT64 runs itself. If audio stops with an unknown
  jr target at run time, add it to extra_indirect_branch_targets (as Zelda's).
  Save type: FlashRAM (osFlash*), plus EEPROM reads.
  Cloned tools/N64ModernRuntime (e4342ae, its start() takes a Configuration:
  newer than Zelda's) and tools/Zelda64Recomp (b65c482, reference for the host:
  src/main/main.cpp, register_overlays.cpp, rt64_render_context.cpp; its
  lib/rt64 is the renderer). The Stadium host is written against the current
  N64ModernRuntime API, Zelda only as a reference.
- 2026-11-16: **Host program** `port/` (CMake, VS2026 ClangCL):
    cmake -S port -B port/build -G "Visual Studio 18 2026" -A x64 -T ClangCL
    cmake --build port/build --config Release --target Stadium1
  Uses tools/N64ModernRuntime (e4342ae: same N64Recomp as our recompiler, new
  `recomp::Configuration` API) + RT64 from tools/Zelda64Recomp/lib/rt64 + SDL2
  2.30.3 (fetched). No launcher UI: `Stadium1.exe baserom.z64` checks the ROM
  (XXH3 0x6E46EACF8F27011D, "POKEMON STADIUM"; Stadium 2 = 0x13DE5F210AA8D502,
  "POKEMON STADIUM 2"), librecomp stores it in %LOCALAPPDATA%\EchoesOfJohto-Stadium1,
  later starts need no path. src: main.cpp (game entry, FlashRAM, callbacks),
  render.cpp (RT64 context, from Zelda's minus texture packs), audio.cpp (SDL
  queue), input.cpp (keyboard = P1, SDL controllers P1-4, F11 fullscreen),
  register_overlays.cpp, fragments.cpp.
  **Fragments** (src/3FB0.c, memmap.c): linked at 0x81000000-0x8FFFFFFF, id =
  ((vram & 0x0FF00000) >> 20) - 0x10 (one id, 0x82800000, has two fragments);
  the game copies one into a heap block, relocates it in place, and records it with
  Memmap_SetFragmentMap(id, ram, sizeInRam); freed -> Memmap_ClearFragmentMemmap(id).
  us.toml [[patches.hook]] on both -> stadium_fragment_loaded/unloaded (fragments.cpp)
  -> librecomp load_overlays/unload_overlays (id + size pick the section). The game
  calls a fragment at its load address (header "j main; nop"): gen_manual_funcs.py
  adds a `fragmentN_entry` function (8 bytes) at each fragment start.
  Fragment headers jump to the fragment's main function (anywhere in it); the
  generator reads that `j` from the ELF bytes. 70 entry stubs; fragment30
  (0x88A00000) jumps into slot 0x88F00000, left out for now.
  Game function `fabsf` clashes with <math.h>: [patches] renamed = ["fabsf"].
- 2026-11-16: **Stadium1.exe builds and links.** src/ultra_stubs.cpp: libultra calls the
  runtime lacks (__osContRamRead/Write, __osPfsGetStatus, osPfsIsPlug = "no pak";
  osLeoDiskInit, osEPiWriteIo, __osSet{SR,Cause,Count,Compare}, osDpGetCounters).
  **The Transfer Pak goes in __osContRamRead/Write** later (osGbpak* call them).
  First run: ROM accepted and stored, then an access violation with no output.
  Added src/crash.cpp (symbolized stack to stderr + crash.txt) and /Zi + /DEBUG
  for Release.
- 2026-11-16: **Boot fixes** (run with `& tools\run_port.ps1 [seconds]`; set
  STADIUM_LOG_FRAGMENTS=1 for fragment load logs):
  * 64DD: hook LeoCJCreateLeoManager -> returns 41 (no drive).
  * Saves: SaveType::AllowAll (boot probes SRAM and EEPROM besides FlashRAM).
  * Direct hardware access: main.cpp map_hardware_windows (on_init_callback) makes
    rdram+0x24000000 (0xA4xxxxxx registers, zeroed = idle) and rdram+0x30000000
    (0xB0000000 cartridge ROM, in RDRAM word order) real memory. Copy checks in
    main code and fragments 0x822/0x82D/0x842 read ROM 0xE38/0xD10 this way.
    Game_DoCopyProtection hook kept as well.
  * Audio manager reads AI_LEN_REG directly: instruction patch + hook ->
    stadium_ai_len() (runtime's queued audio bytes).
  * aspMain (standard libultra audio ucode): extra_indirect_branch_targets = the
    command table (first 16 halfwords of aspMainData, ROM 0x7F670); 0x02B0 there
    is 0x12B0 (12-bit RSP PC).
  * fragment31 (0x81000000) starts with a table of 60 "j target; nop" slots (decomp:
    unk_table textbin), targets in other fragments too. fragments.cpp registers a
    thunk per slot (add_loaded_function) that resolves the link address to where the
    target fragment is loaded now. Same for header jumps into a slot.
  Now boots through the audio thread, fragments 0x820/0x814/0x878/0x879/0x86B/0x810.
  **Blocker: hidden code fragments.** The game then loads and calls a fragment with
  id 0xEF (link 0x8FF00000) that isn't in the ELF. tools/find_packed_fragments.py
  (WSL venv: crunch64) finds **298 code fragments the decomp left as data**:
  PERS-SZP (header + Yay0) blobs inside BinArchives (late_assets_*, e.g. ROM
  0x15215E0...0x15A3C40), 294 of them linked at 0x8FF00000 (move animations /
  per-scene code?), + 0x87000000, 0x8C000000, 0x8C200000, 0x8D000000, and one raw
  at ROM 0x1206400. A BinArchive: u32 id (0xEF), ?, total size, count, then 16-byte
  entries (offset, size) from +0x20; func_8000484C(archive, n) decompresses file n
  and, if it's a FRAGMENT, relocates it under the archive's id.
  **Plan:** (1) extract + dedupe the decompressed blobs; (2) per blob, an .s with the
  raw words + `.reloc` lines from the fragment's own reloc table (targets inside the
  blob: section symbol + offset; main code: absolute, no reloc; other fragments:
  their section symbol) and FUNC symbols (entry, jal/R_MIPS_26 targets, code
  pointers; text end via spimdisasm's function analysis); (3) assemble, link into
  the ELF as extra sections (after the ROM, at 0x8FF00000 etc.) so N64Recomp
  treats them as more relocatable fragments; (4) fragments.cpp identifies which
  blob was loaded by hashing the unrelocated RAM bytes at Memmap_SetFragmentMap
  (several share id + size) -> its section -> load_overlays.
- 2026-11-16: **Hidden fragments recompiled; Stadium 1 reaches the title screen.**
  tools/build_hidden_fragments.py (WSL, decomp venv; run from anywhere):
    python3 tools/build_hidden_fragments.py MOD_ROOT stadium1 ~/stadium/pokestadium pokestadium-us
  -> build/stadium1/hidden/hf_<rom>.s (kept), ~/stadium/pokestadium/build/hidden/*.o
  (linker scripts can't take paths with spaces), build/pokestadium-us-ext.{ld,elf,map}
  (the decomp's script + the hidden sections before /DISCARD/, LMA from 0x02000000),
  copied to build/stadium1/pokestadium-us-ext.elf; recomp/stadium1/relocatable_sections_ext.txt;
  port/src/stadium1_hidden_fragments.inc ({FNV-1a64 of bytes 0..relocOffset, relocOffset, rom}).
  222 unique code blobs (65 more are data-only: skipped, the port logs "no code").
  Function detection: code ends at the last `jr ra` before the first R_MIPS_32
  location (data); functions start at jal targets and after a `jr ra` unless an
  earlier branch of the same function reaches past it, or it's a jump-table case
  label of a function with `jr $reg`, or a local `j` target. `jal 0x80000000`
  (unresolved in the original link, dead) -> nop.
  us.toml now uses pokestadium-us-ext.elf + relocatable_sections_ext.txt; run
  `& tools\run_recomp.ps1 stadium1 pokestadium-us-ext`. 14,977 functions.
  fragments.cpp: find_hidden() hashes the RAM copy (unrelocated at that point) ->
  section by rom; decomp fragments still by id + size (hidden ones never by id).
  tools/shot_port.ps1 -At 6,15,30: runs the port and saves window screenshots to
  port/build/shots. At ~30 s: the Pokemon Stadium title screen (JPEG via njpgdspMain).
- 2026-11-16: **Menus work.** Start on the title hung: DDC0.c func_8000D2B4
  busy-waits on func_800484E0 (sound voices still playing); the runtime's game
  threads are cooperative, so the audio thread never ran. Hook: func_800484E0 starts
  with yield_self_1ms(rdram). Now: title -> "Please Select" menu -> Pokemon Stadium
  hub (screenshots). Thin line seams on the menu panels (RT64 upscaling?) to check.
  Tools: shot_port.ps1 -Press "32:Enter","40:X" (keys: Enter X C Z Space arrows Q E);
  STADIUM_DUMP_AT=<s> writes threads.txt (every thread's stack) for hangs.
- 2026-11-16: **Battle Now team select works; battle screen doesn't render yet.**
  * Testing without touching the user's desktop: STADIUM_INPUT="33:start,42:a,..."
    (port/src/input.cpp presses P1 buttons itself; a b z start l r up down left right
    su sd sl sr cu cd cl cr); when set, the window opens off-screen without focus.
    shot_port.ps1 -At ... -Buttons "..." captures with PrintWindow(PW_RENDERFULLCONTENT).
    Battle Now script: "33:start,35:start,42:a,46:left,48:a,52:a,55:a,58:a,62:a,66:a,70:b,72:cu,78:a,82:a"
    (A/B/C-up pick three different rentals; then A confirms).
  * fragments.cpp keeps every loaded fragment by RAM range (many id-0xEF archive
    fragments are in RAM at once; the old id-keyed map unloaded live ones ->
    "Failed to find function"). A load drops only what it overlaps; Clear(id) drops
    that id's latest.
  * gen_manual_funcs.py sizes every zero-sized FUNC in main .text (called through
    pointers, e.g. music driver func_80048AFC), except recomp/stadium1/no_size.txt
    (data / bad splits: func_8004867C, func_80048738).
  * Debug: STADIUM_DUMP_AT=<s> also writes rdram.bin (N64 byte order, 8 MB);
    render.cpp logs [gfx] microcode changes and display lists per 5 s.
  **Open issue:** entering the battle (~85 s in the script) the display lists stop
  (≈30/s before, 0 after) while VIs, input reads and the game thread continue; screen
  shows a stale small framebuffer (black + garbage top-left). Only F3DEX2 is used.
  Game thread waits in func_80001B7C (frame done) inside battle code func_84301A2C;
  gfx thread (dp_intro.c func_8000183C) waits for VTRE; game scheduler 5580.c
  (D_800A62E0: unk_A14 running task, A18 audio, A1C gfx, A20/A24 pending; unk_A38 = 0).
  Suspects: a task/DP-done message the runtime never sends (osDpSetStatus 0x3C0 /
  task type 4 handling / DP event 9 -> func_80005148), or the battle's first gfx task
  submitted through a path ultramodern drops.
  Findings (2026-11-16, later): it's a **timing race**, not missing code.
  * Scheduler trace hooks (us.toml on func_800053B4 submit, func_800049D4 start,
    func_80005084 SP done, func_80005148 DP done) -> port/src/trace.cpp, written to
    trace.txt (buffered) when STADIUM_TRACE is set; audio tasks skipped. Printing to
    unbuffered stderr slowed the game to ~6 fps and changed its behaviour.
  * Normal gfx cycle: submit(state 0) -> start -> sp_done with state 2 (the scheduler
    asked the gfx task to yield for audio; ultramodern ignores yields and
    osSpTaskYielded returns 0, so it counts as finished) -> dp_done -> next submit.
  * With the buffered trace on, the battle's display lists keep coming (~30/s, new
    DL address 0x80209520) but the screen still shows the stale image; without it
    they stop. VI log ([vi] lines from render.cpp update_screen): menus triple-buffer
    origins 0x3DA500 / 0x3B4C80 / 0x38F440 (320 wide); battle briefly sets 640-wide
    hi-res (xscale 0x400, yscale 0x02000800, origin 0x369F80); "no frame ready"
    shows yscale 0 + origin 0x3FFAC0 (osViRepeatLine). The swaps stop in battle.
  **Root cause found (2026-11-16, round after):** RDP-done events go missing.
  Trace counts over ~40 s: 388 gfx submits, 388 SP-done, only ~90 DP-done; the
  runtime's dp_complete counter (debug print in tools/N64ModernRuntime/ultramodern/
  src/events.cpp dp_complete, STADIUM_TRACE only) matches ~90 = gfx tasks that
  actually reached RT64. So ~3/4 of the gfx tasks the game "starts" never reach the
  renderer. Each one leaves the scheduler's gfx slot (D_800A62E0.unk_A1C) waiting for
  a DP-done forever (start called every VI with state 3, 1E 1) -> frame never ends.
  In menus it recovers somehow; in battle it locks up.
  Mechanism suspected: the yield/resume path. 5580.c func_80004AB4 yields the gfx
  task when audio is due (state 2); ultramodern ignores osSpTaskYield and its
  osSpTaskYielded returns 0. When the scheduler then restarts a task with state 2
  (func_800049D4: osSpTaskLoad + StartGo again), libultra's resume path reads the
  DL pointer from the yield buffer, which the runtime never writes.
  Experiments (both reverted, they crash RT64 at boot reading a bad DL pointer):
  (a) hook func_80004AB4 -> return 0 (never yield) [kept in us.toml, commented out];
  (b) ultramodern gfx thread: sp_complete() after send_dl instead of before.
  Next: log every osSpTaskStartGo (task ptr, type, data_ptr, flags incl.
  OS_TASK_YIELDED) in librecomp sp.cpp to see which starts never reach the gfx
  thread and which carry bad DL pointers; then either filter resubmits of a task
  already processed, or emulate yield properly (Yielded=1 + keep the DL pointer).
  Also: trace the frame handshake (dp_intro.c func_8000183C/func_800015A8:
  unk_A8C/A9C/AAC frame slots, func_80001444 submit) and the game thread's
  func_80001B7C wait, with frame numbers; check whether the 640x480 battle intro
  frame is rendered by RT64 at all (hi-res framebuffer); consider making
  osSpTaskYield behave (run audio first) as the scheduler expects.
  Then: audio check, line seams, GB Tower / Transfer Pak, Essentials launcher, Stadium 2.
- 2026-11-16 (later): **Freeze root cause found and fixed: it was the port's own logging.**
  osSpTaskStartGo logging (librecomp sp.cpp, trace "startgo") + gfx-thread logging
  (events.cpp, "gfxrun", "gfxslow") showed every gfx task does reach the renderer;
  the yield theory above was wrong. The gfx thread spent 40-330 ms per
  ScreenUpdateAction: render.cpp update_screen printed a "[vi]" line to unbuffered
  stderr every frame (origin changes every frame), and with stderr redirected each
  write blocked for tens of ms. Gfx tasks then ran 100+ ms after the game sent them,
  by which time the game had reused the memory their sub-display-lists live in
  (decoded from rdram.bin: G_DL 0x8020A040 -> image data) -> RT64 walked garbage:
  crash in RSP::branchZ (garbage vertex index) / Interpreter::processDisplayLists, or
  a "hang" (the earlier "experiment" crashes were this too, not the experiments).
  Fix: per-frame [vi]/[gfx] logs now go to the buffered trace.txt.
  Result: no more scheduler stall; ~30 display lists/s all the way into battle.
  Crash handler now also writes rdram.bin + prints the rdram base.
  Debug aid: python tools/dlwalk.py rdram.bin <dl addr hex> [max] [v] walks an F3DEX2 DL
  (microcode is "F3DEX fifo 2.06" = F3DEX2).
  **Open (battle):** after "Is this OK? -> Yes" (VI back to 320 wide at ~78 s) the
  screenshots show black with a small garbled patch top-left (may be a capture
  artifact: off-screen window), and one run crashed in game code: func_8001783C
  reads arg0->unk_58 (anim pointer) == NULL, called from fragment62 func_84306914
  (battle Pokémon state unk_36 == 1). Last fragment loads before it: two id 0xEF
  blobs "no code" (0x9010 / 0x5850 bytes; data-only?).
  Next: render the battle on-screen once to tell capture artifact from real; check
  what fills unk_58 (func_80017804 / model+anim loading) and whether those 0xEF
  blobs are really data-only; compare with an emulator run if needed.
- 2026-11-16 (round 3): **Battle screen is real, not a capture artifact: battle stuck loading.**
  Decoded both battle frame DLs (rdram.bin at 88 s, tools/dlwalk.py): no VTX/TRI at
  all, only 8 texture rects drawing a 37x37 patch at the top-left (into 0x229580 and
  the 0x3DA280 framebuffer). So RT64 draws what the game asks; the battle never
  starts drawing 3D. Inputs (A/B/Start) from 90-125 s change nothing; game threads
  are healthy (main thread per-frame in func_84301A2C -> func_800078D4 loop).
  Loader trace (us.toml hooks on 19840.c func_80019484/80019514/80019204/80019420,
  trace.cpp stadium_trace_loader): at ~78 s both battle Pokémon models load OK
  (type 1, model fragment non-NULL), one anim set loads (type 2, archive idx 0x2C),
  then the loader goes idle. Only ONE type-2 (animation) request for two Pokémon
  (func_80019A7C) -> the other Pokémon may never get anims (matches the crash seen
  once: func_8001783C with unk_58 == NULL from fragment62 func_84306914).
  Audio verified: 32 kHz stereo, correct sample count, sound during battle
  (peaks hit 32767/32768 -> check for clipping later).
  Also: crashed/killed test runs can leave Stadium1.exe running; shot_port runs
  should be followed by `taskkill /F /IM Stadium1.exe`.
  Next: find who calls func_80019A7C (anim request) for battle Pokémon and why the
  second request doesn't happen (state flag unk_01 & 2? Util_Malloc NULL?); trace
  the battle state machine (fragment62 D_8438E440 / func_8432AEE4).
- 2026-11-16 (round 4): **BATTLES RENDER.** Battle Now: stadium in 3D, "Go! ODDISH!",
  battle menu with Squirtle's panel; ran 140 s with no crash.
  Root cause of the "black battle": fragment variables were never relocated, so the
  recompiled code used them at their link addresses instead of inside the loaded
  fragment. Pointers handed to the RSP (display lists/matrices in fragment bss) pointed
  at nothing, and fragments that share state disagreed. Three parts, all fixed:
  1. us.toml `bss_section_suffix = "_bss"`: pairs .fragmentN with .fragmentN_bss.
  2. N64Recomp elf.cpp patch: relocations into ANOTHER section's bss are remapped too
     (upstream only remapped a section's own bss; fragment62 uses fragment34's).
  3. N64Recomp elf.cpp patch: the decomp defines many fragment variables as ABSOLUTE
     symbols (linker script D_xxxxxxxx = 0x...); an absolute symbol inside a
     relocatable section's code/data/bss range is now relocated with that section
     (current section wins; ambiguous 0x8FF00000 hidden-fragment matches stay absolute).
     Unrelocated "lui 0x8141" went 28 -> 2 (the 2 left are constants in main code).
  Also: librecomp overlays.cpp unload no longer resets a section's address while another
  copy of the same section is still loaded (two Pokémon of one model / stale entries).
  Also: manual func proutSprintf (0x8005E020, sprintf's callback; "Failed to find function").
  Rebuild note: the recompiler exe target is N64RecompCLI (N64Recomp is the library).
  Next: script the battle menu (pick moves) to play a full battle; window size/crop in
  the off-screen test window; audio clipping; then GB Tower / Transfer Pak, launcher, Stadium 2.
- 2026-11-16 (round 5): **Battle turns play.** BATTLE (A) -> moves are on the C-buttons
  (keyboard I/J/K/L); turns run with full move animations, HP changes, faint ->
  next-Pokémon prompt. Battle Now script for a turn: base script + "95:a,97:cd".
  tools/shot_port.ps1 is now DPI-aware (shots were cropped to 1024x768 at 125% scaling;
  now full 1280x960).
  Next: audio clipping check; then GB Tower (fragment1 GB CPU core -> C) and Transfer
  Pak (ultra_stubs.cpp __osContRam*), Essentials launcher, Stadium 2.
- 2026-11-16 (round 6): Audio OK: clipping is the game's own mix (<= 149 of 320k samples
  per 5 s in loud battle moments, same as hardware); output is scaled 0.5, no extra clip.
  **Transfer Pak emulated** (port/src/transfer_pak.cpp, replaces the "no pak" stubs):
  pak power 0x8000 / bank 0xA000 / status 0xB000 / cart window 0xC000, GB cart with
  ROM-only/MBC1/MBC2/MBC3(RTC stubbed)/MBC5 + battery RAM. Player N's pak = <dir>/pN.gb +
  pN.sav, dir = STADIUM_TPAK_DIR or %LOCALAPPDATA%\EchoesOfJohto-Stadium1\tpak. Save is
  written on power-off / leaving access mode / exit. Runtime: ultramodern Pak::TransferPak
  added (osMotorInit -> PFS_ERR_DEVICE for it); input.cpp reports it per port.
  NOT TESTED with a cart yet: needs a Pokémon Red/Blue/Yellow ROM + save (user's own).
  This is also the hook for transfer: Essentials can write pN.sav (Gen 1 save layout)
  before launching and read it back after.
  Next: Essentials launcher plugin (separate event call, like Pinball); test Transfer Pak
  once a GB ROM is available; GB Tower (fragment1 GB CPU core); Stadium 2.

- 2026-11-17: **Quick boot, Transfer Pak verified, Echoes of Johto launcher.**
  * Stadium 2 is on hold (user: Stadium 1 is enough for now).
  * Quick boot (port/src/boot.cpp, default; `--intro` = normal start): N64 logo kept
    (fragment35 does the setup: save, Game Pak scan, options), intro movie skipped
    (us.toml hook func_800290E4 id 0x12), Start pressed on the title by the input layer
    while gCurrentGameState (0x80075668) == 2, "Game Pak Check" skipped on the first
    Menu Select (hook fragment57 func_82D06D0C: a1 = 0). Menu Select in ~6 s (was ~33).
  * Freeze entering a Stadium cup: busy-wait `while (func_80001C90() == 0) {}` (JPEG
    decode etc.) never yielded -> us.toml hook yields in func_80001C90.
  * Transfer Pak works: user's Yellow ROM + save read (trainer AA / ID 33998, party).
    Trace of pak accesses: STADIUM_TRACE ("tpak rd/wr" lines).
  * A Gen 1 save built from scratch (party + 12 boxes + checksums, nothing else) is
    accepted: party shown in Poké Cup entry, eligible boxes lit.
  * Launcher plugin: Echoes of Johto/Plugins/Pokemon Stadium (event call
    pbPokemonStadium): 001_Gen1Data.rb (species index/base stats/types/catch/growth and
    move order/PP, generated from Yellow's tables), 002_Gen1Save.rb (Essentials Pokemon
    <-> Gen 1 records, build/read save), 003_Launcher.rb (writes <save folder>/Stadium/
    tpak/p1.sav, copies a cart image to p1.gb if missing, runs Stadium1.exe with
    STADIUM_TPAK_DIR, waits, imports Pokémon that weren't sent, e.g. prizes).
    NOT yet run inside the game (no Ruby here to test; the save layout was checked with
    a Python mirror, tools-free). Closing Stadium's window exits at once (code 0).
  * Still open: the cart image is a real GB Pokémon ROM (Stadium identifies the game
    from it); GB Tower would run that ROM with the generated save (not a playable save).
  * Keyboard (user's layout): Z=A, X=B, Enter=Start, WASD=D-pad, arrows=C, Q/E=L/R,
    Shift=Z; hold left mouse = analog stick toward the cursor (port/src/input.cpp).
  * GB Tower closed (user): it plays the cart's GB game, and the launcher's generated
    cart isn't a playable save (black screen). boot.cpp stadium_filter_state maps
    state 0x26 -> Area Select (hook in Game_DoCopyProtection).

## Kids Club PVP (requested 2026-11-17) - design
User: a third Kids Club box "PVP" (same graphic as "Who's the best?", text PVP), same rules
as Who's the Best; the server announces "USERNAME just started a PVP Who's the Best in
Stadium, join him quickly" and "USERNAME just joined the PVP". Client-sided: each player
plays locally (1P + COMs); the COM slots show the other humans' real scores (+ names maybe);
up to 4 people per party. User idea: a shared seed so the games line up.

Findings (decomp):
* Kids Club menu = fragment39 (fully decompiled). Main boxes: D_8250A228[0..1] =
  func_8250182C(1, i, geo D_8250A274) at y = 240 - (i*88 + 196); highlighted box =
  D_8250A288.unk_00 (wraps at 2 in func_82503020), chosen mode -> D_8780FA2A (0 pick a
  game, 1 who's the best). Panel pool D_82508B30 has 14 slots, all used (2+2+1+9).
  Box drawing: geo callback func_82500020: segment 0x0F = D_8250890C[idx] (box art incl.
  the text), 0x0E = animated sprite frames (D_82508880 / D_825088A8), DL D_82506FF0/71F0.
* Who's the Best state lives in fragment2 bss (link 0x8780xxxx, relocated at run time):
  D_8780FA30[4] (1 = COM), D_8780FA3A target wins, D_8780FA40[4] wins per player,
  D_8780FA50[9] games played. func_87802F00(slot) = slot won a minigame (at 0x87802F20
  v0 = &D_8780FA40[slot] -> runtime base); func_87802F4C = "someone reached the target?"
  (end check). Roulette pick: fragment39 func_82503F00 (*arg0 = func_878001E8(9)).
  func_878001E8(n) = ((guRandom() + frame counter) / 10) % n.
Plan:
1. Port: pvp.cpp - IPC with the Essentials launcher via files in STADIUM_TPAK_DIR's parent
   (port writes pvp_out.jsonl events: enter, wins N, done; launcher writes pvp_in.json:
   seed, target, others' names + wins). Hooks: win counter (base address + report), end
   check (write others' wins into slots 1..3), roulette (seeded pick sequence).
2. Kids Club UI: third box (pool 14 -> 15, cursor wrap 2 -> 3, y spacing, box art copy with
   "PVP" text rendered into the texture), PVP mode flag -> Who's the Best with 1P + 3 COM.
3. Launcher plugin: poll pvp_out, relay to server (NetworkClient), write pvp_in.
4. Server handler stadium_pvp.js: party (<= 4, join window), seed, announcements,
   scores relay, winner announcement.
- 2026-11-17: **Kids Club PVP built.**
  * port/src/pvp.cpp: file link (STADIUM_PVP_DIR, pvp_out.txt / pvp_in.txt), hooks on the
    win counter (func_87802F00 @0x87802F20), end check (func_87802F4C), roulette
    (func_82503F00) and random (func_878001E8: seeded final pick). Verified: seed 12345 ->
    game 8 (Dig), others' wins (2, 1) and target (3) shown in the COM slots.
    STADIUM_PVP=1 = every Who's the Best is PVP (testing).
  * port/src/kidsclub.cpp: 15th menu panel at 0x80700000 (pool is full), made with
    func_8250182C(1, 2, geo) at set-up (hook func_825024C4 @0x825027E8 + pool alloc hook),
    chained after "Who's the best?" (unk_34), flip animation run in stadium_kc_update,
    art = copy of D_03017700 with the text redrawn as "PVP" (0x80701000), swapped in via
    Memmap_GetSegmentVaddr while the panel draws; cursor wrap patched to 3
    (0x82503078 li t9,2 / 0x825030A8 slti 3). Choosing it -> mode 1 + PVP armed.
    stadium_fragment_addr() (fragments.cpp) = a fragment symbol's run-time address.
  * Server: ServerStuff/handlers/stadium_pvp.js (+ MessageRouter / server.js): party <= 4,
    join window 3 min, target 3, shared seed, announcements (started / joined / won).
  * Launcher: Plugins/Pokemon Stadium/004_PVP.rb relays while Stadium runs.
  * Not yet tested end to end with the live server (needs a server restart).
- 2026-11-17: **PVP in step (user's spec).** Joining = choosing the box (announced in the
  lobby); "Who wants to play?" pills light for joined players (D_8780FA30 = 0 while in the
  lobby, back to COM for the games); only the host can Ready (joiners' A is masked) ->
  'start' closes joining; joiners' screens move on by themselves (A injected on the
  lobby / COM level / wins screens); host's COM level shared ('level'); round 1 = seeded
  game; after each game 'done R W'; the server waits for everyone, names the picker (fewest
  wins), the picker's 'pick R G' moves everyone's cursor (D_8780FA48 / D_8250A292);
  COMs' own wins = 0; instruction screens skipped (9 before_vram hooks on the Start test);
  others' names above their pills on the scoreboard. All verified off-screen with a fake
  pvp_in (joiner, remote picker, host). Server: start/level/done/pick messages.
- 2026-11-17: **PVP fixes (user report: stuck after a COM won).** Cause: zeroing a COM's
  win left its trophy-animation flag (D_8780FDFC, u8[4]; D_8780FC50 = won this round)
  at 1 -> the results screen waited forever; both flags are cleared with the count now.
  Picker = fewest wins incl. COM slots (0 wins, players first on ties); a COM pick is made
  by the server (an unplayed game). Per-round chat announcement "X won <game>!" ('done'
  carries the game index). No picker from the server within 20 s -> pick locally.
  Relay writes pvp_in.txt with retries and logs to <save>/Stadium/pvp/relay_log.txt.
