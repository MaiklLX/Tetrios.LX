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
