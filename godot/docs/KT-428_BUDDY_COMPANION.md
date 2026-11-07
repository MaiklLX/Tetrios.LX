# KT-428 — Buddy companion: first Godot integration

Date: 2026-11-07

## Scope
- Keep the existing 10×23 board and game model unchanged.
- Add an original, code-drawn pixel Buddy companion in saturated blue/cyan.
- Keep the asset self-contained: no image generation, external downloads, or imported proprietary art.
- Place the companion in the safe left gutter beside the portrait playfield; hide it automatically when the viewport has no room.
- Connect the character to gameplay events:
  - idle during normal play;
  - happy after a line clear;
  - victory after a four-line clear;
  - surprised when the run ends;
  - return to idle after the reaction window or a restart.

## Files
- `godot/scripts/buddy_companion.gd` — procedural pixel character and four expressions.
- `godot/scripts/main.gd` — layout placement and event-to-expression wiring.

## Verification status
- Source changes committed on `godot/kt428-buddy-companion-2026-11-07`.
- Godot 4.4.1 headless import, parser, model tests, and scene smoke test must pass in CI before this is considered validated.
- No APK was built or released.
- No change to `main` or the public web deployment.

## Follow-up
- Review the CI result and rendered in-engine proportions.
- Add a small animation atlas or frame-based sprite only if profiling shows the procedural drawing is not sufficient.
- Later, wire the remaining Buddy personalities and gameplay reactions without changing core mechanics.
