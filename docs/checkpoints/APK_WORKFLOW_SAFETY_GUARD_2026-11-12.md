# APK workflow safety guard — 12 November 2026

## Scope

- Branch: `feature/gameplay-evolution-389-2026-11-03`
- Existing Draft PR: [#49 — cross-platform visual preview and gameplay audit](https://github.com/MaiklLX/Tetrios.LX/pull/49)
- This change is limited to the APK workflow trigger policy on the feature branch.

## Finding

On 11 November 2026, five successful `Build Block Buddies APK` workflow runs were triggered by `push` events on this branch. The latest inspected run is [42977208354](https://github.com/MaiklLX/Tetrios.LX/actions/runs/42977208354), which uploaded a `Block-Buddies-debug-apk` artifact (ID `13836346482`, 46,533,258 bytes). These runs were not initiated by this automation session. The artifact was not downloaded or opened.

The cause was explicit in this branch's workflow definition: `.github/workflows/build-apk.yml` included `push` triggers for `main` and `feature/gameplay-evolution-389-2026-11-03`. The current `main` version already uses `workflow_dispatch` only.

## Guard applied

- Removed the automatic `push` trigger from `build-apk.yml`.
- Removed the automatic `push` trigger from `release-apk.yml`.
- Both workflows now require a manual `workflow_dispatch` event. No manual dispatch was made.

The existing debug artifact and the historical prerelease were not deleted or modified. This guard prevents ordinary pushes to this feature branch from starting new APK build/release workflows. It does not itself prevent a user with Actions permissions from manually dispatching a workflow.

## Validation and safety

- Trigger headers were inspected before and after each update.
- The workflow edits are on the existing feature branch only.
- No APK build, release, deployment, merge, or main-branch modification was performed by this session.
- Existing artifact [13836346482](https://github.com/MaiklLX/Tetrios.LX/actions/runs/42977208354/artifacts/13836346482) remains untouched.


## Planet-route preview timing follow-up — 12 November 2026

Cross-platform run [43212698789](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43212698789) failed only on the planet-map route assertions across desktop and iOS WebKit. The downloaded artifact [13942333137](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43212698789/artifacts/13942333137) was inspected: the navigation screenshot visibly shows the next-route button has moved the map to planets 7–13, while the test's fixed 420ms check still reported no advance. The UI uses `scrollBy/scrollTo({behavior:'smooth'})`; the fixed delay was not a reliable completion condition.

The test now:
- records the initial `scrollLeft`;
- waits for the smooth scroll to settle (up to 2.5s) before comparing the next-route position;
- computes the exact centering target for the current planet;
- waits for the jump-to-current smooth scroll to settle before asserting within 8px of that target.

This is a test-harness timing correction only; no campaign data, unlock state, route mechanics, or user progress is changed. Fresh Cross-platform Preview on the new branch HEAD is required before acceptance.

Test commit: `a8df8112d2bed630b73fe1d432d3209536617b22`.
