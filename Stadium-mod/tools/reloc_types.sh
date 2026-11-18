#!/usr/bin/env bash
# Count relocation types per kind of section in a decomp ELF (which ones
# N64Recomp has to understand). Usage (in WSL): tools/reloc_types.sh game.elf
mips-linux-gnu-readelf -r -W "$1" | awk '
  /^Relocation section/ { sec = $3; gsub(/'"'"'/, "", sec); kind = (sec ~ /fragment/ ? "fragments" : sec) ; next }
  $3 ~ /^R_MIPS/ { n[kind " " $3]++ }
  END { for (k in n) printf "%8d  %s\n", n[k], k }' | sort -k2
