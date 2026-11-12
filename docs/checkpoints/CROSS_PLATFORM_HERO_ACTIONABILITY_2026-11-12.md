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


## Follow-up from run 43211987358

The actionability adjustment advanced the test past hero confirmation. The next exact failure exposed two independent issues on the current main snapshot:

1. **Desktop arena collapsed:** after the confirmation handler ran, `#game` was unhidden and had `display:grid`, but its measured height was 0px. The desktop grid declared four rows (`auto auto auto 1fr`) while the daily objective is moved into the heading and the visible direct children are only the heading, HUD, and playlayout. The empty fourth track left the arena layout in an auto-sized row with a percentage-height child. The desktop grid now uses three rows so the playlayout receives the available 1fr track. The test now requires a desktop game height ≥400px, playlayout ≥300px, and board frame ≥300px.
2. **Campaign back bridge scope:** the main gameplay script is wrapped in an IIFE, so its `bbNavigateBack` function is not visible to the later standalone `bb-kt632-ui-ready` script. That listener raised `ReferenceError: bbNavigateBack is not defined`. The function is now explicitly exported as `window.bbNavigateBack`, and the listener calls that exported function. The cross-platform test verifies the global bridge and that the campaign back control returns to the home screen.

Updated code commit: `98503f22a3b3a52bed83b6e7d933564d70de9e03`.
Updated test commit: `c53d17e8b95d85b066ca0915854596145f5db4f9`.

Fresh Cross-platform Visual Preview on the new branch HEAD is required. No success is claimed until it completes.


## Mobile preview finding — run 43213291239

The first Mobile Arena Visual Preview on the branch failed at both 375×812 and 412×915. Its screenshots showed the full home dashboard still occupying the page while the newly opened 2D arena began below it (frame y=876px and y=988px respectively). The menu had been assigned its HTML `hidden` state by the screen switcher, but the late `#menu.home-dashboard { display:grid }` brand rule still won the cascade, so the hidden menu retained layout space.

A final, higher-specificity guard now enforces `#menu.home-dashboard[hidden] { display:none!important }`. The mobile workflow now checks the menu's hidden/display/height state, arena frame top, and document height in addition to the existing 10×23 geometry, Hold/Drop visibility, objective placement, and 2D renderer checks.

Application fix commit: `4cfb0cf33806f384de8eef2ed4678c10191e3276`.
Mobile regression-test commit: `e119164f19f65068c8538109ce96cd9291394cf7`.

The exact new HEAD still requires fresh Mobile Arena and Cross-platform runs; no PASS is claimed.


## Specificity correction — Mobile Preview run 43213745135

The first hidden-screen guard did not outrank the older triple-`.home-dashboard` selector at `site/index.html:5759`, which still applied `display:grid!important`. The failed run confirmed `hidden:true` but `display:grid` and a 750–853px menu height.

The guard now uses the same four-class specificity pattern already present in the legacy cascade, plus the `[hidden]` state, so it wins over the triple-class display rule. The mobile regression assertion remains strict; the next exact-SHA run must prove `display:none`, zero menu height, and an arena frame near the top of the viewport.

Corrected CSS commit: `71cfaa677f17f0b874a8899fc5342a3c54f179a3`.
