#!/usr/bin/env python3
"""Generate a deterministic RGB888 test image for the Sobel simulation."""

from __future__ import annotations

import argparse
from pathlib import Path


def pixel(width: int, height: int, x: int, y: int) -> tuple[int, int, int]:
    r = (x * 255) // max(width - 1, 1)
    g = (y * 255) // max(height - 1, 1)
    b = ((x + y) * 255) // max(width + height - 2, 1)

    if width // 4 <= x < (width * 3) // 4 and height // 4 <= y < (height * 3) // 4:
        r, g, b = 240, 240, 240

    if abs(x - y) <= 1 or abs((width - 1 - x) - y) <= 1:
        r, g, b = 20, 20, 20

    if width // 2 - 2 <= x <= width // 2 + 2:
        r, g, b = 255, 40, 40

    return r, g, b


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--width", type=int, default=128)
    parser.add_argument("--height", type=int, default=72)
    parser.add_argument("--output", type=Path, default=Path("data/input_rgb.hex"))
    args = parser.parse_args()

    if args.width <= 1 or args.height <= 1:
        raise SystemExit("width and height must be greater than 1")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="ascii") as f:
        for y in range(args.height):
            for x in range(args.width):
                for channel in pixel(args.width, args.height, x, y):
                    f.write(f"{channel:02x}\n")


if __name__ == "__main__":
    main()
