# KT-427 exact-parent preview evidence — 2026-11-13

## Parent branch snapshot

- PR: [#76 — KT-427: restore BLOCK BUDDIES pixel brand identity](https://github.com/MaiklLX/Tetrios.LX/pull/76)
- Branch: `design/kt427-block-buddies-brand-identity-2026-11-07`
- Parent HEAD before this validation-record commit: `de44ce949d19b4e8ea84f2a2b5dbdfe08581897d`
- PR remains Draft. It is 56 commits ahead / 90 behind current `main@20d66e3171522feb010a81522dc3f5cf4334d936`; mergeability is false. Do not rebase or merge mechanically.

## Stacked regression runs inspected

The test-only PR #89 branch is based on parent checkpoint `4f1275311d817d319a2200755ecdfd6cc9fced8e`, not the latest parent HEAD above. These runs validate the selector/control changes in that stacked snapshot, but are not substitutes for a fresh exact-parent run.

- Mobile Arena Visual Preview [run 43221596069](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43221596069) — **SUCCESS** on test SHA `f575269f4650d8480fc94bdc83b8fce3fc52e88f`.
- Downloaded and inspected artifact [13946127573](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43221596069/artifacts/13946127573). The geometry report records both 375×812 and 412×915. On both targets Hold, Pause and Drop are visible, enabled, pointer-events `auto`, and center-hit-testable; Resume is visible/enabled/hit-testable after Pause. Hold and Drop handlers were dispatched; Pause → Resume returned to the active arena; pageErrors are empty.
- Cross-platform Visual Preview [run 43221596341](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43221596341) — **SUCCESS**, 10 viewport targets, zero report failures.
- Downloaded and inspected artifact [13945249106](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43221596341/artifacts/13945249106): desktop Chromium, iOS WebKit portrait/landscape, and Android Chromium portrait/landscape captures are present. The nested runtime selector resolves the same frame as the geometry report; the 375×812 frame and rail are both 494.75px high, and the 412×915 inset rail is retained. The landscape guard captures are present. No page or console errors were recorded; the cancelled soundtrack request during WebKit teardown did not fail the run.
- The screenshots confirm the BLOCK BUDDIES wordmark and procedural Buddy identity are visible in the menu. Browser captures are not physical-device acceptance.

## Exact-parent validation gate

This file is added under `site/**` so the PR's path-filtered Mobile Arena and Cross-platform workflows run against the current PR #76 head. Do not mark KT-427 complete until those fresh runs finish on the resulting parent SHA and their artifacts are inspected.

## Safety

No gameplay, balance, persistence, wallet, campaign, user data, or old project changes. No `main` edit, merge, deployment, APK build/release, image generation, or external code agent. Physical iPhone/Android touch and orientation behavior remains unverified.


## 2026-11-14 — KT-427.13: coordinate touchscreen path; exact-parent CI requested

- Current PR #76 branch HEAD before this validation-record update: `a33174ec979217644d0f05d04c6086dfc3e73500`.
- The preview script now uses verified coordinate `page.touchscreen.tap()` for mobile contexts. Before tapping, it checks that `document.elementFromPoint()` resolves to the intended control; after the tap, the test checks the actual Hold/Drop/Pause/Resume state transitions. Desktop continues to use mouse clicks. Runtime gameplay/CSS is unchanged.
- The preceding `locator.tap()` timeout is from the separate stacked test-only PR [#90](https://github.com/MaiklLX/Tetrios.LX/pull/90), head `36e63f466d95baf1f5b867f090e38c8e1e31412d`, not from PR #76. Cross-platform run [43592769174](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43592769174) failed only at iOS WebKit 375×812 while tapping Pause: the button resolved and was visible, enabled and stable, but Playwright's `locator.tap()` timed out after the tap began. No page exception was reported. The run's partial artifact is [14113042274](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43592769174/artifacts/14113042274); it did not reach the final iOS gameplay capture.
- PR #76 current HEAD had no associated check-runs/workflow runs at this audit. This update is under `site/**` specifically to request fresh path-filtered Mobile Arena and Cross-platform previews on the updated parent PR head.
- Acceptance remains pending until both workflows complete on the resulting PR #76 HEAD and their artifacts/geometry reports are inspected. A stacked test PR or older SHA is not an exact-parent substitute.
- Browser automation remains separate from physical-device testing. Keep PR #76 Draft; no merge, rebase, deployment, APK, game-rule, save-data or user-data changes.
