#!/usr/bin/env python3
"""Convert simulation image files to PNG files that open directly."""

from __future__ import annotations

import argparse
import struct
import zlib
from pathlib import Path


def read_rgb_hex(path: Path, width: int, height: int) -> bytes:
    values: list[int] = []
    for line_no, line in enumerate(path.read_text(encoding="ascii").splitlines(), start=1):
        item = line.strip()
        if not item:
            continue
        try:
            value = int(item, 16)
        except ValueError as exc:
            raise SystemExit(f"{path}:{line_no}: invalid hex byte {item!r}") from exc
        if not 0 <= value <= 255:
            raise SystemExit(f"{path}:{line_no}: value out of byte range: {item!r}")
        values.append(value)

    expected = width * height * 3
    if len(values) != expected:
        raise SystemExit(f"{path}: expected {expected} RGB bytes, got {len(values)}")

    return bytes(values)


def read_pgm_p2(path: Path) -> tuple[int, int, bytes]:
    tokens: list[str] = []
    for line in path.read_text(encoding="ascii").splitlines():
        line = line.split("#", 1)[0]
        tokens.extend(line.split())

    if len(tokens) < 4 or tokens[0] != "P2":
        raise SystemExit(f"{path}: expected ASCII PGM P2 format")

    width = int(tokens[1])
    height = int(tokens[2])
    max_value = int(tokens[3])
    if width <= 0 or height <= 0:
        raise SystemExit(f"{path}: invalid PGM size {width}x{height}")
    if max_value <= 0:
        raise SystemExit(f"{path}: invalid PGM max value {max_value}")

    raw_pixels = [int(item) for item in tokens[4:]]
    expected = width * height
    if len(raw_pixels) != expected:
        raise SystemExit(f"{path}: expected {expected} pixels, got {len(raw_pixels)}")

    pixels = bytes(max(0, min(255, (value * 255) // max_value)) for value in raw_pixels)
    return width, height, pixels


def png_chunk(chunk_type: bytes, data: bytes) -> bytes:
    crc = zlib.crc32(chunk_type)
    crc = zlib.crc32(data, crc) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + chunk_type + data + struct.pack(">I", crc)


def write_png(path: Path, width: int, height: int, pixels: bytes, color_type: int) -> None:
    if color_type == 2:
        bytes_per_pixel = 3
    elif color_type == 0:
        bytes_per_pixel = 1
    else:
        raise ValueError(f"unsupported PNG color type: {color_type}")

    expected = width * height * bytes_per_pixel
    if len(pixels) != expected:
        raise SystemExit(f"{path}: expected {expected} bytes for PNG, got {len(pixels)}")

    rows = []
    stride = width * bytes_per_pixel
    for y in range(height):
        start = y * stride
        rows.append(b"\x00" + pixels[start : start + stride])

    ihdr = struct.pack(">IIBBBBB", width, height, 8, color_type, 0, 0, 0)
    compressed = zlib.compress(b"".join(rows), level=9)

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + png_chunk(b"IHDR", ihdr)
        + png_chunk(b"IDAT", compressed)
        + png_chunk(b"IEND", b"")
    )


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Convert simulation input and Sobel PGM output to directly viewable PNG images."
    )
    parser.add_argument("--width", type=int, default=128, help="RGB hex image width")
    parser.add_argument("--height", type=int, default=72, help="RGB hex image height")
    parser.add_argument("--input-rgb", type=Path, default=Path("data/input_rgb.hex"))
    parser.add_argument("--sobel-pgm", type=Path, default=Path("build/sobel_out.pgm"))
    parser.add_argument("--input-png", type=Path, default=Path("build/input_rgb.png"))
    parser.add_argument("--sobel-png", type=Path, default=Path("build/sobel_out.png"))
    args = parser.parse_args()

    if args.width <= 0 or args.height <= 0:
        raise SystemExit("width and height must be positive")

    rgb_pixels = read_rgb_hex(args.input_rgb, args.width, args.height)
    write_png(args.input_png, args.width, args.height, rgb_pixels, color_type=2)

    sobel_width, sobel_height, sobel_pixels = read_pgm_p2(args.sobel_pgm)
    write_png(args.sobel_png, sobel_width, sobel_height, sobel_pixels, color_type=0)

    print(f"Wrote {args.input_png}")
    print(f"Wrote {args.sobel_png}")


if __name__ == "__main__":
    main()
