#!/usr/bin/env python3
"""Generate platform icons from one original Veldigo vector-style design.

Only Python standard library is used; image pixels are rendered locally.
"""
from __future__ import annotations

from math import hypot, exp
from pathlib import Path
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
SHIELD = [
    (.50, .065), (.83, .19), (.79, .58),
    (.68, .79), (.50, .93), (.32, .79),
    (.21, .58), (.17, .19), (.50, .065),
]
LETTER = [(.34, .34), (.50, .68), (.68, .34)]


def distance_to_polyline(x: float, y: float, points: list[tuple]) -> float:
    best = 10.0
    for (ax, ay), (bx, by) in zip(points, points[1:]):
        dx, dy = bx - ax, by - ay
        t = max(0.0, min(1.0, ((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy)))
        best = min(best, hypot(x - ax - t * dx, y - ay - t * dy))
    return best


def raster(size: int) -> bytes:
    raw = bytearray()
    for yi in range(size):
        raw.append(0)  # PNG scanline filter = None
        for xi in range(size):
            x, y = (xi + .5) / size, (yi + .5) / size
            dist = distance_to_polyline(x, y, SHIELD)
            vdist = distance_to_polyline(x, y, LETTER)
            d = min(dist, vdist)
            glow = exp(-d * 16) * .12
            background = (
                int(5 + glow * 20),
                int(17 + (1 - y) * 10 + glow * 175),
                int(31 + glow * 160),
            )
            stroke = max(0.0, min(1.0,
                (.024 - dist) * size / 1.25 + .5))
            stroke = max(stroke, max(0.0, min(1.0,
                (.040 - vdist) * size / 1.25 + .5)))
            accent = (39, 228, 210)
            rgb = [int(a * (1 - stroke) + b * stroke)
                   for a, b in zip(background, accent)]
            raw.extend((*rgb, 255))
    return png(size, size, bytes(raw))


def chunk(label: bytes, data: bytes) -> bytes:
    body = label + data
    return struct.pack('>I', len(data)) + body + struct.pack(
        '>I', zlib.crc32(body) & 0xffffffff)


def png(width: int, height: int, scanlines: bytes) -> bytes:
    return (
        b'\x89PNG\r\n\x1a\n' +
        chunk(b'IHDR', struct.pack('>2I5B', width, height, 8, 6, 0, 0, 0)) +
        chunk(b'IDAT', zlib.compress(scanlines, level=9)) +
        chunk(b'IEND', b'')
    )


def write_icons() -> None:
    android = ROOT / 'android/app/src/main/res'
    for density, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96),
                          ('xxhdpi', 144), ('xxxhdpi', 192)]:
        folder = android / f'mipmap-{density}'
        folder.mkdir(parents=True, exist_ok=True)
        (folder / 'ic_launcher.png').write_bytes(raster(size))

    images = [(n, raster(n)) for n in (16, 32, 48, 64, 128, 256)]
    entries = bytearray()
    payload = bytearray()
    offset = 6 + 16 * len(images)
    for n, data in images:
        entries.extend(struct.pack('<BBBBHHII',
            0 if n == 256 else n,
            0 if n == 256 else n,
            0, 0, 1, 32, len(data), offset))
        payload.extend(data)
        offset += len(data)
    ico = struct.pack('<HHH', 0, 1, len(images)) + entries + payload
    target = ROOT / 'windows/runner/resources/app_icon.ico'
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(ico)
    print('Veldigo launcher icon generated for Android and Windows.')


if __name__ == '__main__':
    write_icons()
