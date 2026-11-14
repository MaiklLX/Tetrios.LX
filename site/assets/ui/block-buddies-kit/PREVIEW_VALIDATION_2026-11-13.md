# KT-427 preview evidence — 2026-11-14

## Parent branch snapshot

- PR: [#76 — KT-427: restore BLOCK BUDDIES pixel brand identity](https://github.com/MaiklLX/Tetrios.LX/pull/76)
- Branch: `design/kt427-block-buddies-brand-identity-2026-11-07`
- Current PR #76 HEAD before KT-427.14 evidence refresh: `eeb317d8af147b29ddeba3733cac2141c5097b68`
- PR remains Draft. It is 66 commits ahead / 90 behind current `main@20d66e3171522feb010a81522dc3f5cf4334d936`; mergeability is false. Do not rebase or merge mechanically.

## Stacked regression runs inspected

The test-only PR #89 branch is based on parent checkpoint `4f1275311d817d319a2200755ecdfd6cc9fced8e`, not the latest parent HEAD above. These runs validate the selector/control changes in that stacked snapshot, but are not substitutes for a fresh exact-parent run.

- Mobile Arena Visual Preview [run 43221596069](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43221596069) — **SUCCESS** on test SHA `f575269f4650d8480fc94bdc83b8fce3fc52e88f`.
- Downloaded and inspected artifact [13946127573](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43221596069/artifacts/13946127573). The geometry report records both 375×812 and 412×915. On both targets Hold, Pause and Drop are visible, enabled, pointer-events `auto`, and center-hit-testable; Resume is visible/enabled/hit-testable after Pause. Hold and Drop handlers were dispatched; Pause → Resume returned to the active arena; pageErrors are empty.
- Cross-platform Visual Preview [run 43221596341](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43221596341) — **SUCCESS**, 10 viewport targets, zero report failures.
- Downloaded and inspected artifact [13945249106](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43221596341/artifacts/13945249106): desktop Chromium, iOS WebKit portrait/landscape, and Android Chromium portrait/landscape captures are present. The nested runtime selector resolves the same frame as the geometry report; the 375×812 frame and rail are both 494.75px high, and the 412×915 inset rail is retained. The landscape guard captures are present. No page or console errors were recorded; the cancelled soundtrack request during WebKit teardown did not fail the run.
- The screenshots confirm the BLOCK BUDDIES wordmark and procedural Buddy identity are visible in the menu. Browser captures are not physical-device acceptance.

## Exact-parent validation gate

This file is updated under `site/**` to request fresh path-filtered Mobile Arena and Cross-platform workflows against the resulting PR #76 head. Do not mark KT-427 complete until those fresh runs finish on that SHA and their artifacts are inspected.

## Safety

No gameplay, balance, persistence, wallet, campaign, user data, or old project changes. No `main` edit, merge, deployment, APK build/release, image generation, or external code agent. Physical iPhone/Android touch and orientation behavior remains unverified.


## 2026-11-14 — KT-427.13: coordinate touchscreen path; exact-parent CI requested

- Current PR #76 branch HEAD before this validation-record update: `a33174ec979217644d0f05d04c6086dfc3e73500`.
- The preview script now uses verified coordinate `page.touchscreen.tap()` for mobile contexts. Before tapping, it checks that `document.elementFromPoint()` resolves to the intended control; after the tap, the test checks the actual Hold/Drop/Pause/Resume state transitions. Desktop continues to use mouse clicks. Runtime gameplay/CSS is unchanged.
- The preceding `locator.tap()` timeout is from the separate stacked test-only PR [#90](https://github.com/MaiklLX/Tetrios.LX/pull/90), head `36e63f466d95baf1f5b867f090e38c8e1e31412d`, not from PR #76. Cross-platform run [43592769174](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43592769174) failed only at iOS WebKit 375×812 while tapping Pause: the button resolved and was visible, enabled and stable, but Playwright's `locator.tap()` timed out after the tap began. No page exception was reported. The run's partial artifact is [14113042274](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43592769174/artifacts/14113042274); it did not reach the final iOS gameplay capture.
- PR #76 current HEAD had no associated check-runs/workflow runs at this audit. This update is under `site/**` specifically to request fresh path-filtered Mobile Arena and Cross-platform previews on the updated parent PR head.
- Acceptance remains pending until both workflows complete on the resulting PR #76 HEAD and their artifacts/geometry reports are inspected. A stacked test PR or older SHA is not an exact-parent substitute.
- Browser automation remains separate from physical-device testing. Keep PR #76 Draft; no merge, rebase, deployment, APK, game-rule, save-data or user-data changes.


## 2026-11-14 — KT-427.14: coordinate-touch regression evidence

### Earlier PR #76 preview baseline

- Mobile Arena Visual Preview [run 42406781492](https://github.com/MaiklLX/Tetrios.LX/actions/runs/42406781492) — **SUCCESS** on SHA `a20795c9a6e3dcd5bef498aee3c4907ba04dbac8`.
- Cross-platform Visual Preview [run 42406781408](https://github.com/MaiklLX/Tetrios.LX/actions/runs/42406781408) — **SUCCESS** on the same SHA.
- Downloaded and inspected mobile artifact [13587746752](https://github.com/MaiklLX/Tetrios.LX/actions/runs/42406781492/artifacts/13587746752): both 375×812 and 412×915 screenshots are present. The geometry report records no horizontal page overflow; at 375×812 the board frame and utility rail are both 494.75px high, Hold and Drop remain inside the rail, and the goals panel stays inside the viewport. These captures are from the older a20795 snapshot, not the current PR #76 head.

### Touch interaction regression and fix

- Stacked test PR [#90](https://github.com/MaiklLX/Tetrios.LX/pull/90), head `36e63f466d95baf1f5b867f090e38c8e1e31412d`, failed Cross-platform Visual Preview [run 43592769174](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43592769174) on iOS WebKit 375×812. The log shows the Pause target was visible, enabled and stable; Playwright scrolled it into view and began `locator.tap()`, then timed out. No page exception was reported. This is a touch-automation timeout, not evidence that the Pause control is absent.
- The current PR #76 script at the parent snapshot uses coordinate-based `page.touchscreen.tap(x, y)` after verifying `document.elementFromPoint()` resolves to the intended control. It then checks actual state transitions: Hold changes the active piece, Pause sets the paused state, Resume clears it, and Drop changes the active piece.
- Stacked test PR [#91](https://github.com/MaiklLX/Tetrios.LX/pull/91), head `d1e906639a8652b8f9e0f9ce7afee1d5e0de0725`, based on PR #76 parent `a33174ec979217644d0f05d04c6086dfc3e73500`, passed Cross-platform Visual Preview [run 43593443365](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43593443365) — **SUCCESS**. Downloaded artifact [14113881848](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43593443365/artifacts/14113881848) contains 64 captures and a report for 10 targets with zero report failures and no page errors. Inspected the iOS WebKit 375×812 final arena screenshot and the 375×812 / 412×915 geometry records. This validates the coordinate-touch fix on the stacked a33174 parent, not the latest PR #76 head.
- PR #76 current HEAD `eeb317d8af147b29ddeba3733cac2141c5097b68` has no exact-head Mobile Arena or Cross-platform run. The latest runs on the PR #76 branch itself remain the older 2026-11-10 runs on SHA `67bf06715cf6566ec3f6360b257062d05163b1be`.

### Exact-head gate requested

This evidence refresh changes only this validation document under `site/**`, so the path-filtered Mobile Arena and Cross-platform workflows should run against the resulting PR #76 head. Acceptance remains **PENDING** until both exact-head workflows complete and their artifacts/geometry reports are inspected. Do not treat PR #91's stacked run or the older a20795 preview as exact-head confirmation.

### Safety

No gameplay/runtime code, balance, progression, save data, economy, campaign, old project, `main`, deployment or release was changed. PR #76 remains Draft. No APK build/export, image generation, DeepSeek Harness or external code agent was used. Physical Android/iPhone touch and orientation testing remains unverified.


## 2026-11-14 — KT-427.15: exact-head trigger outcome

- Evidence refresh commit `1a4794d52f03fbeac7c9b36955d3483d1696abb6` changed only this validation record under `site/**`. After the update, GitHub returned no workflow runs and no check-runs for that exact SHA; the PR #76 branch run history still ends with the 2026-11-10 Mobile Arena / Cross-platform runs on `67bf06715cf6566ec3f6360b257062d05163b1be`.
- Therefore the expected path-filtered Mobile Arena and Cross-platform jobs did **not** start on the resulting PR #76 head. This is a missing exact-head validation, not a passing check. Do not mark KT-427 complete.
- PR #91's coordinate-touch Cross-platform success remains useful stacked evidence on parent `a33174ec979217644d0f05d04c6086dfc3e73500`, but it is not an exact-head run for PR #76. PR #76 remains Draft and currently 67 commits ahead / 90 behind `main`; no mechanical rebase or merge was attempted.
- Next safe step: obtain a fresh Mobile Arena and Cross-platform run against the current PR #76 head, then inspect the resulting artifacts. Do not substitute old `a20795` previews or stacked PR #91 results.
- No runtime/gameplay, balance, progression, save data, user data, `main`, deployment, APK/export, image generation or external-agent changes.
