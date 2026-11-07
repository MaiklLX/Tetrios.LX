# KT-428 — Buddy companion: first Godot integration

Date: 2026-11-07

## Scope
- Keep the existing 10×23 board and game model unchanged.
- Add an original, code-drawn pixel Buddy companion in saturated blue/cyan.
- Keep the asset self-contained: no image generation, external downloads, or imported proprietary art.
- Place the companion in the left gutter beside the portrait playfield; scale it to fit the available gutter on phone screens and hide it only when the gutter is too narrow.
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
- Godot 4.4.1 headless import, main-script parse, model tests, and scene smoke test passed on KT-428 and again after the KT-430 / KT-431 layout commits.
- KT-430 moves the minimum safe-gutter visibility threshold to 126px to prevent overlap at wider viewports.
- KT-431 scales Buddy to the actual left-gutter width, anchors it at an 8px inset, and keeps an 8px gap before the playfield; this makes the companion available on common phone portrait widths rather than only tablets.
- Runtime geometry is still not covered by a dedicated Godot viewport test; physical Android rendering remains unverified.
- No APK was built or released.
- No change to `main` or the public web deployment.

## Follow-up
- Review the rendered in-engine proportions on physical Android devices, especially narrow portrait screens.
- Add a small animation atlas or frame-based sprite only if profiling shows the procedural drawing is not sufficient.
- Later, wire the remaining Buddy personalities and gameplay reactions without changing core mechanics.
