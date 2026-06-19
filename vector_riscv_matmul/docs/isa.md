# Simplified ISA

## Machine encoding

All instructions are 32 bits:

```text
31:28 opcode | 27:24 rd/vrd | 23:20 rs1 | 19:16 rs2/vrs
15:8 imm8    | 7 funct1     | 6:5 reserved | 4:0 imm5
```

Opcodes: NOP=0, LOAD=1, STORE=2, MOV=3, MAC=4, VLOAD=5,
VSTORE=6, VMAC-s=7, HALT=F.

`imm5` is sign-extended. `imm8` is used as an unsigned byte by MOV.
Reserved and unused fields are zero.

## Assembly syntax and semantics

- `LOAD rd, rs, imm5`: `rd = ScalarDCM[rs + sext(imm5)]`
- `STORE /, rs1, rs2`: `ScalarDCM[rs1] = rs2`
- `MOV rd, imm8, $0`: replace rd low byte.
- `MOV rd, imm8, $1`: replace rd high byte.
- `MAC rd, rs1, rs2, $0`: `rd = rd + rs1 * rs2`
- `MAC rd, /, /, $1`: clear rd.
- `VLOAD vrd, rs, imm5`: load one packed vector.
- `VSTORE /, rs, vrs`: store one packed vector.
- `VMAC-s vrd, rs, vrs, $0`: active lanes perform
  `vrd[lane] += rs * vrs[lane]`.
- `VMAC-s vrd, /, vrs, $1`: clear active lanes.
- `HALT`: stop PC and architectural writes.

Assembly is case-insensitive. `//` and `#` introduce comments. `.equ` defines
symbols, and `[NAME]` denotes a symbol value used by MOV.
