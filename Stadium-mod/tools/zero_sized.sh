#!/usr/bin/env bash
# Zero-sized FUNC symbols in an ELF (hand-written asm without .size), grouped by 64 KB region.
# Usage (WSL): tools/zero_sized.sh game.elf
mips-linux-gnu-readelf -s -W "$1" | awk '$4=="FUNC" && $3==0 {print $2, $8}' | sort > /tmp/zero_sized.txt
echo "total: $(wc -l < /tmp/zero_sized.txt)"
cut -c1-4 /tmp/zero_sized.txt | uniq -c | sort -rn | head -20
