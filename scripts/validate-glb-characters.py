#!/usr/bin/env python3
"""Validate bundled GLB v2 files and the animation clips expected by Tetrios.LX."""

import json
import struct
import sys
from pathlib import Path

required = ("idle", "attack", "dead")
root = Path(sys.argv[1] if len(sys.argv) > 1 else "site/characters/models")
files = sorted(root.glob("*.glb"))
if len(files) != 5:
    raise SystemExit(f"Expected 5 GLB character models, found {len(files)}")

for path in files:
    data = path.read_bytes()
    if len(data) < 20:
        raise SystemExit(f"{path.name}: file is too small to be a GLB")
    magic, version, total_length = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF" or version != 2 or total_length != len(data):
        raise SystemExit(f"{path.name}: invalid GLB v2 header")
    chunk_length, chunk_type = struct.unpack_from("<II", data, 12)
    if chunk_type != 0x4E4F534A or 20 + chunk_length > len(data):
        raise SystemExit(f"{path.name}: missing first JSON chunk")
    document = json.loads(data[20:20 + chunk_length].decode("utf-8").rstrip(" \t\r\n\0"))
    if document.get("asset", {}).get("version") != "2.0":
        raise SystemExit(f"{path.name}: glTF asset version is not 2.0")
    animations = {item.get("name") for item in document.get("animations", [])}
    missing = [name for name in required if name not in animations]
    if missing:
        raise SystemExit(f"{path.name}: missing animation clips {missing}; found {sorted(animations)}")
    if not document.get("skins"):
        raise SystemExit(f"{path.name}: expected a rigged/skinned character")
    if not document.get("meshes"):
        raise SystemExit(f"{path.name}: no mesh geometry found")
    if any("uri" in buffer for buffer in document.get("buffers", [])):
        raise SystemExit(f"{path.name}: external buffer dependency is not allowed")
    print(f"PASS {path.name}: {len(document.get('meshes', []))} meshes, {len(animations)} clips, rigged, self-contained")

print("PASS: all five GLB character models are valid, self-contained and animated.")
