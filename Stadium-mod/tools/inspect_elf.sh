#!/usr/bin/env bash
# Summary of a decomp ELF for N64Recomp: code sections, relocation sections,
# function symbols. Usage (in WSL): tools/inspect_elf.sh path/to/game.elf
set -e
ELF="$1"
RE=mips-linux-gnu-readelf
echo "ELF: $ELF ($(stat -c %s "$ELF") bytes)"
echo "sections:          $($RE -S -W "$ELF" | grep -cE '^\s+\[ *[0-9]+\]')"
echo "code sections (AX): $($RE -S -W "$ELF" | grep -E '^\s+\[' | awk '$0 ~ / PROGBITS / && $0 ~ /AX/' | wc -l)"
echo "reloc sections:    $($RE -S -W "$ELF" | grep -cE ' \.rel\.')"
echo "FUNC symbols:      $($RE -s -W "$ELF" | awk '$4 == "FUNC"' | wc -l)"
echo "unnamed func_ symbols (not decompiled yet): $($RE -s -W "$ELF" | awk '$4 == "FUNC" && $8 ~ /^func_/' | wc -l)"
echo "code sections:"
$RE -S -W "$ELF" | grep -E '^\s+\[' | awk '$0 ~ / PROGBITS / && $0 ~ /AX/ {for(i=1;i<=NF;i++) if ($i ~ /^\./) {n=$i; a=$(i+2); s=$(i+4); break}; printf "  %-22s vram %s size %s\n", n, a, s}'
