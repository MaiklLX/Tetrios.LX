# Tetrios.LX — project checkpoint

Last updated: 2026-11-01 (arena streak-response pass)

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
- PR purpose: optional mobile haptic feedback, safe background auto-pause, and responsive 3D rotation feedback.
- Added a haptic toggle beside the sound control in the header. It is hidden where `navigator.vibrate` is unsupported.
- Haptics are user-toggleable, persisted in `localStorage.bb_haptics`, and used for successful rotations, hard drops and line clears. The 4-line clear gets a stronger pattern; blocked rotations do not vibrate.
- Main 2D game logic, classic mobile layout, and 3D arena remain unchanged.
- Updated `site/validate-3d-runtime.mjs` to assert haptic capability guarding, persisted preference, and event feedback.
- Inline gameplay script syntax was checked successfully with `new Function` after the background-pause change.
- Added `bbHandleVisibilityChange()`: if Android backgrounds the WebView during an active round, the game opens its existing pause overlay and remains paused until the player explicitly taps RESUME. No automatic resume on return; no changes to menu flow or an already-paused round.
- Runtime validator now asserts the visibility handler and active-round guard.
- Successful piece rotations now trigger a light 9 ms haptic pulse. The rotate function only emits feedback when a rotation or wall-kick succeeds; failed rotations remain silent.
- 3D rotation feedback: when a tetromino rotates, a short mint-colored arc appears around its pivot, gently expands and rotates, then disposes itself. It uses the existing capped transient-effects manager, respects reduced-motion by not animating, and does not change game rules or inputs.
- Landing flashes now also pass through `addEffect()` instead of bypassing the 96-effect cap. This closes a small resource-management gap during rapid locking.
- Line clears now add a brief camera-only impact pulse, scaled by the number of cleared lines; the 2D UI and game logic are untouched.
- Arena streak response: the existing metallic side-rail material receives a subtle, short emissive pulse after line clears. The pulse scales gently with line count and consecutive clears, fades within 720 ms, and reuses the existing material (no new meshes, particles, timers, or render loops). It runs inside the existing animation frame and respects reduced-motion mode.

## Main screen redesign — 2026-11-01
- Gameplay-space redesign is paused by user request; current 2D/3D arena and gameplay presentation remain unchanged.
- Main menu is being reorganized as a responsive one-viewport dashboard across desktop, tablet and mobile.
- Preserved existing feature hooks and data IDs: game modes, Android APK download, daily visit streak/repair, hero selection, shop, currencies, daily quests, record/run/relic stats, and full progress reset.
- Desktop uses a wide dashboard grid; narrow screens use a compact two-column composition with a featured primary run mode.
- Short-height devices below 620px retain natural vertical overflow instead of clipping content or making controls inaccessible.
- Responsive dashboard commits: markup `0b48a9c9e52d50a6b79094f768cf24e538f7e85e`; initial dashboard CSS `e30ed69c701a5d7f3261f0f905fe5eda9a3a8326`; mobile grid/screen-switch safety `1a2f077db2ee96e12d20233c3bcca684d20028f4`; featured primary mode `2a1d4b49b131751d63d390eb89b847b633f5bbc2`; short-viewport CSS safety `8124f9fd2343bd301273f0be4446db36192ad9f4`.
- Runtime validator addition: `83b8d20200b8c7e2c56019e7cd873654a0f09125`.
- Run `41238153870` completed successfully for the responsive dashboard source before the final featured-mode and short-viewport CSS refinements. Latest full audit `41238292740` is running for source commit `8124f9fd2343bd301273f0be4446db36192ad9f4`; verify its conclusion and artifact before sharing a new APK.
- The dashboard keeps the existing app identity and all existing click/data hooks; no gameplay screen or arena files were changed in this homepage pass.

## Current CI
- Android WebView audit PR run: `41217105665`
- Run URL: https://github.com/MaiklLX/Tetrios.LX/actions/runs/41217105665
- Run `41217105665` completed successfully for source commit `4b082c39510305f68ceeeeeeffd061342844af12`.
- Test APK artifact: `13048019167` (`Tetrios-LX-test-apk`, 18,904,326 bytes), expires `2026-11-14T15:56:05Z`.
- Artifact URL: https://github.com/MaiklLX/Tetrios.LX/actions/runs/41217105665/artifacts/13048019167
- Follow-up audit `41217232515` for checkpoint commit `d034f9685fdc8cd104699946521c1409ce5b5816` completed successfully and produced APK artifact `13048177545`.
- Latest source changes: auto-pause commit `32c533aba3e040e99ed3f5d29b789d264241d33a`, validator commit `27570ed6808cf8219a9e49e4cf3b8d44d53668e3`.
- Latest 3D feedback source commit: `78c289531469489c6b4c072c19832ab8e5b254b3`.
- Latest rotation haptics source commit: `0e0bb2b62c8a9e23aaf06c0f10f8cc39b41b58bd`.
- Latest haptics validator commit: `2cfca88be0277e22262bde7b080bc28b41d9885d`.
- Latest 3D effect lifecycle source commit: `b25da61f091bfa253ba60b164948cf33a098c1cb`.
- Latest 3D effect validator commit: `f680721d28faf3c17a4c2b5645cf0f99d3ff06b3`.
- Latest runtime validator commit: `81a06b69e7e88017aa8e51b076313888c7ad7c4a`.
- Latest verified pre-homepage audit run `41237316474` completed successfully for arena streak-response checkpoint commit `c8def368eec5d0dfbd9adc1484d206c5670f0c19`. The responsive homepage pass has a successful intermediate audit `41238153870`; the final CSS refinements are being checked by run `41238292740`. Verify its result and APK artifact before sharing a new build.

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
3. Verify subtle rail pulse after single and consecutive clears, including reduced-motion behavior and low-power Android devices.
3. Improve 3D/gameplay integration incrementally, retaining 2D as the reliable fallback.
4. Test the new 3D rotation arc: rotate pieces in both directions and check that the cue is brief, centred, and does not obscure the blocks.
4. Test background auto-pause by starting a round, switching to another Android app, then returning; confirm the pause overlay remains until RESUME is tapped.
5. Keep Android offline asset validation and APK build checks in CI.
6. Keep a fresh checkpoint after meaningful milestones and update this file with the latest verified branch, PR, commit SHA, audit run and artifact.
