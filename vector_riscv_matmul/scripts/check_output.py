#!/usr/bin/env python3
"""Check the simulator's machine-readable RESULT lines."""

import argparse
import re
from pathlib import Path


def unpack(line: str) -> list[int]:
    value = int(line.strip(), 16)
    return [(value >> (32 * lane)) & 0xffffffff for lane in range(8)]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("log", nargs="?", default="sim/output.log")
    parser.add_argument("--expected", default="sim/expected_output.mem")
    args = parser.parse_args()
    expected = [unpack(x) for x in Path(args.expected).read_text().splitlines()[:8]]
    raw = Path(args.log).read_bytes()
    if raw.startswith((b"\xff\xfe", b"\xfe\xff")) or b"\x00" in raw[:200]:
        text = raw.decode("utf-16", errors="replace")
    else:
        text = raw.decode("utf-8", errors="replace")
    actual = [[None] * 8 for _ in range(8)]
    for row, col, value in re.findall(r"RESULT\s+(\d+)\s+(\d+)\s+(-?\d+)", text):
        actual[int(row)][int(col)] = int(value) & 0xffffffff
    failures = []
    for r in range(8):
        for c in range(8):
            if actual[r][c] != expected[r][c]:
                failures.append((r, c, expected[r][c], actual[r][c]))
    if failures:
        for item in failures:
            print("Mismatch row=%d col=%d expected=%s actual=%s" % item)
        raise SystemExit("FAIL")
    print("PASS: output.log matches expected_output.mem")


if __name__ == "__main__":
    main()
