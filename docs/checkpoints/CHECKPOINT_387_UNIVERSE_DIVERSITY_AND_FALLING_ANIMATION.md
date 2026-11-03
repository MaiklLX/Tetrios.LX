# TETRIOS LX — CHECKPOINT #387
## Universe diversity, 3D falling animation and future hero teaser

**Date:** 2026-11-03  
**Branch:** `mobile/golden-arena-adaptation-2026-11-03`  
**PR:** #48 — remains open; do not merge without explicit approval  
**Checkpoint commit before this document:** `c83374937fa047346a844fe6feba07a7ec36a7c4`  
**Main baseline:** `7c0f8d6dd7c2e6653db983359c780175600b6496` — unchanged

### Implemented

1. **Campaign universe atlas**
   - Expanded the manifest and offline Android bundle from 24 to **40 CC0 GLB models**.
   - Added 16 models: Jupiter, Venus, Pluto, Ringed Planet, Hover Bike, Holo Map Table, Data Pad, Cargo Lift, Energy Crystal, Force Field Emitter, Hologram Projector, Hydroponics Rack, Medical Pod, Repair Bot, Sci-Fi Airlock and Solar Panel Array.
   - Each of the 12 universe cards now has a distinct showcase planet and a distinct companion object; the 12 planet IDs and 12 companion-object IDs are validated as unique and non-overlapping.
   - The 360 campaign planet nodes use deterministic per-node procedural 3D variants. Each variant gets a different palette and combination of surface patches, craters, atmosphere, optional rings and moons. The campaign nodes deliberately remain procedural rather than upgrading to one repeated GLB.
   - Source pages and CC0 license metadata are recorded in `site/universes/manifest.json` and `site/universes/MODEL_CREDITS.md`.

2. **3D piece descent**
   - Slowed the easing for normal vertical falling movement so each descent is more visible.
   - Hard Drop now animates the locked tetromino from its current falling position to its actual ghost/landing position instead of making the blocks appear instantly at the bottom.
   - Landing flash and shockwave cues are aligned to the real landing row. Line-clear animation logic remains separate.

3. **Future hero teaser**
   - Added a locked, non-selectable future hero card to the hero roster.
   - It signals “Будущее обновление / Скоро в команде” without adding a fake hero to gameplay data or changing hero selection.

### Verification

- Android WebView source audit **#215** — SUCCESS.
- Mobile Arena Visual Preview **#70** — SUCCESS.
- APK build **#793**, workflow run `41650853274` — SUCCESS.
- APK artifact ID: `13237815999`.
- Verified inside APK: **40 GLB files**, 40 manifest models, 40 unique manifest order entries, and bundled `universes-3d.js`.
- APK size: 47,009,093 bytes.
- APK SHA-256: `afd1177cf06fba8b74ad0500e357f5dadd8e3ff5f5d4ad8874d6aef8ca9f4311`.
- Signing certificate SHA-256 matches the previously tested APK #764/#776 certificate: `5B:50:DC:C9:E8:FB:F0:D7:45:EC:AD:FD:81:2E:0B:12:9C:38:E5:FD:0F:59:00:26:E2:43:A7:E8:D9:C6:9C:9E`.
- Physical Android gameplay testing is still required, especially the actual descent/Hard Drop feel and 3D model performance across the 360 planet nodes.

### Protected conditions

- Golden Desktop Baseline #372 remains untouched.
- `main` remains unchanged.
- PR #48 remains open and unmerged.
- No production deployment was performed; deployment steps were skipped for the PR build.

### Continuation phrase

`TETRIOS LX — продолжаем с #387: 40 CC0 моделей, 12 уникальных вселенных с разными объектами, 360 неповторяющихся процедурных планет, анимированное падение фигур, закрытый герой на будущее. Проверяем APK #793 на Android.`
