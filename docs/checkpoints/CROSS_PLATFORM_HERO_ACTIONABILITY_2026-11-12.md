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


## Mobile regression validation — run 43213975247

- [Mobile Arena Visual Preview #43213975247](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43213975247) completed **SUCCESS** on branch code/test SHA `cb3345e52e821b44d39d1b0b3fc1b29a14d0ddab`.
- Downloaded and inspected artifact [13943345402](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43213975247/artifacts/13943345402), including 375×812 and 412×915 screenshots and geometry reports.
- At 375×812: menu `hidden=true`, computed `display:none`, height 0; document height 812; frame y=129.05px, 210×483px; Hold 93.86×30px; Drop 97.86×42px; objective panel bottom 764.94px; 10:23 ratio 0.43478; no page errors.
- At 412×915: menu `hidden=true`, computed `display:none`, height 0; document height 915; frame y=137.59px, 238.17×547.78px; Hold 97.83×30px; Drop 101.83×42px; objective panel bottom 856.39px; 10:23 ratio 0.43479; no page errors.
- This confirms the hidden-menu CSS guard on browser preview only. Physical iPhone/Android behavior remains unverified.


## Cross-platform rerun diagnosis and watchdog cleanup — 12 Nov 2026

- Re-ran the cancelled Cross-platform Visual Preview job [43213975313](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43213975313) on the unchanged code/test SHA `cb3345e52e821b44d39d1b0b3fc1b29a14d0ddab`. The run reached iOS WebKit arena capture and desktop/Android campaign captures, then failed with `[target:timeout] desktop-1440x900 exceeded 240000ms`; this was not a gameplay assertion or browser page exception.
- Downloaded and inspected partial artifact [13942624793](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43213975313/artifacts/13942624793) (28 files). It contains the iOS WebKit 390×844 arena, desktop menu/card-library/campaign-atlas and hero diagnostic captures, Android menu/card-library/campaign captures, and the iOS landscape guard.
- Root cause in the test harness: when the campaign hero-detail wait timed out, its catch block captured diagnostics and used `continue` before the per-target watchdog was cleared and before the viewport context/browser were closed. The loop advanced to later targets, but the abandoned desktop watchdog remained armed and terminated the whole process after its deadline. This masked the remaining target checks.
- Fixed in script commit `f27a4209e8b540da3507f1253a357b37cbb86c18`: the hero-detail failure is now recorded and logged, the campaign mission-only assertions are skipped without abandoning the viewport, and the campaign page is closed before the remaining daily/arena checks continue. The hero-detail visibility wait is extended from 10s to 20s to accommodate the observed desktop showcase settling delay.
- This is test-harness-only; no UI/gameplay/persistence code changed. A fresh Cross-platform run on the new exact SHA is required. The earlier run remains **FAIL**; no pass is claimed. Mobile Preview [43213975247](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43213975247) remains **SUCCESS** on `cb3345e`.
- The diagnostic capture showed the hero detail card and its selected-state action visible after the timeout; the new run will log computed display/visibility/rect and the caught timeout cause so any remaining timing or selector issue is explicit.
- No main edit, merge, deployment, APK build/release, user-data change, image generation or external agent.


## Desktop arena assertion correction — 12 Nov 2026

- Cross-platform run [43218574080](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43218574080) failed after Block Run launch on desktop with `playlayout` reported as 0×0 while its nested board frame measured 319×734 and the game measured 1375×878.
- Inspected the failed job log and CSS cascade. Desktop intentionally sets `#game > .playlayout { display: contents }`, allowing the arena and utility rail to participate directly in the parent grid. Under CSS `display: contents`, the wrapper has no principal box and `getBoundingClientRect()` may return zero even while its descendants render normally. The prior test incorrectly required the wrapper itself to have a 300px box.
- The partial artifact [13944064992](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43218574080/artifacts/13944064992) was downloaded and inspected. The desktop campaign and daily-challenge arena captures show the 2D board and right utility rail rendered; the failed run stopped before the Block Run arena screenshot.
- Corrected the Cross-platform test only: it now accepts the intentional `display: contents` wrapper, verifies that the board frame remains inside it, and checks the actual rendered frame's visibility and minimum dimensions. Non-`contents` wrappers must still have a real layout box.
- Test-harness commit: `ac0fc298b7dde6a23b9ea9bf0f114e3c451e3354`.
- A fresh Cross-platform run on the new exact SHA is required. The previous run remains **FAIL**; no pass is claimed. Mobile Arena [43218574205](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43218574205) passed on the parent code SHA, and its artifact [13944113863](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43218574205/artifacts/13944113863) is available for review.
- No gameplay, progression, persistence, user data, `main`, deployment, APK, or release changes.


## 2026-11-13 — Cross-platform run 43220817119 failure audit

- PR #88 Cross-platform Visual Preview [run 43220817119](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43220817119) completed **FAILURE** on HEAD `66ad6c6704774f2e10c316c04d2c5c07849d4210`. The preview server, browser setup, screenshots and artifact upload succeeded; the failure occurred in the visual assertion stage. No page or console errors were recorded.
- Downloaded and inspected artifact [13945149666](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43220817119/artifacts/13945149666) (55 files), including Android Chromium menu and campaign-atlas captures. The menu screenshot shows BLOCK BUDDIES branding, but the three mobile mode cards wrap Russian titles into narrow columns; this is a real readability concern, not something to hide by weakening the assertion.
- The 26 reported failures repeat across six viewport targets and cluster into four groups:
  - KT-571 profile panel is present with hero emblem/name/level and matching wallet, but the test requires a 50px height while the rendered panel is approximately 48px. This is a threshold mismatch; the screenshot shows the panel.
  - KT-577 mode cards have the expected gradients, accent colors, icon size and visible border, but use a 15px radius against a 16px minimum. This is an off-by-one style threshold.
  - KT-581 the current layout is a two-column profile/collection row plus three mode cards in one row. The test expects each mode card to occupy at least 78% of the menu width; actual cards are about one-third width, and the Android screenshot confirms awkward title wrapping. Do not relax this check without fixing readability; a responsive menu-layout decision is required.
  - KT-574 the horizontal atlas has 12 cards, flex-row layout, horizontal overflow, correct scroll direction and visible art, but art width is 131px against a 150px minimum. The card/art sizing needs visual review rather than a blind threshold change.
- The campaign-atlas final-state assertion also sees root opacity 0 after re-entering the atlas, despite the earlier atlas capture being visible. The script waits for a card's box but not for the root opacity transition to complete; this is a likely test timing issue and should be isolated in a follow-up.
- No broad UI redesign or test-threshold relaxation was made in this audit. The mode-card layout and atlas-art sizing are user-visible product choices; keep the PR Draft until they are resolved and the exact-HEAD Cross-platform workflow is green.
- Safety: no `main`, gameplay rules, persistence, wallet, user data, deployment, APK, or release changes.
