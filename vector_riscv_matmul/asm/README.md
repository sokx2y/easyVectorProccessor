# Pseudo assembly

The assembler is intentionally small and case-insensitive. Supported
instructions are `LOAD`, `STORE`, `MOV`, `MAC`, `VLOAD`, `VSTORE`,
`VMAC-s`, `NOP`, and `HALT`. `//` and `#` start comments. `/` is an
unused operand placeholder and `$0`/`$1` is the one-bit function field.

`.equ NAME, VALUE` defines an address symbol. `[NAME]` in a `MOV` is an
address constant, not a memory access. `MOV rd, value, $0` writes the low
byte and `$1` writes the high byte while preserving the other byte.

Example:

```text
MOV r15, 8, $0
LOAD r3, r2, 0
VLOAD vr5, r1, 0
VMAC-s vr6, r3, vr5, $0
VSTORE /, r1, vr6
```
