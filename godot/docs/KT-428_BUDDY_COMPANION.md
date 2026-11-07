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
- KT-432 adds automated helper coverage for a common phone gutter (85px), a too-narrow gutter (60px), and a wide gutter (220px).
- KT-433 strengthens the tests across 70px, 85px, 120px, and 220px gutters, asserting the Buddy never crosses the 8px playfield clearance and never shrinks as space increases.
- KT-433 CI passed: workflow run 42422744181.
- KT-434 adds Hold storage/swap rules with a once-per-piece limit and a visible arena control; model tests cover first store, blocked repeat, re-enable after lock, and swap.
- KT-436 adds an always-visible pause control, a pause overlay with Resume, and keyboard shortcuts P / Escape; automated tests cover pause, resume, and the game-over guard.
- KT-437 adds compact HOLD and NEXT preview cards above the playfield; previews use the same seven-bag queue as gameplay, and the NEXT read does not consume or alter the queue.
- KT-437 automated tests verify preview stability, non-consumption, and that the next spawned piece matches the displayed preview; CI workflow run 42423152004 passed on the current PR head.
- KT-438 adds mobile board swipes: horizontal movement (distance-limited to 1–3 cells), downward soft drop (1–4 cells), and upward rotation. Touches beginning outside the board are left for the existing button/tap controls.
- KT-438 tests cover horizontal distance mapping, downward soft drop, upward rotation, and protecting taps outside the board; CI workflow run 42423231284 passed (Godot import, script parse, model tests, scene smoke test).
- KT-436 CI passed: workflow run 42422966003.
- A full rendered Godot viewport geometry test is still outstanding; physical Android rendering remains unverified.
- No APK was built or released.
- No change to `main` or the public web deployment.

## Follow-up
- Review the rendered in-engine proportions on physical Android devices, especially narrow portrait screens.
- Add a small animation atlas or frame-based sprite only if profiling shows the procedural drawing is not sufficient.
- Later, wire the remaining Buddy personalities and gameplay reactions without changing core mechanics.
