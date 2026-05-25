#!/usr/bin/env python3
"""build_amxd.py — Assemble a .maxpat JSON into a .amxd file.

.amxd format: 32-byte header + .maxpat JSON bytes (no compression).

Header layout:
  4 bytes  "ampf"          magic
  4 bytes  LE uint32(4)    section size
  8 bytes  "aaaameta"      section tag
  4 bytes  LE uint32(4)    meta section size
  4 bytes  LE uint32(1)    meta value
  4 bytes  "ptch"          patch section tag
  4 bytes  LE uint32(N)    JSON byte length
  N bytes  <JSON>          .maxpat content verbatim

Usage:
  python3 scripts/build_amxd.py m4l/MyDevice.maxpat m4l/MyDevice.amxd
"""

import json
import os
import struct
import sys


def _check_empty_parameterbanks(patcher_json: bytes) -> None:
    doc = json.loads(patcher_json)
    pb = doc.get("patcher", {}).get("parameters", {}).get("parameterbanks") or {}
    if pb and all(not bank.get("parameters") for bank in pb.values()):
        sys.stderr.write(
            "WARNING: empty parameterbanks block detected — remove the top-level "
            '"parameters" key from the .maxpat to avoid Live/Max param_banks crash.\n'
        )


def build_amxd(maxpat_path: str, amxd_path: str) -> None:
    with open(maxpat_path, "rb") as f:
        json_bytes = f.read()
    _check_empty_parameterbanks(json_bytes)

    header = (
        b"ampf" + struct.pack("<I", 4) +
        b"aaaameta" + struct.pack("<I", 4) +
        struct.pack("<I", 1) +
        b"ptch" + struct.pack("<I", len(json_bytes))
    )

    with open(amxd_path, "wb") as f:
        f.write(header + json_bytes)

    print(f"Built {amxd_path} ({len(header) + len(json_bytes)} bytes, JSON={len(json_bytes)} bytes)")


if __name__ == "__main__":
    if len(sys.argv) == 3:
        maxpat = sys.argv[1]
        amxd = sys.argv[2]
    else:
        print("Usage: build_amxd.py source.maxpat dest.amxd")
        sys.exit(1)

    if not os.path.exists(maxpat):
        print(f"Error: {maxpat} not found")
        sys.exit(1)

    build_amxd(maxpat, amxd)
