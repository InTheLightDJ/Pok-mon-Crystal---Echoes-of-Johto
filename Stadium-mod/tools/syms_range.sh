#!/usr/bin/env bash
# Every ELF symbol with an address in [START, END) (hex, no 0x), sorted.
# Usage (in WSL): tools/syms_range.sh path/to/game.elf 8006102c 800612f0
ELF="$1"; START=$((16#$2)); END=$((16#$3))
mips-linux-gnu-readelf -s -W "$ELF" | awk -v s="$START" -v e="$END" '
  $1 ~ /^[0-9]+:$/ { v = strtonum("0x" $2); if (v >= s && v < e) printf "%s %6s %-7s %-6s %-4s %s\n", $2, $3, $4, $5, $7, $8 }' | sort
