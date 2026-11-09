# KT-545 — Authored campaign layouts and mission runner foundation

## Status
Implementation in progress on `godot/kt493-gallery-validated-2026-11-08`. PR #81 remains Draft/open/unmerged. No main merge, public deployment or APK release.

## Scope of this slice
- Add a deterministic, validated authored starting-layout contract to the isolated campaign piece runtime.
- Allow planet definitions to supply optional bottom-up board rows before the first piece spawns.
- Keep ordinary planets on the existing empty-board fallback when no authored layout is present.
- Preserve the existing standard piece bag and the campaign-only Cargo Hook schedule.
- Keep the shared Classic model, Sprint/Marathon and Block Run unchanged.

## First Star Caravan authored layouts
- Planet 033 — Cargo Corridor (`cargo_corridor`): three bottom rows, 26 occupied cells.
- Planet 036 — Offset Bay (`offset_bay`): three bottom rows with staggered gaps.
- Planet 046 — Staggered Joint (`staggered_joint`): three bottom rows with offset passages.

Rows are authored top-to-bottom within the bottom stack. Each row is exactly 10 characters. A dot is an empty cell; digits 0–6 select an existing standard block color/type. Full rows, empty rows, invalid symbols, malformed widths and layouts that could overlap the spawn zone are rejected. Layout application is atomic: invalid input must not mutate the live board.

## Runtime behavior
- The layout is applied to a fresh campaign-owned 10×23 board before the initial piece is spawned.
- The first active piece remains a standard piece unless the planet explicitly declares the already-approved Cargo Hook event.
- Cargo Hook remains restricted to authored campaign planets; it does not enter Classic, Sprint/Marathon or Block Run.
- Leaving an unfinished planet still restarts that attempt; completed progression and rewards persist.

## Validation
- Unit tests cover valid layout application, exact occupied-cell count, invalid-layout rejection without mutation and safe standard-piece spawning.
- Catalog tests cover layout metadata and malformed-row rejection.
- Live integration test launches Planet 033 through the real campaign entry point and verifies the authored board is active without mutating the shared Classic model.
- Visual CI captures Planet 033 briefing and live arena screens.
- Full Godot CI must pass before this KT is accepted.

## Remaining KT-545 work
- Extend the mission definition schema with explicit objective variants, authored difficulty/duration bands and deterministic event metadata.
- Add more than one authored layout per mission family and test fair completion paths.
- Complete the 30-node Star Caravan pacing pass; do not label briefing-only entries as live mechanics.
- Produce a reviewable screenshot set for the newly authored layout missions.

## Acceptance boundary
This slice proves the authored-layout runtime seam; it does not mean the full Star Caravan chapter or all 360 planets are complete. No modifier registry entry becomes live without a dedicated runtime implementation, briefing, deterministic tests and visual proof.
