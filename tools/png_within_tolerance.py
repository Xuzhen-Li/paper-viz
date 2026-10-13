#!/usr/bin/env python3
"""Is a re-rendered PNG only a rendering-noise change from the committed one?

    python3 tools/png_within_tolerance.py OLD.png NEW.png [--max-fraction F] [--max-channel N]

Exit 0: within tolerance -> keep the committed file (the render bot does not commit NEW).
Exit 1: real change (size differs, too many pixels differ, or a channel differs by more than N).
Exit 2: cannot decode either file -> treat as a real change.

Within tolerance means: same width and height, and after decoding both to 8-bit RGBA the
fraction of pixels with any channel difference is < F (default 0.0001 = 0.01 %) and no channel
differs by more than N (default 2). Byte-only differences (0 differing pixels) are within
tolerance. Pure Python (zlib + struct); no third-party packages, so it runs on the bare runner.
"""
from __future__ import annotations

import argparse
import struct
import sys
import zlib

SIG = b"\x89PNG\r\n\x1a\n"
CHANNELS = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}


class PNGError(Exception):
    pass


def _chunks(data: bytes):
    if data[:8] != SIG:
        raise PNGError("not a PNG")
    pos = 8
    while pos + 8 <= len(data):
        (length,) = struct.unpack(">I", data[pos:pos + 4])
        kind = data[pos + 4:pos + 8]
        body = data[pos + 8:pos + 8 + length]
        if len(body) != length:
            raise PNGError("truncated chunk")
        yield kind, body
        pos += 12 + length
        if kind == b"IEND":
            return
    raise PNGError("missing IEND")


def _unfilter(raw: bytes, width: int, height: int, bpp: int, stride: int) -> list[bytearray]:
    rows: list[bytearray] = []
    prev = bytearray(stride)
    pos = 0
    for _ in range(height):
        ftype = raw[pos]
        cur = bytearray(raw[pos + 1:pos + 1 + stride])
        pos += 1 + stride
        if len(cur) != stride:
            raise PNGError("truncated image data")
        if ftype == 1:
            for i in range(bpp, stride):
                cur[i] = (cur[i] + cur[i - bpp]) & 0xFF
        elif ftype == 2:
            cur = bytearray((a + b) & 0xFF for a, b in zip(cur, prev))
        elif ftype == 3:
            for i in range(stride):
                left = cur[i - bpp] if i >= bpp else 0
                cur[i] = (cur[i] + ((left + prev[i]) >> 1)) & 0xFF
        elif ftype == 4:
            for i in range(stride):
                a = cur[i - bpp] if i >= bpp else 0
                b = prev[i]
                c = prev[i - bpp] if i >= bpp else 0
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pred = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                cur[i] = (cur[i] + pred) & 0xFF
        elif ftype != 0:
            raise PNGError(f"bad filter type {ftype}")
        rows.append(cur)
        prev = cur
    return rows


def decode_rgba(path: str) -> tuple[int, int, list[bytes]]:
    """Return (width, height, rows) with each row as 8-bit RGBA bytes."""
    with open(path, "rb") as fh:
        data = fh.read()
    ihdr = None
    idat = []
    palette = b""
    trns = b""
    for kind, body in _chunks(data):
        if kind == b"IHDR":
            ihdr = struct.unpack(">IIBBBBB", body)
        elif kind == b"IDAT":
            idat.append(body)
        elif kind == b"PLTE":
            palette = body
        elif kind == b"tRNS":
            trns = body
    if ihdr is None:
        raise PNGError("missing IHDR")
    width, height, depth, ctype, _comp, _filt, interlace = ihdr
    if ctype not in CHANNELS:
        raise PNGError(f"unsupported colour type {ctype}")
    if interlace:
        raise PNGError("interlaced PNG not supported")
    if depth not in (8, 16) and not (depth in (1, 2, 4) and ctype in (0, 3)):
        raise PNGError(f"unsupported bit depth {depth}")
    nch = CHANNELS[ctype]
    bits = nch * depth
    stride = (width * bits + 7) // 8
    bpp = max(1, bits // 8)
    try:
        raw = zlib.decompress(b"".join(idat))
    except zlib.error as exc:
        raise PNGError(f"bad image data: {exc}") from exc
    rows = _unfilter(raw, width, height, bpp, stride)

    out: list[bytes] = []
    for row in rows:
        if depth == 16:
            samples = row[0::2]  # high byte -> 8 bit
        elif depth == 8:
            samples = row
        else:
            per = 8 // depth
            mask = (1 << depth) - 1
            samples = bytearray()
            for byte in row:
                for k in range(per):
                    samples.append((byte >> (8 - depth * (k + 1))) & mask)
            samples = samples[:width]
            if ctype == 0:
                scale = 255 // mask
                samples = bytearray(v * scale for v in samples)
        rgba = bytearray(width * 4)
        if ctype == 6:
            rgba[:] = samples[: width * 4]
        elif ctype == 2:
            rgba[0::4] = samples[0::3]
            rgba[1::4] = samples[1::3]
            rgba[2::4] = samples[2::3]
            rgba[3::4] = b"\xff" * width
        elif ctype == 0:
            g = bytes(samples[:width])
            rgba[0::4] = g
            rgba[1::4] = g
            rgba[2::4] = g
            rgba[3::4] = b"\xff" * width
        elif ctype == 4:
            g = bytes(samples[0::2])
            rgba[0::4] = g
            rgba[1::4] = g
            rgba[2::4] = g
            rgba[3::4] = bytes(samples[1::2])
        else:  # palette
            for x, idx in enumerate(samples[:width]):
                if 3 * idx + 2 >= len(palette):
                    raise PNGError("palette index out of range")
                rgba[4 * x:4 * x + 3] = palette[3 * idx:3 * idx + 3]
                rgba[4 * x + 3] = trns[idx] if idx < len(trns) else 255
        out.append(bytes(rgba))
    return width, height, out


def compare(old: str, new: str, max_fraction: float = 0.0001, max_channel: int = 2) -> tuple[bool, str]:
    """(within_tolerance, message)."""
    w0, h0, a = decode_rgba(old)
    w1, h1, b = decode_rgba(new)
    if (w0, h0) != (w1, h1):
        return False, f"size changed {w0}x{h0} -> {w1}x{h1}"
    total = w0 * h0
    diff_px = 0
    worst = 0
    for ra, rb in zip(a, b):
        if ra == rb:
            continue
        for x in range(0, len(ra), 4):
            pa, pb = ra[x:x + 4], rb[x:x + 4]
            if pa != pb:
                diff_px += 1
                worst = max(worst, max(abs(p - q) for p, q in zip(pa, pb)))
    frac = diff_px / total if total else 0.0
    msg = (f"{w0}x{h0}, {diff_px} differing pixel(s) = {frac * 100:.4f}% "
           f"(limit < {max_fraction * 100:.4f}%), max channel diff {worst} (limit <= {max_channel})")
    ok = frac < max_fraction and worst <= max_channel
    return ok, msg


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("old")
    ap.add_argument("new")
    ap.add_argument("--max-fraction", type=float, default=0.0001)
    ap.add_argument("--max-channel", type=int, default=2)
    args = ap.parse_args(argv)
    try:
        ok, msg = compare(args.old, args.new, args.max_fraction, args.max_channel)
    except (OSError, PNGError, struct.error) as exc:
        print(f"cannot compare: {exc}")
        return 2
    print(("within tolerance: " if ok else "real change: ") + msg)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
