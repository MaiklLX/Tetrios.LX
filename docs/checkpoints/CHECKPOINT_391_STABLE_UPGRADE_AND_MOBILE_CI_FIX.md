# TETRIOS LX — Checkpoint #391
Date: 2026-11-03

## Branch and safety
- Branch: `feature/gameplay-evolution-389-2026-11-03`
- PR: #50 (draft/open; base `main`)
- Implementation commits: `82793fa21bbafd1c16e944f05bed6884aaa95459` (Stable + mobile spacing) and `20e2e1a2da02944ce497f3dbbbd67a2e21cd0602` (validator correction). Latest source touch: `0a0051f1bca06c07e59baf9259a31af9efdf7795`.
- Golden Desktop Baseline #372 remains protected; no merge, production deployment, or APK build.

## Completed
1. Implemented the first missing upgrade trigger: `stable` (Стабилизатор).
   - In Block Run only, rotation now tries deterministic horizontal wall-kicks.
   - Rank 1 permits up to 2 cells; higher ranks extend the cap up to 4 cells.
   - Standard modes retain the previous rotation behavior.
   - The catalogue effect description now reports the actual kick range.
2. Corrected the gameplay validator's monster telegraph assertion.
   - The prior regex expected the low-time warning declaration after the rendered attack label, but the source declares the warning before building the markup.
   - Assertions now independently verify the warning threshold and the visible attack label/countdown.
3. Tightened the bottom goals panel by 2 vertical pixels on compact screens (<=400px wide and <=840px high), addressing the 1.5px viewport overflow reported at 375x812 without changing the board geometry.

## CI findings before fixes
- Cross-platform visual preview failed during dependency preparation because the gameplay validator's telegraph regex was ordered incorrectly; Playwright never started.
- Mobile arena preview reached Playwright and found the objective panel bottom edge at 813.5px on a 375x812 viewport. The 412x915 viewport remained within bounds.
- The mobile screenshot artifact was reviewed; board aspect ratio remained 10:23 and the mobile controls/monster HUD were present.

## CI after fixes
- Mobile Arena Visual Preview #94 completed successfully; the compact 375x812 and 412x915 geometry checks passed. The artifact was inspected and the goals panel now ends at y=803.91 on the 812px viewport.
- Cross-platform Visual Preview #49 and #50 both reached browser installation and local server startup, but their screenshot-capture steps were cancelled by overlapping concurrency runs. They are not accepted as passing.
- A subsequent source-only comment commit (`0a0051f`) was pushed to request a clean cross-platform rerun. The PR-filtered run listing has not yet surfaced that push-triggered run; visual acceptance remains pending.
- No real-device iPhone Safari test has been performed.

## Upgrade audit remaining
The other seven catalog IDs still requiring implementation or explicit product decision:
- `prism`, `luck`, `void`, `gear`, `shift`, `aura`, `plasma`
Do not invent effects before checking their descriptions against existing gameplay flow. Keep the 35-card pool intact. Next candidate: inspect `plasma` against the drop-timer lifecycle; implement only if the advertised reset is not already happening for every lock/clear.

## Next steps
1. Confirm the clean cross-platform preview run and inspect desktop Chromium / iOS WebKit screenshots.
2. Audit the drop timer and decide whether `plasma` has a real missing trigger.
3. Add the next card in a separate tested increment.
4. Keep Block Run-only mechanics gated to `mode==='rogue'`; campaign and daily challenge must remain unchanged.
