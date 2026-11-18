#!/usr/bin/env bash
# Disassemble raw ROM bytes as MIPS at a given vram.
# Usage (WSL): tools/disasm_rom.sh ROM.z64 ROM_OFFSET_HEX VRAM_HEX SIZE_HEX
ROM="$1"; OFF=$((16#$2)); VRAM="$3"; SIZE=$((16#$4))
TMP=$(mktemp)
dd if="$ROM" bs=1 skip="$OFF" count="$SIZE" status=none > "$TMP"
mips-linux-gnu-objdump -D -b binary -m mips -EB --adjust-vma=0x"$VRAM" "$TMP" | tail -n +8
rm -f "$TMP"
