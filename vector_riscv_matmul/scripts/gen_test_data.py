#!/usr/bin/env python3
"""Generate deterministic 8x8 matrices and memory images."""

from pathlib import Path

N = 8
VEC_LANES = 16
ACC_WIDTH = 32

A = [[((r * 3 + c * 2) % 7) + 1 for c in range(N)] for r in range(N)]
B = [[((r * 5 + c * 3) % 9) + 1 for c in range(N)] for r in range(N)]
C = [[sum(A[r][k] * B[k][c] for k in range(N))
      for c in range(N)] for r in range(N)]


def pack_vector(values: list[int]) -> str:
    lanes = values + [0] * (VEC_LANES - len(values))
    return "".join(f"{value & 0xffffffff:08x}" for value in reversed(lanes))


def show(name: str, matrix: list[list[int]]) -> None:
    print(name)
    for row in matrix:
        print(" ".join(f"{x:5d}" for x in row))


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    sim = root / "sim"
    sim.mkdir(exist_ok=True)

    scalar_words = [value for row in A for value in row]
    (sim / "scalar_init.mem").write_text(
        "\n".join(f"{x & 0xffff:04x}" for x in scalar_words) + "\n",
        encoding="ascii")

    vector_entries = [pack_vector(row) for row in B]
    vector_entries += [pack_vector([])] * 8
    vector_entries += [pack_vector([])] * 8
    (sim / "vector_init.mem").write_text(
        "\n".join(vector_entries) + "\n", encoding="ascii")
    (sim / "expected_output.mem").write_text(
        "\n".join(pack_vector(row) for row in C) + "\n", encoding="ascii")

    show("A =", A)
    show("B =", B)
    show("Golden C =", C)


if __name__ == "__main__":
    main()
