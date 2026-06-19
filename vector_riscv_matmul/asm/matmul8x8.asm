# Fully unrolled C[8][8] = A[8][8] x B[8][8].
.equ A_BASE, 0
.equ B_BASE, 0
.equ C_BASE, 16

MOV r15, 8, $0

# C row 0
MOV r2, 0, $0
MOV r1, [B_BASE], $0
VMAC-s vr6, /, vr5, $1
LOAD r3, r2, 0
VLOAD vr5, r1, 0
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 1
VLOAD vr5, r1, 1
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 2
VLOAD vr5, r1, 2
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 3
VLOAD vr5, r1, 3
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 4
VLOAD vr5, r1, 4
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 5
VLOAD vr5, r1, 5
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 6
VLOAD vr5, r1, 6
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 7
VLOAD vr5, r1, 7
VMAC-s vr6, r3, vr5, $0
MOV r1, 16, $0
VSTORE /, r1, vr6

# C row 1
MOV r2, 8, $0
MOV r1, [B_BASE], $0
VMAC-s vr6, /, vr5, $1
LOAD r3, r2, 0
VLOAD vr5, r1, 0
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 1
VLOAD vr5, r1, 1
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 2
VLOAD vr5, r1, 2
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 3
VLOAD vr5, r1, 3
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 4
VLOAD vr5, r1, 4
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 5
VLOAD vr5, r1, 5
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 6
VLOAD vr5, r1, 6
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 7
VLOAD vr5, r1, 7
VMAC-s vr6, r3, vr5, $0
MOV r1, 17, $0
VSTORE /, r1, vr6

# C row 2
MOV r2, 16, $0
MOV r1, [B_BASE], $0
VMAC-s vr6, /, vr5, $1
LOAD r3, r2, 0
VLOAD vr5, r1, 0
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 1
VLOAD vr5, r1, 1
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 2
VLOAD vr5, r1, 2
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 3
VLOAD vr5, r1, 3
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 4
VLOAD vr5, r1, 4
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 5
VLOAD vr5, r1, 5
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 6
VLOAD vr5, r1, 6
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 7
VLOAD vr5, r1, 7
VMAC-s vr6, r3, vr5, $0
MOV r1, 18, $0
VSTORE /, r1, vr6

# C row 3
MOV r2, 24, $0
MOV r1, [B_BASE], $0
VMAC-s vr6, /, vr5, $1
LOAD r3, r2, 0
VLOAD vr5, r1, 0
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 1
VLOAD vr5, r1, 1
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 2
VLOAD vr5, r1, 2
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 3
VLOAD vr5, r1, 3
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 4
VLOAD vr5, r1, 4
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 5
VLOAD vr5, r1, 5
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 6
VLOAD vr5, r1, 6
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 7
VLOAD vr5, r1, 7
VMAC-s vr6, r3, vr5, $0
MOV r1, 19, $0
VSTORE /, r1, vr6

# C row 4
MOV r2, 32, $0
MOV r1, [B_BASE], $0
VMAC-s vr6, /, vr5, $1
LOAD r3, r2, 0
VLOAD vr5, r1, 0
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 1
VLOAD vr5, r1, 1
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 2
VLOAD vr5, r1, 2
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 3
VLOAD vr5, r1, 3
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 4
VLOAD vr5, r1, 4
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 5
VLOAD vr5, r1, 5
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 6
VLOAD vr5, r1, 6
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 7
VLOAD vr5, r1, 7
VMAC-s vr6, r3, vr5, $0
MOV r1, 20, $0
VSTORE /, r1, vr6

# C row 5
MOV r2, 40, $0
MOV r1, [B_BASE], $0
VMAC-s vr6, /, vr5, $1
LOAD r3, r2, 0
VLOAD vr5, r1, 0
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 1
VLOAD vr5, r1, 1
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 2
VLOAD vr5, r1, 2
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 3
VLOAD vr5, r1, 3
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 4
VLOAD vr5, r1, 4
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 5
VLOAD vr5, r1, 5
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 6
VLOAD vr5, r1, 6
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 7
VLOAD vr5, r1, 7
VMAC-s vr6, r3, vr5, $0
MOV r1, 21, $0
VSTORE /, r1, vr6

# C row 6
MOV r2, 48, $0
MOV r1, [B_BASE], $0
VMAC-s vr6, /, vr5, $1
LOAD r3, r2, 0
VLOAD vr5, r1, 0
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 1
VLOAD vr5, r1, 1
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 2
VLOAD vr5, r1, 2
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 3
VLOAD vr5, r1, 3
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 4
VLOAD vr5, r1, 4
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 5
VLOAD vr5, r1, 5
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 6
VLOAD vr5, r1, 6
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 7
VLOAD vr5, r1, 7
VMAC-s vr6, r3, vr5, $0
MOV r1, 22, $0
VSTORE /, r1, vr6

# C row 7
MOV r2, 56, $0
MOV r1, [B_BASE], $0
VMAC-s vr6, /, vr5, $1
LOAD r3, r2, 0
VLOAD vr5, r1, 0
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 1
VLOAD vr5, r1, 1
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 2
VLOAD vr5, r1, 2
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 3
VLOAD vr5, r1, 3
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 4
VLOAD vr5, r1, 4
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 5
VLOAD vr5, r1, 5
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 6
VLOAD vr5, r1, 6
VMAC-s vr6, r3, vr5, $0
LOAD r3, r2, 7
VLOAD vr5, r1, 7
VMAC-s vr6, r3, vr5, $0
MOV r1, 23, $0
VSTORE /, r1, vr6

HALT
