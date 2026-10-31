# Tetrios.LX — project checkpoint

Last updated: 2026-10-31

## Resume phrase
**ТЕТРИОС — ПРОДОЛЖЕНИЕ С КОНТРОЛЬНОЙ ТОЧКИ**

When the user sends this phrase in a new chat:
1. Open this checkpoint and the latest open PR / branch.
2. Verify the current `main` SHA and compare the working branch against `main`.
3. Check the latest Android WebView audit run and artifacts before offering an APK.
4. Continue from the newest verified commit; do not restart the project or assume an older branch is current.
5. Preserve `backup/main-before-aaa-release-2026-10-31`; never overwrite or delete it.

## Stable baseline
- Repository: `MaiklLX/Tetrios.LX`
- Main at start of this iteration: `7d565ceb75d88803579377f73aa9d3d1caf01d4f`
- Preserved pre-release backup: `backup/main-before-aaa-release-2026-10-31`
- Previous visual release PR: #11 (merged into main)
- Previous release audit: run `41215456927` succeeded and produced a test APK artifact.
- The stable signed APK workflow on main failed at the signing repository lookup (HTTP 404 for `MaiklLX/Tetrios-Signing`); do not claim a signed release exists until a later run succeeds.

## Current work
- Working branch: `feature/gameplay-polish-next-2026-10-31`
- PR: #12 — https://github.com/MaiklLX/Tetrios.LX/pull/12
- PR purpose: optional mobile haptic feedback.
- Added a haptic toggle beside the sound control in the header. It is hidden where `navigator.vibrate` is unsupported.
- Haptics are user-toggleable, persisted in `localStorage.bb_haptics`, and used for hard drops and line clears. The 4-line clear gets a stronger pattern.
- Main 2D game logic, classic mobile layout, and 3D arena remain unchanged.
- Updated `site/validate-3d-runtime.mjs` to assert haptic capability guarding, persisted preference, and event feedback.
- Inline gameplay script syntax was checked successfully with `new Function`.

## Current CI
- Android WebView audit PR run: `41217105665`
- Run URL: https://github.com/MaiklLX/Tetrios.LX/actions/runs/41217105665
- Run `41217105665` completed successfully for source commit `4b082c39510305f68ceeeeeeffd061342844af12`.
- Test APK artifact: `13048019167` (`Tetrios-LX-test-apk`, 18,904,326 bytes), expires `2026-11-14T15:56:05Z`.
- Artifact URL: https://github.com/MaiklLX/Tetrios.LX/actions/runs/41217105665/artifacts/13048019167
- A follow-up audit for the docs-only checkpoint commit `d034f9685fdc8cd104699946521c1409ce5b5816` was queued as run `41217232515`; check its final result when resuming.

## Testing notes for user
Ask the user to test:
- Does the new vibration toggle appear on Android?
- Does it turn vibration on/off and retain the choice after reopening?
- Does hard drop give a short pulse?
- Do 1-line and multi-line clears feel appropriately different?
- Is the vibration too strong or distracting?

Do not claim device testing has happened; the user performs real-device testing.

## Next development priorities
1. Use the user's real-device feedback to tune or disable haptic patterns.
2. Continue improving gameplay completeness and tactile feedback without disturbing the classic mobile layout.
3. Improve 3D/gameplay integration incrementally, retaining 2D as the reliable fallback.
4. Keep Android offline asset validation and APK build checks in CI.
5. Keep a fresh checkpoint after meaningful milestones and update this file with the latest verified branch, PR, commit SHA, audit run and artifact.
