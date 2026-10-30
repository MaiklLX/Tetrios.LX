#!/usr/bin/env bash
set -euo pipefail

ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
SITE="$ROOT/site"
MODEL_DIR="$SITE/characters/models"
LOCK="$SITE/characters/models.sha256"
mkdir -p "$MODEL_DIR"

# Exact model URLs are listed in Gobkit's public CC0 manifest:
# https://gobkit.com/api/free
declare -A MODELS=(
  [minion-a01]="https://gobkit.com/freebies/minion/minion-a01.glb"
  [minion-b01]="https://gobkit.com/freebies/minion/minion-b01.glb"
  [minion-c01]="https://gobkit.com/freebies/minion/minion-c01.glb"
  [minion-d01]="https://gobkit.com/freebies/minion/minion-d01.glb"
  [minion-a02]="https://gobkit.com/freebies/minion/minion-a02.glb"
)

for id in minion-a01 minion-b01 minion-c01 minion-d01 minion-a02; do
  url="${MODELS[$id]}"
  tmp="$MODEL_DIR/$id.glb.download"
  curl --fail --location --retry 3 --retry-delay 2 "$url" --output "$tmp"
  test -s "$tmp"
  size="$(stat -c%s "$tmp")"
  if [ "$size" -lt 1000 ] || [ "$size" -gt 30000000 ]; then
    echo "::error::Unexpected GLB size for $id: $size bytes"
    exit 1
  fi
  if [ "$(head -c 4 "$tmp")" != "glTF" ]; then
    echo "::error::Downloaded file is not a GLB: $id"
    exit 1
  fi

  if [ -s "$LOCK" ]; then
    expected="$(awk -v file="$id.glb" '$2 == file {print $1}' "$LOCK")"
    if [ -z "$expected" ]; then
      echo "::error::No pinned SHA-256 exists for $id.glb"
      exit 1
    fi
    actual="$(sha256sum "$tmp" | awk '{print $1}')"
    if [ "$actual" != "$expected" ]; then
      echo "::error::SHA-256 mismatch for $id.glb"
      exit 1
    fi
  fi
  mv "$tmp" "$MODEL_DIR/$id.glb"
done

if [ ! -s "$LOCK" ]; then
  (cd "$MODEL_DIR" && sha256sum minion-a01.glb minion-b01.glb minion-c01.glb minion-d01.glb minion-a02.glb) > "$LOCK"
fi

python3 - "$SITE/characters/manifest.json" <<'PY'
import json, sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text())
mapping = {
    "plush": "minion-a01",
    "prism": "minion-b01",
    "blip": "minion-c01",
    "pixel": "minion-d01",
    "spark": "minion-a02",
}
license_text = "CC0 1.0 — Gobkit Minion Pack; public domain, commercial and personal use permitted, attribution not required."
for hero, model in mapping.items():
    entry = data["characters"][hero]
    entry["model"] = f"./characters/models/{model}.glb"
    entry["license"] = license_text
    entry["source"] = f"https://gobkit.com/freebies/minion/{model}.glb"
    entry["animations"] = {
        "idle": "idle",
        "attack": "attack",
        "victory": "attack",
        "death": "dead",
    }
path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
PY

python3 "$ROOT/scripts/validate-glb-characters.py" "$MODEL_DIR"

cat > "$SITE/characters/MODEL_CREDITS.md" <<'EOF'
# 3D character model credits

Five rigged low-poly GLB character variants are bundled from the Gobkit Minion Pack.

- Publisher/source: Gobkit — https://gobkit.com/freebies
- Public manifest: https://gobkit.com/api/free
- License: CC0 1.0 (public domain); the source manifest states that commercial and personal use are permitted and attribution is not required.
- Models: minion-a01, minion-b01, minion-c01, minion-d01, minion-a02.
- Each model is rigged and includes named idle, attack and dead animation clips at 24 FPS.
- SHA-256 checksums are pinned in models.sha256.

The models are used as a first real-GLB character pass. Existing Tetrios.LX hero identities and game balance remain unchanged; later art passes can replace or customize individual meshes.
EOF

echo "Downloaded and verified five CC0 rigged GLB models."
