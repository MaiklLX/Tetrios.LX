# TETRIOS LX — Checkpoint #398
Date: 2026-11-03

## Branch and safety
- Branch: `feature/gameplay-evolution-389-2026-11-03`.
- PR #50 remains open/draft; do not merge or deploy.
- `main` is unchanged.
- Golden Desktop Baseline #372 is protected.
- Mobile arena geometry remains 10:23; no APK build.

## Recovered state
- Checkpoint #396 completed Aura in the 2D renderer and fixed the 375×812 objective rail.
- Mobile preview #109 passed: goals rail bottom 799.91px; board ratio approximately 0.43479.
- Cross-platform runs #91 and #92 were cancelled during iOS WebKit capture, not failed by a gameplay assertion.
- Checkpoint #397 already added strict separation of all 35 upgrade cards to Block Run and expanded deterministic campaign objectives. Static validation passed in both cancelled visual-preview runs, but campaign screenshots were not reached.

## Completed: Prism (Призма цвета)
- Prism animates the color of the active falling piece and the next-piece preview through a smooth spectral hue cycle.
- Settled blocks, ghost/collision rules, score, bag fairness, board dimensions, and line-clear logic are unchanged.
- The visual cycle is throttled and stops when the run is paused/over or reduced motion is requested.
- The same active-piece color is exposed to the 3D renderer.
- Aura now also has a dedicated soft halo behind active 3D cells, matching its 2D intent.
- No new card, reward, or mode access was added; the upgrade remains Block Run-only.

## Validation added
- Gameplay validator checks Prism's card gate, animation stop conditions, and active-piece color export.
- 3D runtime validator checks Aura/Prism visual-state wiring.
- Cross-platform preview must be rerun after these changes; do not claim acceptance until Chromium and WebKit finish.

## Next
1. Review the new CI run and inspect desktop 1440×900 / 1920×1080 plus mobile WebKit captures.
2. Confirm the 375×812 and 412×915 objective rails remain inside the viewport and the board remains 10:23.
3. Test Prism and Aura in 2D and 3D, including reduced-motion and pause behavior.
4. Only after visual acceptance, proceed to the next inactive upgrade card.
