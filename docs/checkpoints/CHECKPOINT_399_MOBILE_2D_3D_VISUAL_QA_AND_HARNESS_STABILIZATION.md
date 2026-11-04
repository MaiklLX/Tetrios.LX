# CHECKPOINT 399 — Mobile 2D/3D Visual QA and Cross-Platform Harness Stabilization

Date: 2026-11-03
Repository: MaiklLX/Tetrios.LX
Branch: feature/gameplay-evolution-389-2026-11-03

## Safety constraints
- Do not change `main`.
- Do not merge PR #50.
- Keep Golden Desktop Baseline #372 untouched.
- Preserve the mobile arena ratio at 10:23.
- Do not build an APK yet.
- Do not deploy.
- Keep all further work on the branch above.

## Current implementation
- Prism spectral color is implemented and gated by the Prism upgrade.
- Prism colors the active piece, ghost and next-piece preview.
- Prism animation respects pause/game-over and reduced-motion conditions.
- Aura's 3D halo is wired to the active piece; 3D piece rendering updates with Prism color.
- Validators cover Prism gating/scheduling, reduced motion, 3D Aura halo and Prism color wiring.
- Campaign objectives and Block Run card isolation remain part of the current branch state.

## Mobile visual evidence — commit a7fd066367939c49421445e93b4218c6604b58cf
Mobile Arena Visual Preview #136 completed successfully.

Captured and inspected 2D and 3D screenshots at:
- 375×812
- 412×915

Measured arena geometry:
- 375×812: frame 247.17×568.48 px; ratio 0.43479097 (10:23); 3D canvas alignment delta 0 px; goals rail bottom 809.50 px; no page errors.
- 412×915: frame 277.25×637.67 px; ratio 0.43478474 (10:23); 3D canvas alignment delta 0 px; goals rail bottom 874.09 px; no page errors.

The mobile screenshots show both 2D and 3D arenas with the board and side controls visible. Mobile automated geometry checks passed.

## Cross-platform QA harness corrections
Earlier failures were in Playwright's click/navigation waiting, not confirmed gameplay assertions:
- Campaign start button now uses a forced click because its animated transition prevented stable-click completion.
- Hero selection and confirmation now invoke the element click directly, avoiding Playwright's wait for an unrelated scheduled navigation.
- These changes are limited to `scripts/cross-platform-visual-preview.cjs`; no gameplay logic was changed for these harness fixes.

## Active verification
- Cross-platform Visual Preview run #168: 41686415636.
- At checkpoint creation, dependency setup and local server startup were successful; capture step was still running.
- Await final Chromium 1440×900 and 1920×1080 captures, plus iOS WebKit 390×844 and 430×932 captures.
- Inspect 2D/3D alignment and campaign objective checks before declaring Prism/Aura fully accepted.
- If the harness fails again, inspect the exact failing locator/state and adjust only the test harness unless evidence demonstrates a real gameplay defect.

## Next step
Finish run #168, inspect the uploaded report and screenshots, then record a follow-up checkpoint with the final cross-platform outcome. Only after that QA is accepted should the next upgrade, Void, be implemented.
