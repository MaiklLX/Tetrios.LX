# TETRIOS LX — Checkpoint #391
Date: 2026-11-03

## Branch and safety
- Branch: `feature/gameplay-evolution-389-2026-11-03`
- PR: #50 (draft/open; base `main`)
- Implementation HEAD before this checkpoint: `20e2e1a2da02944ce497f3dbbbd67a2e21cd0602`
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
- New runs for the updated head are in progress:
  - Cross-platform Visual Preview #50
  - Cross-platform Visual Preview #49 (duplicate push-triggered run)
  - Mobile Arena Visual Preview #94
- Do not mark visual acceptance complete until the runs and their screenshots are reviewed.
- No real-device iPhone Safari test has been performed.

## Upgrade audit remaining
The other seven catalog IDs still requiring implementation or explicit product decision:
- `prism`, `luck`, `void`, `gear`, `shift`, `aura`, `plasma`
Do not invent effects before checking their descriptions against existing gameplay flow. Keep the 35-card pool intact. Next candidate: inspect `plasma` against the drop-timer lifecycle; implement only if the advertised reset is not already happening for every lock/clear.

## Next steps
1. Review the three in-progress visual runs and inspect screenshots at desktop and mobile sizes.
2. Confirm compact-screen goals panel no longer clips.
3. Audit the drop timer and decide whether `plasma` has a real missing trigger.
4. Add the next card in a separate tested increment.
5. Keep Block Run-only mechanics gated to `mode==='rogue'`; campaign and daily challenge must remain unchanged.
