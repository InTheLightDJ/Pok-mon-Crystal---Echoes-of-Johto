#!/usr/bin/env bash
# Disassemble [START, END) of a decomp ELF (hex, no 0x), for finding function
# boundaries (jr $ra + delay slot). Usage (in WSL):
#   tools/disasm_range.sh path/to/game.elf 80061054 800612f0 [grep pattern]
ELF="$1"; START="0x$2"; END="0x$3"
out=$(mips-linux-gnu-objdump -d -z --no-show-raw-insn -M reg-names=n32 \
        --start-address="$START" --stop-address="$END" "$ELF" | grep -E '^\s*[0-9a-f]+:')
if [ -n "$4" ]; then echo "$out" | grep -E -A1 "$4"; else echo "$out"; fi
