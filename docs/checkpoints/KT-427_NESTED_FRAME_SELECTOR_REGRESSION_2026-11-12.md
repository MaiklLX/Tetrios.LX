# KT-427 nested arena-frame selector regression — 12 November 2026

## Scope

- Parent branch: `design/kt427-block-buddies-brand-identity-2026-11-07`
- Parent HEAD: `4f1275311d817d319a2200755ecdfd6cc9fced8e`
- Test branch: `test/kt427-nested-frame-selector-2026-11-12`
- This is a stacked, test-only change intended to validate the KT-427.8 selector correction in the parent PR.

## Regression guard

The 375×812 iOS WebKit preview now records whether the runtime selector path

`#game .playlayout` → `.querySelector('.boardframe')`

resolves the same board frame used by the geometry report. It also records the frame wrapper tag/class for diagnostics. The 375×812 target fails if this nested lookup is absent or resolves a different element.

This specifically guards the DOM structure that caused the earlier null frame lookup and missing measured rail scale. The existing alignment and explicit-scale assertions remain unchanged.

## Validation

- Parent PR #76 contains code fix `969439e69f4ef7f660ca5b4be484e680467ba8cf` and the checkpoint-only commit `4f1275311d817d319a2200755ecdfd6cc9fced8e`.
- A fresh Cross-platform Visual Preview run on this stacked PR is required before the selector fix can be accepted.
- The Mobile Arena preview remains a separate workflow; its earlier Chromium pass does not replace iOS WebKit validation.
- No result is marked PASS until the exact new SHA completes successfully.

## Safety

- Test code and this checkpoint only; no gameplay/UI/persistence changes.
- No `main` modification, merge, deployment, APK build/release, image generation, external code agent, or user-data mutation.
- Physical-device behavior remains unverified.


## Validation result — 12 November 2026

- [Cross-platform Visual Preview #43212247116](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43212247116) completed **SUCCESS** on code/test SHA `d98bdb58f009d9712b8a9c6113e319d4535e30bb`.
- All 13 workflow steps passed, including desktop Chromium and iOS WebKit capture.
- Downloaded and inspected artifact [13942522741](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43212247116/artifacts/13942522741) (64 files). The 375×812 and 412×915 iOS WebKit arena screenshots show the game replacing the menu, with the 2D board, Hold, and Drop visible.
- The report records `frameSelector.found=true` and `matchesArenaFrame=true` on the nested selector path; the 10:23 ratio is approximately `0.43477`. No page errors, console errors, or failed requests were reported.
- Desktop Chromium and Android Chromium preview captures also completed in the same run. The landscape orientation-guard captures are present.
- This validates the browser-preview selector fix on the stacked branch only. It does not resolve PR #76's divergence from current `main`, and it does not prove physical-device behavior.
