# AXI deployment interface

The deployment-style target is the four-stage pipeline. Program and matrices
are loaded at runtime; `$readmemh` is disabled in the deployed instance.
The current course deliverable validates this interface in xsim and Vivado
implementation; it does not require a physical PYNQ-Z2 board.

## Address map

The IP exposes a 64 KiB byte-addressed AXI4-Lite space:

| Offset | Access | Description |
|---:|:---:|---|
| `0x0000` | R/W | CONTROL |
| `0x0004` | R | STATUS |
| `0x0008` | R | CYCLE_COUNT |
| `0x000c` | R | CURRENT_PC |
| `0x0010` | R | VERSION (`0x00010000`) |
| `0x1000-0x17ff` | R/W | ICM, 512 x 32-bit |
| `0x2000-0x23ff` | R/W | Scalar DCM, low 16 bits valid |
| `0x4000-0x7fff` | R/W | Vector DCM, 4096 x 32-bit lane words |

All accesses must be 32-bit aligned.

CONTROL is write-one-pulse:

- bit 0: START
- bit 1: SOFT_RESET

STATUS:

- bit 0: DONE
- bit 1: BUSY
- bit 2: HALTED
- bit 3: ACCESS_ERROR, sticky until SOFT_RESET
- bit 4: IDLE

## Vector address calculation

Each vector entry contains 16 32-bit lanes and occupies 64 bytes:

```text
address = 0x4000 + (entry * 16 + lane) * 4
entry   = (address - 0x4000) >> 6
lane    = address[5:2]
```

B uses entries 0 through 7. C is read from entries 16 through 23.

## Runtime sequence

1. Assert SOFT_RESET or confirm STATUS.IDLE.
2. Write `program.mem` to ICM.
3. Write row-major A to Scalar DCM.
4. Write B rows to Vector DCM lanes 0 through 7; clear inactive lanes.
5. Optionally read back representative words.
6. Write START.
7. Poll STATUS.DONE.
8. Read C from Vector DCM.
9. Read CYCLE_COUNT and compare C against a software golden result.

Memory-window accesses and duplicate START are rejected with AXI SLVERR while
BUSY. Invalid, unaligned, and write-to-read-only transactions also return
SLVERR and set ACCESS_ERROR.
