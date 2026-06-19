#!/usr/bin/env python3
"""Assembler for the course-specific scalar/vector pseudo ISA."""

from __future__ import annotations
import argparse
import re
from pathlib import Path

OPCODES = {
    "NOP": 0x0, "LOAD": 0x1, "STORE": 0x2, "MOV": 0x3,
    "MAC": 0x4, "VLOAD": 0x5, "VSTORE": 0x6, "VMAC-S": 0x7,
    "HALT": 0xF,
}


class AsmError(ValueError):
    pass


def number(text: str, symbols: dict[str, int]) -> int:
    token = text.strip()
    m = re.fullmatch(r"\[([A-Za-z_]\w*)\]", token)
    if m:
        name = m.group(1).upper()
        if name not in symbols:
            raise AsmError(f"unknown symbol {name}")
        return symbols[name]
    if token.upper() in symbols:
        return symbols[token.upper()]
    try:
        return int(token, 0)
    except ValueError as exc:
        raise AsmError(f"invalid immediate '{token}'") from exc


def reg(text: str, vector: bool = False, unused: bool = False) -> int:
    token = text.strip().lower()
    if unused and token == "/":
        return 0
    prefix = "vr" if vector else "r"
    m = re.fullmatch(prefix + r"(\d+)", token)
    if not m or not 0 <= int(m.group(1)) < 16:
        kind = "vector" if vector else "scalar"
        raise AsmError(f"invalid {kind} register '{text}'")
    return int(m.group(1))


def funct(text: str) -> int:
    if text.strip() not in ("$0", "$1"):
        raise AsmError(f"funct must be $0 or $1, got '{text}'")
    return int(text.strip()[1])


def encode(op: int, rd: int = 0, rs1: int = 0, rs2: int = 0,
           imm8: int = 0, imm5: int = 0, fn: int = 0) -> int:
    return ((op & 0xF) << 28) | ((rd & 0xF) << 24) | \
           ((rs1 & 0xF) << 20) | ((rs2 & 0xF) << 16) | \
           ((imm8 & 0xFF) << 8) | ((fn & 1) << 7) | (imm5 & 0x1F)


def parse_source(path: Path) -> tuple[list[tuple[int, str]], dict[str, int]]:
    lines: list[tuple[int, str]] = []
    symbols: dict[str, int] = {}
    for lineno, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = re.split(r"//|#", raw, maxsplit=1)[0].strip()
        if not line:
            continue
        if line.lower().startswith(".equ"):
            parts = re.split(r"[\s,]+", line, maxsplit=2)
            if len(parts) != 3:
                raise AsmError(f"{path}:{lineno}: expected .equ NAME, VALUE")
            symbols[parts[1].upper()] = int(parts[2], 0)
        else:
            lines.append((lineno, line))
    return lines, symbols


def assemble_line(line: str, symbols: dict[str, int]) -> int:
    parts = line.strip().split(None, 1)
    mnemonic = parts[0].upper()
    if mnemonic not in OPCODES:
        raise AsmError(f"unknown instruction '{parts[0]}'")
    args = [] if len(parts) == 1 else [x.strip() for x in parts[1].split(",")]
    op = OPCODES[mnemonic]

    if mnemonic in ("NOP", "HALT"):
        if args:
            raise AsmError(f"{mnemonic} takes no operands")
        return encode(op)
    if mnemonic == "LOAD":
        if len(args) != 3:
            raise AsmError("LOAD expects rd, rs, imm5")
        imm = number(args[2], symbols)
        if not -16 <= imm <= 15:
            raise AsmError("LOAD imm5 must be in [-16, 15]")
        return encode(op, reg(args[0]), reg(args[1]), imm5=imm)
    if mnemonic == "STORE":
        if len(args) != 3:
            raise AsmError("STORE expects /, rs1, rs2")
        return encode(op, reg(args[0], unused=True), reg(args[1]), reg(args[2]))
    if mnemonic == "MOV":
        if len(args) != 3:
            raise AsmError("MOV expects rd, imm8, $funct")
        rd = reg(args[0])
        value = number(args[1], symbols)
        fn = funct(args[2])
        byte = (value >> 8) & 0xFF if fn else value & 0xFF
        return encode(op, rd, rd, imm8=byte, fn=fn)
    if mnemonic == "MAC":
        if len(args) != 4:
            raise AsmError("MAC expects rd, rs1, rs2, $funct")
        return encode(op, reg(args[0]), reg(args[1], unused=True),
                      reg(args[2], unused=True), fn=funct(args[3]))
    if mnemonic == "VLOAD":
        if len(args) != 3:
            raise AsmError("VLOAD expects vrd, rs, imm5")
        imm = number(args[2], symbols)
        if not -16 <= imm <= 15:
            raise AsmError("VLOAD imm5 must be in [-16, 15]")
        return encode(op, reg(args[0], vector=True), reg(args[1]), imm5=imm)
    if mnemonic == "VSTORE":
        if len(args) != 3:
            raise AsmError("VSTORE expects /, rs, vrs")
        return encode(op, reg(args[0], unused=True), reg(args[1]),
                      reg(args[2], vector=True))
    if mnemonic == "VMAC-S":
        if len(args) != 4:
            raise AsmError("VMAC-s expects vrd, rs, vrs, $funct")
        return encode(op, reg(args[0], vector=True),
                      reg(args[1], unused=True),
                      reg(args[2], vector=True, unused=True),
                      fn=funct(args[3]))
    raise AssertionError(mnemonic)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", nargs="?", default="asm/matmul8x8.asm")
    parser.add_argument("-o", "--output", default="sim/program.mem")
    parser.add_argument("--listing", default="sim/program.lst")
    args = parser.parse_args()
    source, output, listing = map(Path, (args.input, args.output, args.listing))
    lines, symbols = parse_source(source)
    words: list[int] = []
    listing_lines: list[str] = []
    for lineno, line in lines:
        try:
            word = assemble_line(line, symbols)
        except AsmError as exc:
            raise SystemExit(f"{source}:{lineno}: {exc}") from exc
        listing_lines.append(f"{len(words):04x}: {word:08x}  {line}")
        words.append(word)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(f"{w:08x}" for w in words) + "\n", encoding="ascii")
    listing.write_text("\n".join(listing_lines) + "\n", encoding="utf-8")
    print(f"Assembled {len(words)} instructions -> {output}")


if __name__ == "__main__":
    main()
