# Cross-platform hero actionability checkpoint — 12 November 2026

## Scope

- Repository: `MaiklLX/Tetrios.LX`
- Branch: `fix/kt-cross-platform-hero-actionability-2026-11-12`
- Base snapshot: `main@20d66e3171522feb010a81522dc3f5cf4334d936`
- This is an isolated test-harness change. It does not modify the application UI, game rules, gameplay state, persistence, or user data.

## Confirmed failure

Cross-platform Visual Preview run [43028911729](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43028911729) failed on `main@20d66e3171522feb010a81522dc3f5cf4334d936` during the Desktop Chromium 1440×900 Block Run setup.

The workflow reached `[stage:block-run-start]`, opened the hero confirmation, resolved `#bbConfirmStartHero`, and then timed out in Playwright's `.click()` action while waiting for the element to be visible, enabled, and stable. The earlier iOS WebKit target completed. The failure occurred at `scripts/cross-platform-visual-preview.cjs:582`; no application exception was reported before the actionability timeout.

The failed run's artifact [13859103321](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43028911729/artifacts/13859103321) was downloaded and inspected. It contains the completed iOS arena/campaign captures and desktop menu/campaign captures, but no post-failure Block Run hero capture.

## Isolated test correction

- Wait for the confirmation button to be visible.
- Scroll it into view.
- Check that it is visible, enabled, has pointer events, and that the center-point hit test resolves to the button or one of its children.
- Dispatch the registered DOM click handler after the explicit hit test, then retain the existing assertion that the game arena becomes visible.

This separates Playwright's pointer-stability heuristic from the test's intended purpose (advancing the setup flow to the arena) without silently accepting an obscured or disabled control. Other control-interaction checks remain unchanged.

## Validation state

- Code change is committed on this feature branch only.
- Fresh Mobile Arena and Cross-platform Visual Preview runs are required for the new SHA.
- No green result is claimed until those exact-SHA runs complete successfully.
- Browser preview is not physical-device validation.

## Safety

- `main` was not changed.
- No merge, deployment, APK build/release, external code agent, image generation, or persistent user-data mutation was performed.
