# Tetrios.LX — project checkpoint

Last updated: 2026-11-01 (short-screen clipping audit)

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


## Latest main checkpoint — 2026-11-01
- Current branch of record: `main`
- Current source commit: `00d0aace786c8b8c2cf0992d1422cedfc876673c`
- PR #12 was merged successfully at `c51d094e870f9ef55d735b6c40e9bf1faefa629c`; subsequent dashboard refinements are being committed directly to `main` per user approval.
- Current iteration changes only `site/visual-overhaul.css`; gameplay arena, game rules, input handling and existing feature hooks were not modified.
- Added a dedicated dashboard geometry pass: normalized icon containers and button proportions, consistent alignment, resilient text wrapping, min-width safeguards, currency/quest card overflow protection, and compact topbar controls at narrow widths.
- CSS commit: `00d0aace786c8b8c2cf0992d1422cedfc876673c`.
- Website deployment run `41239739655`: waiting at checkpoint creation; verify completion before claiming the latest CSS is live.
- Android release workflow run `41239739630`: queued at checkpoint creation. The previous signed release attempt `41238880159` failed because GitHub returned HTTP 404 for `MaiklLX/Tetrios-Signing` during keystore retrieval; this is a signing-repository access/configuration issue, not a game-source compile failure.
- Do not offer an APK from an older run as if it includes this latest CSS commit. Verify the run/artifact for the current main SHA first.
- Next: continue responsive QA of the home dashboard across compact phone, tall phone, tablet and desktop widths; focus on clipping/overlap and touch-target comfort. Keep visual effects/art direction on hold until the user approves moving to that phase. Do not alter the gameplay arena.
- Preserve `backup/main-before-aaa-release-2026-10-31` unchanged.


## Latest main checkpoint — 2026-11-01 (content-first layout correction)
- Current branch: `main`
- Latest source commit: `14b5850a5c16dcaf101dd49a3756b16d782c251f`
- Dashboard CSS commits in this pass: `e451148cb1b4b002fb967e6bd98f097927a86694` and `14b5850a5c16dcaf101dd49a3756b16d782c251f`.
- Root cause addressed: the earlier dashboard used fixed viewport-height grid tracks and `overflow:hidden`, which could crop text, streak repair controls and quest details. The new content-first override removes the fixed height/max-height constraint, allows the dashboard and cards to grow, restores supporting copy and details, and allows natural page scrolling when the viewport is short.
- Responsive reflow: mobile mode cards retain full descriptions/tags with readable two-row arrangement; daily quests switch to a single-column list on very narrow screens; hero copy, streak details, resource labels and reset action are no longer hidden solely to force a one-screen fit.
- Existing IDs, handlers and game logic are untouched. The static shop-button placeholder remains hidden because the existing JS relocates the single live shop button into `#rpgPanel`; this avoids a duplicate control.
- Gameplay arena and gameplay screens remain untouched. Visual-effects phase remains on hold until the user approves.
- Android debug workflow for latest commit: run `41240346307` (queued at checkpoint time); verify completion and artifact before sharing an APK.
- Previous source commit `e451148cb1b4b002fb967e6bd98f097927a86694` web deployment run `41240286036` succeeded, but it predates the small follow-up CSS correction. Verify the deployment triggered by `14b5850a5c16dcaf101dd49a3756b16d782c251f` before claiming that exact revision is live.
- Signed release workflow run `41240286047` failed again; verify logs if investigating. Previous runs show the signing repository lookup for `MaiklLX/Tetrios-Signing` returning HTTP 404. This is separate from the debug APK build.
- Preserve `backup/main-before-aaa-release-2026-10-31` unchanged at `1a6548446c938d77d737accb202ee368a116943c`.
- Next: inspect latest deployed page and test dashboard composition at narrow phone widths (including 360px), tablet and desktop; fix any real collisions without hiding content. Ask the user to verify on the physical Android device; do not claim device testing.


## Latest main checkpoint — 2026-11-01 (short-screen clipping audit)
- Current CSS source commit: `52b0671a5448545ee00ec618265cc9a3b86ede71`.
- Confirmed concrete source of hidden content: legacy `@media(max-height:700px)` rules were still hiding the hero description, mode tags and daily-quest reward labels. The previous content-first correction only restored these in a narrower <=620px height range, leaving a 621–700px band where content remained hidden.
- New override explicitly cancels the short-height hiding rules and removes fixed dashboard height/track constraints at every supported width.
- Daily quest cards now size to content; at <=420px they use a compact two-column inner layout with title and progress/reward retained, rather than forcing narrow three-column cards.
- Main dashboard cards and dynamic shop panel are permitted to grow; overflow is visible and page scrolling is allowed where required. Existing IDs, handlers and game logic remain unchanged.
- Website deployment run: `41242331153` (waiting at checkpoint time).
- Android debug APK run: `41242331169` (queued at checkpoint time). Do not share an APK for this revision until artifact is verified.
- Signed release run: `41242331168` (queued at checkpoint time); prior signed runs fail retrieving key from `MaiklLX/Tetrios-Signing` with HTTP 404.
- Preserve backup branch `backup/main-before-aaa-release-2026-10-31` unchanged at `1a6548446c938d77d737accb202ee368a116943c`.
- Next: confirm deployment and debug APK artifact; then review user's device feedback. Do not begin home-screen effects or change gameplay arena until the geometry has been verified.


## Main-screen art direction implementation — 2026-11-01
- User supplied the generated neon arcade menu as the explicit visual prototype and asked for a real site implementation, not another image. The implementation uses real HTML/CSS controls and preserves the existing game logic and navigation hooks.
- Main branch source commits:
  - HTML/menu structure and settings entry: `eb6000dcf232f892b64ca6a57726d54312cc991c`
  - Neon arcade dashboard layout and visual system: `5498dab88c86478d1a8cc28db740db20693fe6c2`
  - Browser title aligned to product identity: `53625162d8be966afa61354e4b3b850b7a0af839`
- The home screen now has a wider arcade composition with a smaller TETRIOS.LX wordmark, luminous central hero/orb, left-side mode actions, right-side hero/shop/download destinations, and a lower band for streak, currencies, records and daily quests. Layout collapses to a two-column/tablet and compact mobile composition rather than shrinking the whole page.
- Replaced the visible home/game sound controls with one intuitive hamburger settings button. Sound, music and haptic controls remain connected to the existing handlers and are available inside the settings overlay. The old sound/music buttons are hidden rather than deleted, preserving the existing audio synchronization hooks.
- Gameplay music control is removed from the playfield sidebar; the existing music toggle remains available in settings. Pause remains a dedicated icon-only control in the game header; gameplay logic and pause overlay are unchanged.
- Rebranded the page header and document title to TETRIOS.LX. Existing mode IDs, hero/shop/currency/quest/streak/stat IDs, gameplay logic, canvas and game navigation handlers are retained.
- No generated artwork is used as the page itself. The visual treatment is built from CSS gradients, layered borders, neon glow and a perspective grid.
- Current main SHA at checkpoint: `53625162d8be966afa61354e4b3b850b7a0af839`.
- Preserved backup branch remains `backup/main-before-aaa-release-2026-10-31` at `1a6548446c938d77d737accb202ee368a116943c`; do not modify it.
- CI for the new layout source commit `5498dab88c86478d1a8cc28db740db20693fe6c2`: deployment run `41244084591`, debug APK run `41244084487`, signed release run `41244084540` (all still running when checked). A preceding deployment run was cancelled after a newer commit superseded it; the signed build for the preceding commit failed. Latest title commit workflows: deploy `41244112831`, debug APK `41244112733`, signed release `41244112545` (pending/queued when checked). Verify latest run/artifacts before sharing a live URL or APK as the new revision.
- Next: verify the latest web deploy and Android debug APK; inspect CI logs for any runtime/markup validation failure; then refine actual page geometry against the reference without touching the gameplay arena. User should verify on a physical Android device; no physical-device test has been claimed.
- Research notes: classic puzzle-game menus benefit from a strong central focal point and clear mode destinations (Tetris Effect's mode-selection presentation and Puyo Puyo Tetris 2's separated Adventure/Solo/Online/Options destinations were useful references). Sources: https://media.gdcvault.com/gdc2019/presentations/Mizuguchi_Tetsuya_MakingTetrisEffect-ive.pdf and https://cdn.steamstatic.com/steam/apps/1259790/manuals/tenpex_WM_210216_Steam_en.pdf.
- Resume phrase: **ТЕТРИОС — ПРОДОЛЖЕНИЕ С КОНТРОЛЬНОЙ ТОЧКИ**


## Follow-up: central neon block arena built from interface elements — 2026-11-01
- Added a real CSS/HTML block-stack centerpiece inside the home hero. It is composed of individual colored, glowing block elements with a perspective frame and animated light response; it is not a background screenshot or a generated image.
- New source commits: hero centerpiece markup `2ff1003f6aef32f403f1640df2cea18e223316ca`; centerpiece styling `580dc6e84059f0e2f7951892c9b3392357519d86`.
- Latest main SHA at checkpoint: `580dc6e84059f0e2f7951892c9b3392357519d86`.
- Current CI for this SHA: web deployment run `41244190929` (pending), debug APK run `41244190902` (queued), signed release run `41244191005` (queued). Earlier signed build attempt `41244112545` failed at signing-key retrieval; this is the known external signing-repository access issue. Do not offer an APK or claim the latest revision is live until the corresponding latest artifact/deployment is confirmed.
- Preserve backup branch `backup/main-before-aaa-release-2026-10-31` at `1a6548446c938d77d737accb202ee368a116943c`.
- Next: verify deployment and APK workflow results; inspect the rendered page on phone/tablet/desktop and adjust proportions, especially the center scene and side cards. Keep gameplay arena/game rules unchanged. Ask user for physical-device feedback after a current APK is available.
- Resume phrase: **ТЕТРИОС — ПРОДОЛЖЕНИЕ С КОНТРОЛЬНОЙ ТОЧКИ**


## Portrait-first mobile menu correction — 2026-11-01
- User clarified that the primary target is portrait mobile, not landscape/desktop. The previous wide-screen composition is now overridden on phones in portrait orientation with a dedicated stacked arcade layout.
- CSS commit: `7d40d14e811dc969474cc1c158fecf7571740352` (`feat(ui): make portrait mobile the primary home menu layout`).
- Portrait order: compact TETRIOS.LX header and hero/board scene; full-width primary Block Run action; two-column Campaign/Daily Challenge; two-column Heroes/Shop; then visit streak, currencies, stats, APK download, daily quests and reset. Controls and content remain present, with normal vertical scrolling instead of clipping.
- Portrait breakpoint <=600px with a narrower <=390px refinement. Tablet and desktop compositions remain separate; landscape gameplay arena is not modified.
- Latest main SHA: `7d40d14e811dc969474cc1c158fecf7571740352`.
- Current web deploy run `41244821791`, debug APK run `41244821819`, signed release run `41244821682` are all in progress at checkpoint time. An earlier debug APK build for pre-portrait SHA `5c074c3bcd3b5ceb1b60bafefc83b262d5a1b8b5` succeeded, but it does not contain this portrait correction and must not be shared as current.
- Preserve backup branch `backup/main-before-aaa-release-2026-10-31` unchanged at `1a6548446c938d77d737accb202ee368a116943c`.
- Next: verify the latest deploy/APK artifacts, then ask user to check portrait phone layout and refine based on actual device proportions. No physical-device test has been claimed.
- Resume phrase: **ТЕТРИОС — ПРОДОЛЖЕНИЕ С КОНТРОЛЬНОЙ ТОЧКИ**


## Portrait menu geometry repair — 2026-11-01
- User reported the portrait home screen had visibly narrowed/distorted buttons and poor alignment; the previous layout was not acceptable.
- Root cause found in `site/visual-overhaul.css`: several historical dashboard overrides were stacked with conflicting grid templates, min-heights, display modes and short-screen rules. The final portrait block did not consistently neutralize all earlier geometry.
- Added a final, explicit portrait-only layout override in source commit `e5b9a48a5b7f87d3545cdc21a3ae3cb3178fbfd9`.
- New portrait structure uses a predictable two-column content-sized grid: full-width hero and primary run button; equal Campaign/Daily cards; equal Heroes/Shop cards; then full-width streak, currency, stats, APK, quests and reset. Buttons are explicitly full-width within their grid cells, with fixed icon boxes and flexible text columns; no fixed viewport height or clipped dashboard content.
- Changes are limited to `site/visual-overhaul.css`; no HTML, game logic, data, handlers, gameplay controls or arena changes.
- Current main SHA: `e5b9a48a5b7f87d3545cdc21a3ae3cb3178fbfd9`.
- CI for this commit: debug APK run `41246102332` and signed release run `41246102321`; both were in progress when recorded. Check latest run state and artifacts before sharing a build. Prior portrait APK run `41244821819` succeeded but predates this repair and should not be presented as the repaired version.
- Preserve `backup/main-before-aaa-release-2026-10-31` unchanged at `1a6548446c938d77d737accb202ee368a116943c`.
- Next: verify CI, then user should inspect the new portrait layout on their Android device. If it is still not right, revert the portrait-specific menu work rather than stacking more conflicting CSS. Do not start visual FX or change the gameplay arena until the user approves the geometry.
- Resume phrase: **ТЕТРИОС — ПРОДОЛЖЕНИЕ С КОНТРОЛЬНОЙ ТОЧКИ**


## Home hero tetromino showcase — 2026-11-01
- User approved the repaired portrait menu and requested a shorter logo/hero block, removal of the static Tetris board illustration, and restoration of the former rotating centerpiece with Tetris pieces cycling one after another instead of a cube.
- Updated `site/index.html`: shortened eyebrow to “ИГРАЙ • СОЗДАВАЙ • ПОБЕЖДАЙ”, shortened tagline to “Собирай фигуры. Побеждай.”, replaced the static board scene with seven semantic CSS-rendered tetrominoes (I, O, T, L, J, S, Z) inside the existing orb/relic area.
- Updated `site/visual-overhaul.css`: compact hero typography and spacing; removed the board illustration from layout; created glossy 3D-like rotating/fading sequence for seven pieces with staggered timing, retaining the previous orb/ring framing. Reduced-motion preference displays a static I piece. No JS, game logic, game data, navigation, gameplay arena or button geometry changed.
- Source commits: HTML `938ddbbca112c5df0f8af51c214b64e12b9e444b`; CSS `5ea3d1f114908936fa4c7a1293ed29e1530f9569`; animation timing refinement `297fd34d49b77e310f0c3592a8fb09e60440207f`.
- Current main SHA at source checkpoint: `297fd34d49b77e310f0c3592a8fb09e60440207f`.
- Preserve backup `backup/main-before-aaa-release-2026-10-31` unchanged at `1a6548446c938d77d737accb202ee368a116943c`.
- Next: verify web deploy and debug APK workflows for this SHA. User should review the hero/logo animation on an Android device before any further visual effects or gameplay changes.
- Resume phrase: **ТЕТРИОС — ПРОДОЛЖЕНИЕ С КОНТРОЛЬНОЙ ТОЧКИ**


## Home logo tetromino alignment and motion refinement — 2026-11-01
- User reported that the seven tetrominoes appeared inconsistently positioned and visually overlapped the logo. The cause was inconsistent shape footprints within a shared but insufficiently constrained grid.
- CSS commit: `d430331ae8009c6bc44e18d994547f4161e72fb7` (`fix(ui): align and smooth home tetromino showcase`).
- All seven shapes now use the same fixed 76×76px grid, identical 16px cells, explicit centering and a common transform origin. The showcase itself has a fixed centered stage so the shape does not jump between positions.
- Added slow continuous rotation (18s per revolution) independently of the visibility cycle. The seven-shape sequence now uses a 21s cycle with gentle ease-in/out opacity transitions and a brief hold, rather than abrupt 2s flips.
- Reduced-motion preference remains respected and displays one static centered I piece.
- Only `site/visual-overhaul.css` changed. HTML, game logic, navigation, data, buttons and gameplay arena were not modified. Backup branch remains untouched.
- Verify web deploy and Android debug APK workflows for this source commit before claiming it is live or sharing a build. Physical-device review is still required for the perceived centering and animation smoothness.
- Resume phrase: **ТЕТРИОС — ПРОДОЛЖЕНИЕ С КОНТРОЛЬНОЙ ТОЧКИ**


## Latest main checkpoint — 2026-11-01 (centered rotating emblem + home-menu expansion)
- Current main source commit: `93628e54798610399192651fd221281b2eade2d2`.
- Changed only `site/visual-overhaul.css`; existing menu HTML, IDs, handlers, gameplay logic, data, and gameplay arena are untouched.
- Removed the duplicate product name/tagline from the central hero area; the TETRIOS.LX name remains in the top header.
- Reframed the centerpiece as a single square neon emblem: a rotating square frame and subtle orbital ring surround the tetromino showcase. Tetrominoes retain the centered shared geometry, slow rotation, and soft cross-fades.
- Reallocated the dashboard around the emblem: mode choices on the left/upper area, hero selection and APK download alongside it, and quests, streak, shop, currencies, statistics and reset action in supporting grid areas.
- Added a dedicated narrow portrait layout with a centered emblem, two-column mode cards and compact supporting sections. Reduced-motion preferences disable the new frame/orbit motion.
- Website deployment workflow run: `41248794952` for this exact SHA; queued when checkpoint was written. Verify the run and deployment status before saying the new version is live.
- Visual layout is source-implemented but not yet verified on a physical Android device. The user should review the emblem centering, balance of menu controls, and whether the first screen avoids scrolling on their phone. Do not claim device testing.
- Preserved backup branch `backup/main-before-aaa-release-2026-10-31` remains at `1a6548446c938d77d737accb202ee368a116943c`; do not modify it.
- Next: inspect deployment run `41248794952`, then review the live result and tune any actual clipping/overlap based on the user's device feedback. Do not change the gameplay arena.
- Resume phrase: **ТЕТРИОС — ПРОДОЛЖЕНИЕ С КОНТРОЛЬНОЙ ТОЧКИ**


## Recovery checkpoint — 2026-11-01 (restore stable home layout)
- The expanded dashboard grid introduced in commit `93628e54798610399192651fd221281b2eade2d2` was visually broken on the user's device. Do not reapply that grid or its CSS block.
- Recovery commit: `6c6a2fe08fb3ed0c4595a30d923b802c247d8b77`. It removes only the appended block beginning `TETRIOS.LX — centered rotating emblem + expanded home controls` from `site/visual-overhaul.css`.
- This restores the prior home layout and preserves the earlier working tetromino showcase: common centered shape geometry, slow rotation and soft cross-fades from `d430331ae8009c6bc44e18d994547f4161e72fb7`.
- No HTML, game logic, navigation, data, gameplay arena or backup branch was changed.
- A new GitHub Pages deployment should be triggered by the recovery commit; verify its completion before telling the user the site is restored live.
- Next design pass: do not rearrange the dashboard grid. First adjust only the central hero/emblem within its existing layout bounds; preserve all menu dimensions and positions. Make one small change at a time and wait for user device confirmation before expanding scope.
- Backup branch `backup/main-before-aaa-release-2026-10-31` remains unchanged at `1a6548446c938d77d737accb202ee368a116943c`.
- Resume phrase: **ТЕТРИОС — ПРОДОЛЖЕНИЕ С КОНТРОЛЬНОЙ ТОЧКИ**


## Focused home emblem refinement — 2026-11-01
- CSS commit: `77277975a812631b15593677ad75881e25c1b489`.
- This is a narrowly scoped hero-only pass in `site/visual-overhaul.css`; it does not alter dashboard grid, menu card positions, dimensions, IDs, handlers, game logic, data or gameplay arena.
- Hid the duplicate TETRIOS.LX hero heading; the product name remains in the top site header. Kept the short supporting tagline.
- Changed the orb's inner frame to a 76×76px rounded square with slow rotation and retained a softer orbital ring.
- Corrected the horizontal/vertical offsets of the T, S and Z showcase shapes within the shared 4×4 stage so their visual centers align with the emblem.
- This is source-only verification so far. Wait for the matching deployment and debug APK workflows; physical Android review is still required. If the frame or piece alignment is not right on-device, revert this isolated block rather than changing dashboard geometry.
- The recovery baseline remains in commit `6c6a2fe08fb3ed0c4595a30d923b802c247d8b77`; do not reapply the failed expanded grid from `93628e5`.
- Preserve `backup/main-before-aaa-release-2026-10-31` unchanged at `1a6548446c938d77d737accb202ee368a116943c`.
- Resume phrase: **ТЕТРИОС — ПРОДОЛЖЕНИЕ С КОНТРОЛЬНОЙ ТОЧКИ**


## Unified home emblem pass — 2026-11-01
- CSS commit: `8a875c49add561a055180b70016f1fbefab662a6` (`refine(ui): unify centered neon home emblem`).
- Replaced the accumulated, conflicting home-emblem CSS tail with one consolidated hero-only ruleset. The preceding site styles and the stable menu layout remain intact.
- The logo now has one centered 76×76 neon square frame, a subtle orbit ring, and a single consistent 4×4 cell geometry for every tetromino.
- Applied optical-centre offsets based on each shape's actual four-cell footprint (I/O/T/L/J/S/Z), rather than ad-hoc margins. Shape transitions use one animation per piece, avoiding competing transform animations.
- Retained the product title in the header, removed the duplicate hero heading, and kept the short tagline.
- No HTML, JavaScript, menu cards, navigation, game logic, data, gameplay arena, or backup branch changed.
- The earlier web deployment and debug APK succeeded for source `e3d1b055ac76c92d9b8ead474617d4da484e10b2`; they do NOT include this new CSS pass. Verify fresh workflows for `8a875c49add561a055180b70016f1fbefab662a6` before saying this pass is live or offering its APK.
- Signed release APK remains blocked by the separate signing workflow failure; debug APK is the current test-build route.
- Physical Android review remains necessary; do not claim visual/device verification.
- Preserve backup `backup/main-before-aaa-release-2026-10-31` unchanged at `1a6548446c938d77d737accb202ee368a116943c`.
- Resume phrase: **ТЕТРИОС — ПРОДОЛЖЕНИЕ С КОНТРОЛЬНОЙ ТОЧКИ**


## Brand identity refinement — 2026-11-01
- CSS commit: `4af089883ab63ee9b2729a7f7cc47ce2027cb5b7` — `refine(brand): add persistent T tetromino signature`.
- Added a permanent four-cell T-shaped signature inside the emblem, using cyan-to-violet dimensional blocks and restrained glow. This gives TETRIOS.LX a repeatable visual mark even between the seven-piece transitions.
- Refined the frame with subtle internal axis lines and a broken cyan/violet orbital ring, strengthening the sci-fi/arcade identity without adding clutter.
- Kept the seven tetromino transitions and their existing shape geometry. The permanent T mark sits beneath the animated pieces and remains visible during transition gaps.
- Scope remains CSS-only and hero-only. No HTML, JS, gameplay, menu layout, or backup branch changes.
- Verified prior emblem CSS deployment and debug APK succeeded for `8a875c49add561a055180b70016f1fbefab662a6`; the new brand mark commit requires its own workflow verification before calling it deployed or offering its APK.
- Physical Android visual review is still pending.
- Resume phrase: **ТЕТРИОС — ПРОДОЛЖЕНИЕ С КОНТРОЛЬНОЙ ТОЧКИ**


## Latest verified checkpoint — 2026-11-01 (brand emblem deployed)
- Current branch: `main`; current source commit: `ec018399442a9b48b4a644390cb43cadce6efb87` (`fix(web): bust cached home emblem stylesheet`).
- Latest visual identity pass is the CSS-only T tetromino signature from `4af089883ab63ee9b2729a7f7cc47ce2027cb5b7`; the latest commit adds a cache-busting query to the stylesheet link in `site/index.html` so browsers/WebView clients fetch the current CSS.
- Matching GitHub Actions for `ec018399442a9b48b4a644390cb43cadce6efb87`:
  - Website deployment run `41270579978`: completed successfully.
  - Android debug APK run `41270580028`: completed successfully.
  - Debug APK artifact `Block-Buddies-debug-apk`, artifact ID `13069046640`, 18,924,590 bytes, expires `2026-11-15T03:49:36Z`.
  - GitHub Pages artifact ID `13069306012` is also attached to the successful APK workflow run.
  - Signed release APK run `41270580017`: failed in job `Build signed Android APK`, step `Download and decrypt signing key`; GitHub API returned HTTP 404 for `MaiklLX/Tetrios-Signing`. This is a signing repository access/configuration failure, not a failure of the debug APK or website deployment.
- Website and debug APK are verified for this exact source SHA. Physical Android visual verification remains pending; do not claim device testing.
- Preserve backup branch `backup/main-before-aaa-release-2026-10-31` unchanged at `1a6548446c938d77d737accb202ee368a116943c`.
- Next: invite the user to inspect the updated emblem and menu on their Android device using the current debug APK or deployed site. Only make further visual changes from concrete device feedback. If addressing signed release, separately repair access to `MaiklLX/Tetrios-Signing` and verify repository/file permissions; do not change app source to mask this external signing issue.
- Resume phrase: **ТЕТРИОС — ПРОДОЛЖЕНИЕ С КОНТРОЛЬНОЙ ТОЧКИ**


## Dimensional brand emblem — 2026-11-01
- User approved the direction “Объёмный фирменный знак” and delegated the creative effect level: “Удиви меня”.
- Implemented a hero-only CSS pass in `site/visual-overhaul.css`: deeper machined frame, layered cyan/violet orbital energy, volumetric tetromino blocks with beveled highlights, visible extrusion/shadow faces and a restrained light sweep. The existing seven-piece cycle and permanent T signature remain.
- Kept the logo inside the existing hero footprint. No dashboard geometry, menu controls, gameplay, game rules, JavaScript, data or navigation were changed.
- Added compact portrait-specific sizing and retained `prefers-reduced-motion` behavior.
- CSS commit: `e9a3f814b89b0f98b380ab7a860a41867cae9e4c`.
- Cache-bust commit in `site/index.html`: `5fe136650c7c479b8616c89e16e71293701aa8fc`; stylesheet query is now `20261101-tetrios-3d-emblem-1`.
- Current main at checkpoint: `5fe136650c7c479b8616c89e16e71293701aa8fc`.
- Matching web deployment run `41278749090`, debug APK run `41278749050`, and signed release run `41278749054` were triggered for this exact main SHA and were still running/pending when checkpoint was written. Earlier source-only runs `41278732691`, `41278732673`, `41278732689` were also still running. Verify the exact-main runs before claiming deployment or offering an APK.
- Physical Android visual review is still pending; do not claim device testing.
- Preserve `backup/main-before-aaa-release-2026-10-31` unchanged at `1a6548446c938d77d737accb202ee368a116943c`.
- Next: verify exact-main deployment and APK workflows, then ask the user to inspect the dimensional emblem on the public site. If the effect feels too busy or too subtle on device, tune only the isolated hero emblem block.
- Resume phrase: **ТЕТРИОС — ПРОДОЛЖЕНИЕ С КОНТРОЛЬНОЙ ТОЧКИ**


## Main menu visual polish — 2026-11-01
- User confirmed the logo work is finished and asked to continue improving the main menu page.
- Implemented a CSS-only visual hierarchy pass in `site/visual-overhaul.css`, commit `dad2b884e2eb134f63faa505b8f3c72ce0f764c7`.
- Refined the top bar contrast/brand typography/settings button; mode cards now have clearer category-specific lighting, stronger tactile depth and improved icon tiles; emphasized the primary run card; polished Heroes, Shop, visit streak, resources, stats, daily quests and APK download panels for a more coherent premium arcade UI.
- Deliberately did NOT change the Tetrios emblem/hero orb, menu geometry, ordering, HTML structure, JS hooks, navigation, gameplay, saves, data or mechanics. No full-screen board or one-screen cropping experiment.
- Kept hover motion subtle and disabled transitions under reduced-motion preference. Existing mobile breakpoints/layout remain authoritative.
- Cache-bust update in `site/index.html`: `0e8d67043c0c530cf09e2db5c07c7189f990231b`; stylesheet query now `20261101-main-menu-polish-1`.
- Current main at checkpoint: `0e8d67043c0c530cf09e2db5c07c7189f990231b`.
- Verify matching web deploy and debug APK workflows for this exact SHA before claiming the polish is live or offering a current APK. Signed release pipeline may still be blocked by the separate signing repository access issue.
- Physical Android visual review is still pending; do not claim device testing.
- Preserve `backup/main-before-aaa-release-2026-10-31` unchanged at `1a6548446c938d77d737accb202ee368a116943c`.
- Next menu passes should be incremental: assess the user-facing mobile hierarchy and readability, then improve secondary-panel details without changing the established layout or emblem.
- Resume phrase: **ТЕТРИОС — ПРОДОЛЖЕНИЕ КОНТРОЛЬНОЙ ТОЧКИ ГЛАВНОГО МЕНЮ**


## Main menu supporting-panel refinement — 2026-11-01
- User resumed from the main-menu checkpoint with the exact phrase: **ТЕТРИОС — ПРОДОЛЖЕНИЕ КОНТРОЛЬНОЙ ТОЧКИ ГЛАВНОГО МЕНЮ**.
- Continued the incremental menu pass without changing the established dashboard geometry or the dimensional Tetrios emblem.
- CSS-only refinement in `site/visual-overhaul.css`, commit `338851a35f8262944cc094a5ef2ec31cfc468306`:
  - Visit-streak panel: clearer purple/gold hierarchy, improved count/message contrast, and a more tactile recovery action.
  - Resources: more legible currency labels and values, distinct coin/gem accents, and refined card depth.
  - Daily quests: consistent dark surfaces, readable progress/reward labels, and a clearer cyan-violet progress fill.
  - Bottom statistics: stronger numeric hierarchy and subtle top-edge highlights.
- Stylesheet cache-bust updated in `site/index.html`, commit `0ca191482c6590644bfb3591d9504304afb380ea`, query token `20261101-main-menu-polish-2`.
- Current main SHA: `0ca191482c6590644bfb3591d9504304afb380ea`.
- No HTML structure, dashboard grid/order/dimensions, emblem, IDs, JavaScript handlers, navigation, game logic, save data, mechanics, or gameplay arena were changed.
- Preserve `backup/main-before-aaa-release-2026-10-31` unchanged at `1a6548446c938d77d737accb202ee368a116943c`.
- Verify the website deployment and Android WebView/debug APK workflows for this exact SHA before claiming it is live or sharing an APK. Physical Android review is still pending; do not claim device testing.
- Next: inspect the refreshed menu on the user's phone and tune only concrete secondary-panel readability/spacing feedback. Keep the emblem and dashboard geometry locked unless the user explicitly requests a change.
- Resume phrase: **ТЕТРИОС — ПРОДОЛЖЕНИЕ КОНТРОЛЬНОЙ ТОЧКИ ГЛАВНОГО МЕНЮ**


## Main menu icon-first button pass — 2026-11-01
- User requested larger buttons, less text, and clearer associative icons so each menu action is recognizable at a glance.
- Implemented in `site/visual-overhaul.css`, commit `770688358ec8743987f78a1aef52de3c5b4db221`:
  - Main mode cards now have larger touch areas, larger icon tiles, clearer titles and stronger arrow affordances.
  - Removed the secondary explanatory copy and category tags from the three primary mode cards to reduce text density; titles remain visible.
  - Heroes and Shop actions also receive larger icon-led hit areas; secondary subtitles are hidden on those entry buttons.
  - Added compact mobile-specific sizing so the buttons remain comfortable without overwhelming the screen.
- Updated primary mode icon associations and shortened the rogue mode title in `site/index.html`, commit `36143c6e447f8ca4b9a8ee8b28d0dd855140da7a`:
  - Campaign: 🗺️
  - Block-run: 🧱 (title shortened from “Весёлый блок-ран” to “Блок-ран”)
  - Daily challenge: 🏆
- Cache-bust token updated to `20261101-icon-first-menu-1`, commit `dce617afa8e263bb966be2307bfbfacae7633b93`.
- No event IDs, data-mode values, click handlers, navigation, gameplay, save data, or menu ordering changed. The emblem and supporting panels remain untouched.
- User has not yet visually reviewed this pass on their phone. Confirm deployment and Android display before claiming it is live or device-tested.
- Next: ask for the user's visual impression; tune icon choice/size or button height only from concrete feedback.
- Resume phrase: **ТЕТРИОС — ПРОДОЛЖЕНИЕ КОНТРОЛЬНОЙ ТОЧКИ ГЛАВНОГО МЕНЮ**


## Block-run Tetris icon correction — 2026-11-01
- User noted that the 🧱 icon read as a Mario/platformer or construction reference rather than Tetris.
- Replaced it with a custom four-cell L-tetromino mark in `site/index.html` and styled it in `site/visual-overhaul.css`.
- HTML commit: `5849728d36c469e3c34f1a77f9909b13a2500913`.
- CSS commit: `26be6ed261c38d6b877ec5cbca8df885322d48a3`.
- Cache-bust token: `20261101-tetromino-icon-1`, commit `04adfd9ffe5c5ef77475abd1deb2ceaf0f96fd66`.
- Only the Block-run icon and its visual styling/cache token changed. Menu layout, labels, data-mode, IDs, handlers, navigation, game logic, and other icons remain unchanged.
- User still needs to visually confirm the refreshed website on the phone; do not claim live deployment or physical-device testing without evidence.
- Resume phrase: **ТЕТРИОС — ПРОДОЛЖЕНИЕ КОНТРОЛЬНОЙ ТОЧКИ ГЛАВНОГО МЕНЮ**


## Main menu tactile feedback pass — 2026-11-01
- User approved the Block-run tetromino icon correction and asked to continue the main-menu refinement.
- Added restrained pressed-state feedback to the three primary menu actions (mode cards, Heroes, Shop) in `site/visual-overhaul.css`:
  - slight downward/scale response while pressed;
  - brighter edge and restrained cyan glow;
  - subtle icon compression to reinforce the tap.
- CSS commit: `bebb68279c90c56385c6865c303c5b985ee0e9cf`.
- Cache-bust token changed to `20261101-menu-tactile-1`, commit `f3096669e0845b3b2f56240c6b0c996cfdf16126`.
- Verification: CSS braces balanced (878/878); all three active-state selectors present; referenced `openHeroes`, `rpgPanel`, and `shop-main-icon` hooks exist; cache token present.
- No layout, button labels, event IDs, data-mode values, handlers, navigation, gameplay, or save data changed.
- Website deployment and physical Android review are not confirmed; user should inspect the refreshed menu on their phone.
- Next: get user's visual feedback on the tactile response before choosing another menu pass.
- Resume phrase: **ТЕТРИОС — ПРОДОЛЖЕНИЕ КОНТРОЛЬНОЙ ТОЧКИ ГЛАВНОГО МЕНЮ**


## Main menu tactile response refinement — 2026-11-01
- User reported that the latest changes were not yet visible on the live site and asked to continue.
- Confirmed repository default branch is `main`; the Pages workflow is configured to trigger on pushes to `main` affecting `site/**`, and also supports manual dispatch.
- The GitHub connector's commit-workflow lookup returned no runs because that endpoint wrapper only includes pull-request-triggered runs; this does not establish that a Pages deployment did not run. No live deployment success is confirmed.
- Continued the source-level polish: added explicit transform/filter transitions to the mode icon and Shop icon so the pressed-state icon response animates smoothly.
- CSS commit: `6de147c757cbda43c23cf72a352d1a0f593b532b`.
- Cache-bust token updated to `20261101-menu-tactile-2`, commit `89e806c959e3f0bc274a7763a954af9edf9d3419`.
- The Pages workflow source is `.github/workflows/deploy-pages.yml`; it downloads a CC0 soundtrack, prepares local Three.js, uploads `site/`, then deploys to Pages.
- No dashboard layout, button labels, IDs, handlers, navigation, game logic, or save data changed.
- Next: inspect the Pages Actions run/deployment for the latest site commit and resolve any failure before claiming the live site is updated. Continue only with small, isolated menu refinements.
- Resume phrase: **ТЕТРИОС — ПРОДОЛЖЕНИЕ КОНТРОЛЬНОЙ ТОЧКИ ГЛАВНОГО МЕНЮ**


## Submenus atmosphere polish — 2026-11-01
- User resumed from checkpoint **TETRIOS.LX / SUBMENUS VISUAL PASS 1** and asked to continue while preserving checkpoint notes and a reusable resume phrase.
- Implemented a second isolated visual pass in `site/visual-overhaul.css`, CSS commit `fc0f82557f7c39f558f803568440407544f2c4a0`:
  - Added restrained layered atmosphere and depth to Campaign, Shop, and Heroes screens.
  - Strengthened submenu headings and added a fine luminous divider for clearer hierarchy.
  - Refined campaign challenge panels, active-node sheen, and visible keyboard/tap focus states.
  - Added tactile pressed states to shop items and hero cards; improved shop-card edge lighting.
  - Kept compact mobile sizing and reduced-motion support.
- Updated the stylesheet cache token in `site/index.html` to `20261101-submenus-atmosphere-2`, commit `c55eb26b388f413ec4c8fedae8db63a06c744ffb`.
- Current main source SHA at this checkpoint: `c55eb26b388f413ec4c8fedae8db63a06c744ffb`.
- CSS brace check passed (1065 opening / 1065 closing braces).
- Changes are CSS-only plus stylesheet cache token. No gameplay mechanics, economy, progress, save data, JavaScript handlers, element IDs, navigation, or content-generation logic were changed.
- Deployment run/status for this exact SHA is not yet verified. Do not claim the changes are live until a matching Pages deployment is confirmed. Physical Android review also remains pending.
- Next: verify the Pages deployment for this exact SHA; then visually review the three submenu screens on Android and refine only concrete readability/spacing issues. Preserve the established mobile-first layout and all game logic/data.
- Resume phrase: **TETRIOS.LX — ПРОВЕРИТЬ DEPLOY ДЛЯ c55eb26. ЗАТЕМ ПРОДОЛЖИТЬ ПОЛИРОВКУ КАРТЫ КАМПАНИИ, МАГАЗИНА И ГЕРОЕВ БЕЗ ИЗМЕНЕНИЯ МЕХАНИКИ И СОХРАНЕНИЙ. 🤘😎**


## Submenu identity pass 3 — 2026-11-01
- Continued the Campaign / Shop / Heroes visual pass with a deliberately more informative approach: distinct visual identities instead of another general atmosphere layer.
- CSS-only implementation in `site/visual-overhaul.css`, commit `e383ef181aacf9ad10ebc4e18b4923472322b643`:
  - Campaign: each of the 11 existing biome cards receives its own restrained color identity; the active biome is more clearly elevated, locked biomes remain visibly subdued, and cleared campaign nodes gain a separate completion treatment. Existing biome order, labels, unlock state, node state and click handlers are untouched.
  - Shop: the six existing catalog cards receive category-specific accent colors tied only to their existing `data-bb-buy` IDs; price, inventory, purchase buttons, currency and reward logic remain unchanged.
  - Heroes: each of the five existing roster cards receives a distinct accent and a clearer character-art stage; the selected/preview/owned state remains driven by the existing app markup and JS.
  - Kept mobile card sizing and reduced-motion behavior.
- Updated stylesheet cache token in `site/index.html` to `20261101-submenus-identity-3`, commit `755562dafd311feae2c8970bf425c8283f1cff8c`.
- CSS brace validation passed: 1119 opening / 1119 closing braces.
- Current main source commit after this pass: `755562dafd311feae2c8970bf425c8283f1cff8c`.
- No HTML structure, JavaScript, IDs, handlers, game mechanics, prices, purchases, inventory, campaign progression, hero selection, localStorage keys, or save data were changed.
- Website deployment for this exact SHA is not yet confirmed. The commit-workflow helper is limited to PR-triggered runs; an empty result from it is not evidence of a failed or missing Pages deployment. Do not claim the changes are live until an exact matching Pages deployment is verified.
- Physical Android review remains pending.
- Next: verify the Pages deployment for `755562dafd311feae2c8970bf425c8283f1cff8c`; then inspect Campaign, Shop and Heroes on a phone and refine only concrete issues.
- Resume phrase: **TETRIOS.LX — ПРОВЕРИТЬ DEPLOY ДЛЯ 755562d. ЗАТЕМ ПРОВЕРИТЬ РАЗЛИЧИМОСТЬ БИОМОВ, КАТЕГОРИЙ МАГАЗИНА И КАРТОЧЕК ГЕРОЕВ. МЕХАНИКУ И СОХРАНЕНИЯ НЕ МЕНЯТЬ. 🤘😎**


## Submenu clarity pass 4 — 2026-11-01
- Confirmed the previous Pages deployment: workflow run `41301074238`, source SHA `755562dafd311feae2c8970bf425c8283f1cff8c`, final conclusion `success`. The deployment log explicitly reports `Reported success!` and resolves the live Pages URL to `https://maikllx.github.io/Tetrios.LX/`.
- Added a focused CSS-only clarity and mobile-usability pass in `site/visual-overhaul.css`, commit `96656ff19057fa3aaf56c4d3ecddd03dc84981e8`:
  - Campaign: stronger hierarchy for the current-biome panel, more readable biome progress bars and labels, clearer node labels, and improved tap/focus affordances.
  - Shop: more consistent product-card layout, larger item icon blocks, readable descriptions, and full-width purchase controls with 42px minimum height. No prices, item IDs, inventory, or purchase handlers changed.
  - Heroes: more consistent roster-card heights, clearer selected/preview labels, improved 3D-stage framing, and more readable stat panels.
  - Added visible keyboard focus treatment and kept reduced-motion support.
  - Tuned compact-screen sizing down to 360px widths.
- Updated stylesheet cache token in `site/index.html` to `20261101-submenus-clarity-4`, commit `ef894c7355e629331d615500d3cc46351a535232`.
- CSS brace validation passed: 1164 opening / 1164 closing braces.
- Current source commit before this checkpoint: `ef894c7355e629331d615500d3cc46351a535232`.
- No JavaScript, HTML structure, game mechanics, prices, inventory, purchases, campaign progression, hero selection, localStorage keys, or save data were changed.
- Deployment for the clarity pass has not yet been confirmed. The successful deployment above is for the previous pass only.
- Physical Android verification remains pending.
- Next: confirm the Pages workflow for `ef894c7355e629331d615500d3cc46351a535232`, then review the published screens on a phone and address only observed issues.
- Resume phrase: **TETRIOS.LX — ПРОВЕРИТЬ DEPLOY ДЛЯ ef894c7. ЗАТЕМ ПРОВЕРИТЬ ЧИТАЕМОСТЬ И УДОБСТВО НА ТЕЛЕФОНЕ: КАРТА КАМПАНИИ, МАГАЗИН, ГЕРОИ. МЕХАНИКУ И СОХРАНЕНИЯ НЕ МЕНЯТЬ. 🤘😎**


## Hero card flip and equipped cosmetic preview — 2026-11-01
- User reported two interaction issues in the Heroes screen: hero details appeared in a separate panel below the roster instead of flipping the selected card in place; equipping a cosmetic did not visibly alter the hero preview.
- Root cause confirmed in the existing `bbRenderHeroes()`: the roster buttons and `#heroDetails` were rendered as separate siblings, and the cosmetic indicator was only applied to the small main-menu avatar. The 3D hero viewer itself remains a separate existing module in `site/visual-3d.js`.
- Reworked `bbRenderHeroes()` in `site/index.html`:
  - The selected hero card now expands across the roster width and flips to reveal the existing 3D stage, portrait, stats, ability and cosmetic controls on its reverse face.
  - Tapping another hero changes the open card; tapping the currently previewed card returns to the selected hero.
  - The existing `#heroDetails` element is moved into the active card rather than duplicated, preserving the existing 3D stage integration and its DOM identity.
  - Equipped cosmetics now have a visible illuminated badge on the 3D showcase stage and a separate accessory marker on the hero portrait. Equipped state is highlighted in the cosmetic picker.
  - Cosmetic equip/unequip still uses the existing `equippedChestCosmetic` key and existing ownership list. Hero confirmation still uses `bbSelectedHero`.
- Added isolated styles in `site/visual-overhaul.css`, CSS commit `243d6f5ddbc59b099bdf6303b5a334155fbe94d3`.
- Updated the stylesheet cache token to `20261101-hero-flip-cosmetics-1` in the HTML commit immediately preceding the CSS commit.
- No changes to hero definitions, cosmetic IDs, item prices, currency, purchases, inventory ownership, campaign progress, gameplay, or save keys were intended.
- Source-level checks: balanced CSS braces; verify current HTML cache token, flip markup, cosmetic indicators, and original save-key references before release.
- Current main SHA at checkpoint: `243d6f5ddbc59b099bdf6303b5a334155fbe94d3`.
- Pages deployment for this source SHA has not yet been confirmed. Do not claim the new card interaction is live until the matching Pages workflow completes successfully. Physical Android review remains pending.
- Next: verify the Pages deployment for this SHA; then inspect hero card flipping and all six cosmetic previews on Android. If the 3D stage badge is obscured by the model, refine its placement without changing the 3D viewer or saved state.
- Resume phrase: **TETRIOS.LX — ПРОВЕРИТЬ DEPLOY ДЛЯ 243d6f5. ПРОТЕСТИРОВАТЬ ПЕРЕВОРОТ КАРТОЧЕК ГЕРОЕВ И ВИДИМОСТЬ ЭКИПИРОВАННЫХ УКРАШЕНИЙ. МЕХАНИКУ, ПОКУПКИ И СОХРАНЕНИЯ НЕ МЕНЯТЬ. 🤘😎**


### Deployment verification update — hero flip/cosmetics pass
- Pages workflow run `41302022757` for source SHA `243d6f5ddbc59b099bdf6303b5a334155fbe94d3` completed with conclusion `success`.
- The `Deploy to GitHub Pages` step is confirmed successful. Live site: `https://maikllx.github.io/Tetrios.LX/`.
- Workflow: https://github.com/MaiklLX/Tetrios.LX/actions/runs/41302022757
- Debug APK workflow `41302022761` for the same site source SHA was still running at the time of this update; do not offer an APK until its artifact is confirmed.
- Signed release APK workflow `41302022729` failed separately. This does not affect the successful website deployment; do not alter signing credentials as part of this UI task.
- The follow-up documentation commit is not a site-source change; the deployed website content matches the verified source SHA above.


## Hero showcase popup and unified hero emblems — 2026-11-01
- User requested replacing the in-place flip interaction with a floating animated popup containing the hero's 3D model, characteristics and abilities; also reported hero icons remained inconsistent in other parts of the game.
- Replaced the Heroes screen flip-card renderer with a shared roster of authored SVG emblems. Tapping a hero now opens a cinematic modal dossier over the current screen, with an animated entrance, dimmed/blurred backdrop, large 3D stage, portrait emblem, role, level, stats, unique ability, XP and cosmetic equipment controls.
- The selected hero can be confirmed from the popup. Cosmetic equip/unequip re-renders the same popup immediately and retains existing `equippedChestCosmetic` storage behavior.
- Unified the authored SVG emblem across the Heroes roster, pre-level selection list, main-menu hero avatar, and hero training/progression modal. Remaining `hero.emoji` reference is only the 3D stage's fallback label metadata, not a UI icon.
- Updated `overlay()` / `closeOverlay()` to remove the showcase-specific modal class when ordinary overlays open/close, avoiding style leakage into other dialogs.
- Source commits: HTML `7769255932ec765e79c571a69f783f299a91c4d8`, menu emblem follow-up `e4784071c742d0f69a3410f77216d0394b4b5eeb`; CSS `b22216bfc427236af791159c83cb4bf812f2c26a`, avatar sizing `5b69dc43144c09cf4912ee95eeaf24403542c01c`.
- Latest site source SHA: `5b69dc43144c09cf4912ee95eeaf24403542c01c`.
- Checks: no old flip renderer remains; canonical emblem references are present in the roster, pre-level chooser, menu avatar and training modal; only 3D fallback metadata still reads `hero.emoji`; CSS braces balanced at 1253/1253.
- Gameplay, hero abilities, item prices, currency, cosmetic ownership, campaign progress and save keys were not changed.
- Pages deployment for the latest source SHA is pending verification. Physical Android review is also pending.
- Next: verify the Pages workflow for `5b69dc4`, then check the popup entrance, 3D model sizing/scrolling and unified emblems on Android.
- Resume phrase: **TETRIOS.LX — ПРОВЕРИТЬ DEPLOY ДЛЯ 5b69dc4. ПРОВЕРИТЬ ВСПЛЫВАЮЩЕЕ ДОСЬЕ ГЕРОЯ С 3D-МОДЕЛЬЮ И ЕДИНЫЕ SVG-ЗНАЧКИ В МЕНЮ, ВЫБОРЕ ПЕРЕД УРОВНЕМ И ПРОФИЛЕ ГЕРОЯ. МЕХАНИКУ И СОХРАНЕНИЯ НЕ МЕНЯТЬ. 🤘😎**


## Checkpoint 271 — 3D universe loader repair and galaxy atlas polish — 2026-11-01
- Resumed from user checkpoint 270. User requested validation of the 12 distinct 3D universe models on the published site and galaxy-map polish while preserving route geometry, campaign progress, purchases and equipped items.
- Audited site/index.html, site/universes-3d.js, site/universes/manifest.json, site/visual-overhaul.css, and .github/workflows/deploy-pages.yml on main.
- Confirmed the manifest contains 12 unique universe model IDs and 12 model entries in the same order used by the galaxy atlas: planet, earth-moon, lava-world, neptune, mars, uranus, saturn, black-hole, mercury, solar-system, spiral-galaxy, sun.
- Found a runtime defect in site/universes-3d.js: visibleSlots was referenced by the IntersectionObserver loader but never declared. This could throw before GLB loading and prevent the 3D models from appearing.
- Fixed the loader by declaring const visibleSlots = new Set() and clearing it during renderer teardown. Commit: fe67cdcb89171acd6c236c1052120dcc345b06fa.
- Updated the module cache-bust URL in site/index.html to 20261101-universe-models-2, ensuring clients request the corrected loader. Commit: 40142b0a8eb26e0dd60e5952937f904848876b4d.
- Applied a restrained atlas-only visual refinement: a 3px visual lift for the current galaxy card and a visible keyboard focus outline. Commit: 20eb144d712194dc36925fc311f6f734c2c1c23c.
- Preservation check: the existing bb-treasure-map-and-arena-geometry style block remains present and untouched; the galaxy/planet ordering, route geometry, click handlers, campaign progress calculations, purchases, inventory and equipped-item state were not changed. No save keys or gameplay logic were edited.
- Source-level verification after the changes: 12 manifest IDs / 12 model entries; loader declares, adds, deletes and clears visible-slot tracking; HTML references the cache-busted module; return-from-planet-map handler still points to renderGalaxyAtlas().
- Deployment and live-device rendering of the repaired models are NOT yet confirmed in this checkpoint. A direct live-site fetch was unavailable from this session; do not claim the new models are already visible until the matching GitHub Pages deployment succeeds and the published site is visually checked.
- Next: verify the Pages Actions deployment for source commit 20eb144d712194dc36925fc311f6f734c2c1c23c; then visually test all 12 models on the published site, including horizontal scrolling, mobile GPU stability, fallback behavior, and back-navigation. Continue polishing galaxy-card presentation without altering the route path or any saved game data.
- Resume phrase: TETRIOS.LX — КОНТРОЛЬНАЯ ТОЧКА 271. ПРОВЕРИТЬ DEPLOY ДЛЯ 20eb144. ПРОТЕСТИРОВАТЬ ВСЕ 12 3D-ВСЕЛЕННЫХ НА ОПУБЛИКОВАННОМ САЙТЕ И ПОЛИРОВАТЬ КАРТУ ГАЛАКТИК. ГЕОМЕТРИЮ МАРШРУТА, ПРОГРЕСС, ПОКУПКИ И ЭКИПИРОВКУ НЕ МЕНЯТЬ. 🤘😎


## Checkpoint 272 — iOS touch handling and mobile 3D loading — 2026-11-01
- User iOS test reported three observations: a downward fast-drop swipe triggers the iPhone screen-shift gesture (Reachability / Удобный доступ); Block Run speed sometimes increases unevenly; the 12 universe models may not be appearing while 3D character models are visible.
- iOS touch fix committed to site/index.html: active board gestures are explicitly tracked; touchmove now uses passive:false and calls preventDefault() for an active board gesture. The existing fast-swipe hardDrop threshold and soft-drop stepping remain unchanged. Commit: f61cf83f6e1a54a5e942bf55ae814aa8ad25e230.
- Important platform limitation: a website cannot disable the iOS system Reachability gesture itself when the swipe starts at the OS bottom-edge activation zone. The browser-level scroll gesture is now suppressed for active board swipes; test on the user's iPhone to confirm whether the system gesture still wins at the physical screen edge.
- 3D model loading optimized for iOS in site/universes-3d.js: iPhone/iPad/touch-Mac is now treated as low-power; antialiasing is disabled and renderer pixel ratio is capped at 1.0 through the existing lowPower path; IntersectionObserver preload margin reduced from 280px to 90px on low-power devices to avoid fetching several GLBs simultaneously. Commit: ea02baaf5caf4cbda442c2e7124abe8b906b5609.
- Updated the module cache token in site/index.html to universes-3d.js?v=20261101-universe-models-3 so iOS Safari requests the optimized loader. Commit: 8f95d29d1e404cfa9e1cfb78e7c09f31cc62e824.
- Source audit of Block Run / rogue speed changes: ordinary monster defeat currently reduces dropMs by 8ms and boss defeat by 24ms, which makes pieces fall faster; each level-up also reduces dropMs by 48ms + 3ms per current level (then applies relic/synergy modifiers). Monster attacks themselves do not change dropMs. Thus the uneven speed increase is explained by two intentional stacked triggers, not a random timer drift. No speed balance was changed pending user preference on whether monster-defeat acceleration should remain.
- The 12 model manifest entries remain intact. Universe-card models are loaded by site/universes-3d.js from remote Grab3D GLB URLs; character 3D rendering is a separate module (site/visual-3d.js). Visible 3D characters therefore do not confirm that the separate universe GLBs loaded. Model loader already preserves emoji fallback and logs fetch/load failures. Live GLB fetch/CORS and visual rendering on iOS are not yet confirmed.
- Preservation: no campaign route geometry, progress, purchases, inventory, equipped items, game save keys, or level/monster speed values were changed. Existing model manifest and galaxy/planet route data were not modified.
- Verification: current main source contains passive:false active touch handling; the hard-drop gesture remains present; iOS model optimization and cache token are present; manifest contains 12 unique universe model IDs. GitHub combined status for the latest source commit returned no status entries, so Pages deployment is not confirmed from this session.
- Next: verify GitHub Pages deployment and re-test on iOS. Check whether Reachability still activates only when the gesture starts at the bottom system edge. Confirm at least the first visible galaxy card's GLB request succeeds; if fallback remains, inspect the remote request/CORS failure. Ask whether the user wants to remove the extra 8ms/24ms speed increase on monster/boss defeat so Block Run accelerates only at level-ups.
- Resume phrase: TETRIOS.LX — КОНТРОЛЬНАЯ ТОЧКА 272. ПРОВЕРИТЬ DEPLOY И ПОВТОРНО ПРОТЕСТИРОВАТЬ iOS: FAST-DROP VS REACHABILITY, 12 GLB-ВСЕЛЕННЫХ И РЕЖИМ BLOCK RUN. СКОРОСТЬ МОНСТРОВ ПОКА НЕ МЕНЯТЬ; МАРШРУТ, ПРОГРЕСС, ПОКУПКИ И ЭКИПИРОВКУ СОХРАНИТЬ. 🤘😎


## Checkpoint 273 — Smooth Block Run acceleration — 2026-11-01
- User chose to retain both acceleration sources in Block Run: ordinary monster/boss defeats and level-ups, while making speed transitions smoother.
- Preserved the existing target-speed calculations unchanged:
  - ordinary monster defeat: reduce target drop interval by 8ms;
  - boss defeat: reduce target drop interval by 24ms;
  - level-up: retain the existing reduction of 48ms + 3ms per current level, including existing relic/synergy modifiers and minimum speed cap.
- Updated only the Block Run (rogue mode) drop scheduler in `site/index.html`: it now eases the actual falling interval toward the target over approximately 1.1 seconds using a smoothstep curve. The scheduler checks at 50ms intervals but moves a piece only when the currently eased interval has elapsed, preventing a large interval jump on the first tick.
- Other modes retain their original `setInterval` drop scheduler; daily-mode gravity modifiers and their timing were not intentionally changed.
- New-run reset initializes the eased interval to the original 760ms baseline.
- Source commits: initial implementation `e11e257d152f62a1421ac45a802e85ed744ec817`; refined easing implementation `98271c733ee40397d7e84ecc08e9b7ec1e0b625e`.
- Verification: latest source still contains both original monster/boss and level-up target-speed calculations; rogue scheduler uses smoothstep easing and a 50ms check; non-rogue modes retain their interval scheduler; new-run baseline reset remains present.
- No monster attack logic, damage, abilities, relic values, level thresholds, scoring, campaign route geometry, purchases, inventory, equipped items, progress, save keys or saved game data were changed.
- Pages deployment for `98271c7` is not yet confirmed. Test the published Block Run on mobile: defeat a regular monster, defeat a boss, and trigger a level-up separately; verify that the falling speed ramps smoothly and remains responsive. Confirm that pause/resume does not cause an immediate extra drop.
- Next: verify the Pages deployment for `98271c7`, then perform the three gameplay checks above and adjust only the easing duration if the transition feels too slow or too fast.
- Resume phrase: **TETRIOS.LX — КОНТРОЛЬНАЯ ТОЧКА 273. ПРОВЕРИТЬ DEPLOY ДЛЯ 98271c7 И ПРОТЕСТИРОВАТЬ ПЛАВНОЕ УСКОРЕНИЕ BLOCK RUN ПОСЛЕ МОНСТРА, БОССА И ПОВЫШЕНИЯ УРОВНЯ. ОБА ИСТОЧНИКА УСКОРЕНИЯ СОХРАНЕНЫ; МЕХАНИКУ, МАРШРУТ, ПРОГРЕСС, ПОКУПКИ И СОХРАНЕНИЯ НЕ МЕНЯТЬ. 🤘😎**


## Checkpoint 274 — Full pre-game hero dossier and reversible selection — 2026-11-01
- User reported that on iOS the pre-level hero picker in multiple game modes does not clearly show which hero is selected, and requested a full hero card similar to the Heroes page plus a reliable way to return to the hero list before starting.
- Reworked only `bbChooseHeroBeforeStart()` in `site/index.html`.
- Pre-game flow is now two-step:
  1. A roster screen clearly marks the currently chosen hero, shows the hero emblem, role and level, and opens each hero's full dossier.
  2. The dossier shows the existing 3D hero stage, equipped cosmetic marker when present, hero description, durability/mastery ratings, unique ability, level and XP.
- The dossier has two explicit back controls ("Назад к выбору героев") returning to the roster. Choosing a hero in the dossier updates only the temporary pre-run selection and returns to the roster; the user can inspect another hero or cancel without committing the change.
- The selected hero is persisted to `bbSelectedHero` and applied only after the final "Начать игру" confirmation. Existing daily replay payment handling remains at final confirmation, and cancel still returns to the correct campaign/daily/menu context without charging for an unconfirmed replay.
- All modes continue to use the existing `startGame() -> bbChooseHeroBeforeStart()` entry point. No hero stats, abilities, progression, cosmetics, gameplay mechanics, campaign route geometry, purchases, inventory, equipped items or save keys were changed.
- Source commit: `0af280f0b16cfc821c2f0a55812e683fe6bced79`.
- Verification against the committed source: roster and dossier render functions are present; both back controls route to the roster; dossier selection updates the temporary `chosenHero` and returns to roster; persistent hero selection occurs only in the final start handler; campaign/daily cancellation branches remain present; all modes still enter through the same pre-game selector.
- iOS visual interaction and GitHub Pages deployment are not yet confirmed. Test in the published site on iPhone: open pre-level selection in campaign, daily and Block Run; open each hero dossier; return to roster; choose a different hero; verify the selected badge and final in-game hero; cancel and verify the correct previous screen is restored.
- Next: confirm Pages deployment and test the complete roster → dossier → back → confirm flow on iOS, including long dossier scrolling and the 3D stage.
- Resume phrase: **TETRIOS.LX — КОНТРОЛЬНАЯ ТОЧКА 274. ПРОВЕРИТЬ DEPLOY И ПРОТЕСТИРОВАТЬ НОВЫЙ ДВУХШАГОВЫЙ ВЫБОР ГЕРОЯ НА iOS: СПИСОК → ПОЛНОЕ ДОСЬЕ → НАЗАД К СПИСКУ → ПОДТВЕРЖДЕНИЕ. ПРОВЕРИТЬ CAMPAIGN, DAILY И BLOCK RUN. ПРОГРЕСС, ХАРАКТЕРИСТИКИ, ПОКУПКИ И СОХРАНЕНИЯ НЕ МЕНЯТЬ. 🤘😎**


## Checkpoint 275 — Planet completion flow, 2D-first board and planet 3D models — 2026-11-01
- User requested a campaign completion presentation as a short informational banner, automatic return to the planet map after 3–5 seconds or immediate dismissal by tapping anywhere, a flash/pulse on the newly unlocked planet, consistent "planet" terminology, 2D as the default game board with optional 3D, and visible 3D planet/universe models.
- Campaign completion in `site/index.html` now:
  - preserves the existing campaign reward calculations, star-mark awards, hero XP awards, unlocked-planet calculation and `nrNode` progression;
  - replaces the old completion dialog and its two navigation buttons with a compact completion banner showing the completed planet and earned rewards;
  - returns to the campaign planet map after 4.2 seconds, or immediately on a tap/click anywhere on the overlay;
  - selects the biome containing the newly unlocked planet and marks that planet for a one-time arrival highlight.
- The newly unlocked planet receives an arrival animation: bright pulse, glow and orbit highlight, with the map scrolling to center it. The animation respects reduced-motion preferences.
- Campaign-facing UI wording was changed from "node" to "planet", including completion banner and campaign upgrade descriptions. No route IDs, route order, biome boundaries or saved progression keys were changed.
- `site/arena-3d.js` now defaults to 2D. The 3D renderer and Three.js module are loaded only after the player presses the 3D toggle; switching away from the game screen returns to 2D and stops the 3D render loop. This removes the previous automatic 3D activation whenever the game screen became visible.
- The universe renderer now targets both the galaxy atlas and the planet-route viewport. Planet spheres receive distinct model IDs from the existing 12-model manifest. The WebGL canvas remains a separate overlay and is positioned over the active map viewport.
- Added a procedural 3D fallback for each universe model if its remote Grab3D GLB request fails, so a failed external asset request should no longer leave only a flat emoji. The original remote GLB remains the preferred model source.
- Cache-busting updated for `arena-3d.js?v=20261101-opt-in-2d` and `universes-3d.js?v=20261101-planet-models-2`.
- Source commits:
  - campaign arrival banner and 2D-first arena: `a84de7b5d939c62fe5b82fff058328e341402db9`
  - optional/lazy 3D arena: `eec607086c8b0098302c99e3cdcf9bd9a52391e9`
  - universe viewport anchoring: `a4f1ebc8c2fe6d63f3993c64a1c14f279adc5d43`
  - 3D planet nodes: `10d3433cb4ad7280512c226f11d34fce3d9db389`
  - local procedural 3D fallback: `93f3dfbede303a44163c9bb8330bbbcc80c945a1`
  - campaign terminology/cache-bust: `0304af3c257a57fcf40c5beacf198ca086dfe92c`
- Verification against committed source: completion banner has no navigation buttons; timer is 4.2 seconds; overlay click listener skips the wait; reward/progression writes remain; planet arrival class is applied; no remaining campaign "узел" wording; 3D arena no longer auto-enables and uses lazy import; planet map includes model slots; universe loader scans both atlas and planet map; procedural fallback is present.
- GitHub Actions for the latest commit `0304af3` were still running/pending at checkpoint time; published Pages rendering and actual iOS/WebGL visual appearance are not yet confirmed. The Grab3D GLB endpoints remain remote; if a GLB fails, the new local procedural 3D representation should be used instead.
- No campaign route geometry, biome/planet numbering, progress records, purchases, coins, inventory, equipped items, hero statistics, game rules or save keys were intentionally changed.
- Next: verify the latest Pages deployment, then test on iOS: finish a campaign planet, let the banner auto-dismiss and separately tap to dismiss it; confirm the next planet is centered and flashes; confirm board opens in 2D and the 3D toggle loads only when requested; inspect both galaxy atlas and planet route for 3D models.
- Resume phrase: **TETRIOS.LX — КОНТРОЛЬНАЯ ТОЧКА 275. ПРОВЕРИТЬ DEPLOY И НА iOS: БАННЕР ЗАВЕРШЕНИЯ ПЛАНЕТЫ (4,2 СЕКУНДЫ / TAP ANYWHERE), ПЕРЕХОД И ВСПЫШКУ НОВОЙ ПЛАНЕТЫ, 2D ПО УМОЛЧАНИЮ И РУЧНОЙ 3D, МОДЕЛИ НА КАРТЕ ГАЛАКТИК И ПЛАНЕТ. МАРШРУТ, ПРОГРЕСС, ПОКУПКИ И СОХРАНЕНИЯ НЕ МЕНЯТЬ. 🤘😎**


### Checkpoint 275 addendum — validation and deployment
- Fixed literal escaped-newline formatting in the campaign map/arrival markup; the main inline gameplay script now passes a JavaScript syntax parse. Commit: `4b369eddc463c02aa2cc625bce48646ac467784a`.
- Updated `site/validate-3d-runtime.mjs` so the runtime audit accepts cache-busted local module URLs while still requiring the import map to appear before the modules. Commit: `5e3ac4aef378c36554d635e38914137a37fc3ef3`.
- Syntax checks passed for the main inline script, `arena-3d.js`, `universes-3d.js`, and the validator module.
- GitHub Pages deployment for `4b369ed` completed successfully: https://github.com/MaiklLX/Tetrios.LX/actions/runs/41324231776.
- Actual device-side iOS rendering remains to be tested; deployment success does not by itself prove that remote GLBs or the procedural 3D fallback render correctly on every device.


## Checkpoint 276 — Immediate 3D planet rendering, stable canvas anchoring and page-top refresh — 2026-11-01
- User reported that 3D planet/universe models appeared late over the old animated 2D icons, shifted slightly while scrolling, and that a page refresh should always start at the top.
- Updated `site/universes-3d.js` so each visible slot receives a local procedural 3D model immediately when activated. The remote Grab3D GLB is now an asynchronous visual upgrade; if it fails, the already-visible procedural 3D model remains. This removes the wait-for-network gap and avoids showing the 2D icon beneath the 3D model.
- Moved the shared WebGL canvas from the outer map grid into the active map viewport itself. The canvas is now positioned at the viewport's own top-left origin, and renderer sizing no longer derives offsets from two independently scrolling DOM rectangles. This is intended to keep 3D models anchored to their corresponding planet/universe slots during page and map scrolling.
- Added loaded-state styling in `site/index.html` to hide the old fallback glyph and remove the 2D sphere background, ring and float animation once a 3D model is present.
- Added manual browser scroll restoration and top-of-page resets on `pageshow` and `load`, including a post-frame reset for mobile browser restoration timing.
- Updated the universe module cache token to `20261101-instant-stable-3d-3`.
- Preservation: no campaign route coordinates, planet ordering, galaxy order, gameplay logic, progression, purchases, inventory, equipment, save keys or stored data were changed.
- Verification required before claiming completion: syntax-check both edited files, inspect the exact diff, run the repository's 3D runtime validator, and verify the GitHub Pages deployment. Then test on iOS/Android that 3D appears immediately, the 2D glyph is gone, models remain fixed while scrolling horizontally/vertically, and refresh starts at the top.
- Resume phrase: **TETRIOS.LX — КОНТРОЛЬНАЯ ТОЧКА 276. ПРОВЕРИТЬ МГНОВЕННУЮ ПРОЦЕДУРНУЮ 3D-ЗАГРУЗКУ С ПОСЛЕДУЮЩИМ GLB-UPGRADE, ОТСУТСТВИЕ СТАРЫХ 2D-ИКОНOК, ФИКСАЦИЮ МОДЕЛЕЙ ПРИ ПРОКРУТКЕ И СТАРТ СВЕРХУ ПОСЛЕ ОБНОВЛЕНИЯ. МАРШРУТ, ПРОГРЕСС, ПОКУПКИ И СОХРАНЕНИЯ НЕ МЕНЯТЬ. 🤘😎**

- Implementation refinement after source review: the WebGL canvas is a fixed overlay attached to `document.body`, and its screen position is refreshed from the active viewport's live bounding rectangle on every render frame. Currently visible slots are activated synchronously before the first IntersectionObserver callback. This avoids making the overlay a child of the horizontally scrolling viewport and reduces first-visible-frame delay.

- Canvas CSS was made global (not campaign-descendant-scoped) because the fixed WebGL canvas is deliberately attached to `document.body`; this ensures the fixed positioning, stacking order and pointer-event behavior apply to the actual canvas element.


## Checkpoint 276 addendum — restore WebGL canvas visibility — 2026-11-01
- User reported that after the previous CSS change both the 2D fallback artwork and the 3D universe/planet models disappeared. Root cause identified: the renderer canvas is a direct child of `document.body`, so its visibility and stacking must be controlled as a body-level fixed overlay, not with campaign-descendant selectors.
- Corrected `site/universes-3d.js`: canvas now receives explicit inline fixed positioning, live viewport coordinates, dimensions, high stacking order and pointer-events:none. This keeps it above the campaign artwork while not intercepting taps.
- Corrected `site/index.html`: the canvas CSS now targets `body > canvas.bb-galaxy-model-canvas` and enforces the fixed overlay layer. No fallback artwork or model geometry was removed.
- New fix commits: `9787ca308f9d34c75d53ea366c46ca676cbf600c` (JS), `528ae6cc70eb06e8b703b67d8e4a030f0ebc6a72` (HTML).
- Deployment and real-device rendering must be checked before declaring restored; preserve the immediate procedural 3D path, background GLB upgrade, 2D fallback suppression only while 3D is active, route, progression, purchases and saves.


## Checkpoint 276 addendum — visible map selection and slot refresh — 2026-11-01
- Audited the shared renderer and found that `scan()` selected the first matching galaxy/planet viewport without checking whether it was currently visible. It also restarted only when the viewport element changed, not when the campaign reused the same viewport element but replaced its model slots.
- Updated `site/universes-3d.js` to select a visible viewport that actually contains model slots, reject hidden/zero-size candidates, and detect slot replacement even when the viewport DOM node is reused. This prevents the renderer from remaining attached to stale or hidden map content after switching between universe and planet maps.
- Kept the existing 12-model manifest, immediate procedural 3D fallback, asynchronous GLB upgrade, and body-level fixed transparent canvas. No route data, map coordinates, progression, purchases, inventory, equipment, save keys or stored data were changed.
- Updated the module cache token in `site/index.html` to `20261101-instant-stable-3d-4`.
- Source commits: `303ac5773bf8948a8cd42d6521024a640e629118` (viewport selection/slot refresh); `f69ab9f354e887463aefedc3714c79158e0634d8` (cache refresh).
- Remaining verification: run the repository 3D runtime validator and confirm Pages deployment, then test both maps on-device. Specifically verify immediate procedural 3D display before GLB completion, removal of the 2D fallback only while its 3D model is active, correct model-to-slot alignment during horizontal and vertical scrolling, and top-of-page refresh behavior. Device-side WebGL rendering is not claimed verified by source inspection alone.
- Resume phrase: **TETRIOS.LX — КОНТРОЛЬНАЯ ТОЧКА 277. ПРОВЕРИТЬ DEPLOY И НА УСТРОЙСТВЕ ОБЕ КАРТЫ: ВСЕ 3D-МОДЕЛИ ПЛАНЕТ И ВСЕЛЕННЫХ, МГНОВЕННОЕ ПОЯВЛЕНИЕ, ОТСУТСТВИЕ ДУБЛЕЙ 2D, ФИКСАЦИЯ ПРИ ПРОКРУТКЕ И СТАРТ СВЕРХУ ПОСЛЕ ОБНОВЛЕНИЯ. МАРШРУТ, ПРОГРЕСС, ПОКУПКИ И СОХРАНЕНИЯ НЕ МЕНЯТЬ. 🤘😎**


## Checkpoint 277 — 3D model alignment while scrolling — 2026-11-01
- User confirmed the 3D models are restored, but during horizontal map scrolling they drifted and overlapped adjacent universe/planet items.
- Root cause found in `site/universes-3d.js`: the draw loop clamped a partially offscreen model's origin to the viewport edge, then used the model's full width/height for both viewport and scissor. This changed the effective framing of a partially clipped model and could draw it across a neighbouring slot.
- Fixed the draw loop: each model now keeps its full viewport anchored to its actual DOM slot coordinates (including negative/offscreen coordinates); a separate scissor rectangle clips only the visible intersection with the map viewport. Camera aspect ratio remains based on the full slot, not the clipped fragment.
- Both galaxy and planet maps use this shared renderer, so the correction applies to both without changing node positions, route geometry, progression, purchases, inventory, save keys or stored data.
- Updated cache token in `site/index.html` to `universes-3d.js?v=20261101-scroll-clip-fix-1`.
- Source commits: `27df73fec5f7ab952ab6831e13f332d503dc2fff` (slot-anchored viewport + independent scissor clipping); `22529d8c1d65208a5857886b9e17f993fa994c8d` (cache refresh).
- Static source verification still required after deployment; actual touch-scroll validation on device remains required. Check the left and right edges while swiping slowly and quickly, including partially visible first/last models, and confirm each 3D model remains centred in its own card/node without crossing into neighbours.
- Resume phrase: **TETRIOS.LX — КОНТРОЛЬНАЯ ТОЧКА 278. ПРОВЕРИТЬ НА ОПУБЛИКОВАННОМ САЙТЕ И НА ТЕЛЕФОНЕ ФИКСАЦИЮ 3D-МОДЕЛЕЙ ПРИ ГОРИЗОНТАЛЬНОЙ ПРОКРУТКЕ КАРТЫ ВСЕЛЕННЫХ И КАРТЫ ПЛАНЕТ: КАЖДАЯ МОДЕЛЬ СТРОГО В СВОЁМ СЛОТЕ, БЕЗ СМЕЩЕНИЯ, РАСТЯГИВАНИЯ И НАЛОЖЕНИЯ НА СОСЕДЕЙ. СОХРАНИТЬ МГНОВЕННУЮ ЗАГРУЗКУ, 2D-ДУБЛИ НЕ ВОЗВРАЩАТЬ, МАРШРУТ И СОХРАНЕНИЯ НЕ МЕНЯТЬ. 🤘😎**


## Checkpoint 278 — smoother atlas scrolling and immersive universe cards — 2026-11-01
- User requested smoother horizontal movement on both the universe and planet maps, while keeping every 3D model anchored to its own slot; also requested removal of the visible universe-card frame and leftover 2D-era animated decorations.
- Updated the final atlas presentation layer in `site/index.html`: changed horizontal scroll snapping from mandatory to proximity so touch momentum is not repeatedly interrupted at every card; retained native iOS momentum scrolling and enabled smooth programmatic scrolling. The same scroll behavior applies to both galaxy and planet viewports.
- Removed the old 2D galaxy orbit rings, blinking star glyphs, floating fallback animation and decorative card border/glow frame. Kept the card content, selection behavior, universe labels, progress/status information, and all 3D model slots. The current-universe card now has only a restrained atmospheric tint rather than a raised bordered panel.
- Preserved the shared 3D renderer and the slot-anchored viewport/scissor clipping correction from checkpoint 277. No 3D models, model manifest, map ordering, route geometry, progression, purchases, inventory, equipment, save keys or stored data were changed.
- Source commit: `e05d59747a8a28c62bc1c2d63ca57449ae00936a` (`Polish atlas scrolling and remove legacy galaxy decorations`).
- Validation boundary: CSS/source update committed to `main`; actual touch feel, model alignment during fast/slow swipes, and final appearance still require checking on the published site/device. Do not claim device-side verification until the user confirms.
- Resume phrase: **TETRIOS.LX — КОНТРОЛЬНАЯ ТОЧКА 279. ПРОВЕРИТЬ ПЛАВНОСТЬ ГОРИЗОНТАЛЬНОЙ ПРОКРУТКИ КАРТЫ ВСЕЛЕННЫХ И ПЛАНЕТ ПОСЛЕ ПЕРЕХОДА НА МЯГКУЮ SNAP-ПРОКРУТКУ. УБЕДИТЬСЯ, ЧТО 3D-МОДЕЛИ ОСТАЮТСЯ СТРОГО В СВОИХ СЛОТАХ, А СТАРЫЕ 2D-ОРБИТЫ, МЕРЦАНИЕ И РАМКИ НЕ ВОЗВРАЩАЮТСЯ. СОХРАНИТЬ МАРШРУТ И СОХРАНЕНИЯ. 🤘😎**


## Checkpoint 279 — clear universe and planet progression states — 2026-11-01
- User requested an at-a-glance visual distinction between available, locked, and completed universes/planets.
- Added a compact status legend to both the universe atlas introduction and each planet-system heading.
- Universe cards now show a small status chip: turquoise "ДОСТУПНО" for the current accessible universe, warm gold "ПРОЙДЕНО" for completed universes, and muted slate "ЗАКРЫТО" for future universes.
- Planet nodes now show a small corner marker: turquoise chevron for the currently available planet, gold check for completed planets, and a muted lock marker for unavailable planets. Their existing textual labels are retained and recolored to match the same status language.
- Statuses are derived only from existing progression classes and variables (`is-current`, `is-cleared`, `is-locked`, `current`, and existing biome ranges). No new progression state or storage keys were introduced.
- 3D models remain visible and unobstructed; markers are compact and placed at the edge of the visual object. No changes to model loading, model positions, route geometry, gameplay, rewards, progression logic, purchases, inventory, equipment, or save data.
- Source commits: `7913a821fdd307d5643ef04053bdb1e677fc3eea` (universe status chips and shared visual language), `9a17b43d2fa53c5cdeb3986c321c9e6b7448f8aa` (planet legend and lock marker).
- Validation boundary: source changes are committed to `main`; actual mobile layout/readability and published-site appearance still require device-side confirmation.
- Resume phrase: **TETRIOS.LX — КОНТРОЛЬНАЯ ТОЧКА 280. ПРОВЕРИТЬ ОБОЗНАЧЕНИЯ СТАТУСОВ НА КАРТЕ ВСЕЛЕННЫХ И КАРТЕ ПЛАНЕТ: БИРЮЗОВЫЙ — ДОСТУПНО, ЗОЛОТОЙ — ПРОЙДЕНО, СЕРЫЙ ЗАМОК — ЗАКРЫТО. УБЕДИТЬСЯ, ЧТО МЕТКИ НЕ ПЕРЕКРЫВАЮТ 3D-МОДЕЛИ И ХОРОШО ЧИТАЮТСЯ НА ТЕЛЕФОНЕ. СОХРАНИТЬ ПРОГРЕСС И МАРШРУТ. 🤘😎**


## Checkpoint 280 — larger foreground completion marks on planet map — 2026-11-01
- User asked to make the gold completed-planet checkmark larger and visibly in front of the 3D planet object.
- Updated only the planet-map presentation layer in `site/index.html`: completed nodes now show a 36px gold check badge with a brighter rim, glow, and dark translucent backing, positioned over the lower-right edge of the planet so it reads as a foreground completion marker.
- Adjusted the 3D canvas stacking and planet viewport/node stacking so the completion badge renders above the 3D model rather than being obscured by it. Universe-map presentation is not changed by the new viewport stacking rule.
- Existing `is-cleared` status class remains the sole trigger. No progression rules, map positions, model selection/loading, route geometry, rewards, purchases, inventory, equipment, save keys or stored data were changed.
- Source commit: `6d8b1cb903dca9dc34bc4a1409296e85152ce32a` (`Make completed planet checkmarks larger and foregrounded`).
- Validation boundary: source update committed to `main`; confirm the visual layering and badge placement on the published site, especially on a narrow phone screen. No device-side verification is claimed.
- Resume phrase: **TETRIOS.LX — КОНТРОЛЬНАЯ ТОЧКА 281. ПРОВЕРИТЬ НА КАРТЕ ПЛАНЕТ УВЕЛИЧЕННУЮ ЗОЛОТУЮ ГАЛОЧКУ ПРОЙДЕННОЙ ПЛАНЕТЫ: ОНА ДОЛЖНА БЫТЬ НА ПЕРЕДНЕМ ПЛАНЕ У ПРАВОГО НИЖНЕГО КРАЯ 3D-МОДЕЛИ, ХОРОШО ЧИТАТЬСЯ И НЕ МЕШАТЬ НАЗВАНИЮ И СОСЕДНИМ ПЛАНЕТАМ. ПРОВЕРИТЬ, ЧТО 3D-МОДЕЛИ ОСТАЛИСЬ ВИДИМЫМИ, А МАРШРУТ И СОХРАНЕНИЯ НЕ ИЗМЕНИЛИСЬ. 🤘😎**


## Checkpoint 281 — completion checkmark in front of 3D planet — 2026-11-01
- Clarified placement after user feedback: the completed-planet checkmark must read as a foreground element in front of the 3D model, not sit low/behind the sphere.
- Adjusted the existing badge to a 38px gold marker at the upper-right/front edge of the planet, with a higher stacking level and glow. The badge remains a DOM element; the 3D model remains visible behind it.
- Only the planet completion badge styling changed. No route/progression logic, model data, saves, rewards, purchases, inventory, equipment or storage keys changed.
- Source commit: `33acede3e867881e8348ecffc872ebb02e13236d` (`Bring completed planet checkmark into foreground of 3D model`).
- Validate on the published phone view that the checkmark is visibly in front of the 3D planet and does not hide its recognizable shape.
- Resume phrase: **TETRIOS.LX — КОНТРОЛЬНАЯ ТОЧКА 282. ПРОВЕРИТЬ, ЧТО ЗОЛОТАЯ ГАЛОЧКА ПРОЙДЕННОЙ ПЛАНЕТЫ ОТОБРАЖАЕТСЯ ПОВЕРХ 3D-МОДЕЛИ, НА ПЕРЕДНЕМ ПЛАНЕ, А НЕ ЗА НЕЙ; ОНА КРУПНАЯ, ЧИТАЕМАЯ И НЕ ЗАКРЫВАЕТ СУЩЕСТВЕННУЮ ЧАСТЬ ПЛАНЕТЫ. ПРОВЕРИТЬ НА ТЕЛЕФОНЕ. МАРШРУТ И СОХРАНЕНИЯ НЕ ТРОГАТЬ. 🤘😎**

## Checkpoint 282 — отметка пройденной планеты рядом с номером (2026-11-01)

- Убрана попытка размещать крупную галочку поверх 3D-модели планеты.
- Для пройденной планеты галочка теперь отображается компактно справа от её номера.
- Старый круглый значок над моделью скрыт только для статуса `is-cleared`; отметки доступной и закрытой планет сохранены.
- Изменены только стили отображения; логика прогресса, маршрут, сохранения и награды не затронуты.
- Source commit: `4e5e8f1f8be692eff74f148c111714e69ca0d924`.
- Публикацию и внешний вид на телефоне необходимо проверить после GitHub Actions.

## Checkpoint 283 — запуск игры после подтверждения героя и закреплённая навигация (2026-11-01)

- В выборе героя подтверждение кнопкой «ВЫБРАТЬ ЭТОГО ГЕРОЯ» в карточке персонажа теперь сразу фиксирует выбранного героя и запускает текущий режим через общий стартовый обработчик.
- Кнопка «НАЧАТЬ ИГРУ ЗА …» в списке героев сохранена как отдельный быстрый путь запуска.
- Учтена существующая оплата повторного ежедневного испытания: списание проверяется до старта и не выполняется при недостатке монет.
- Кнопка отмены вынесена в правый верхний угол списка героев; кнопка возврата в досье героя также находится сверху справа.
- Обе кнопки закреплены в прокручиваемом окне выбора, нижняя дублирующая кнопка возврата удалена.
- Изменены только поток выбора героя и навигация окна; игровой баланс, прогресс, сохранения, режимы и награды не менялись.
- Source commits: `a8c0ee5cf9a7d4107972dc8db61ce975c21aeed9`, `ecc714e54cfeb88ce00e807a6632be009f09586e`.
- Публикацию и поведение на телефоне проверить после завершения GitHub Actions.

## Checkpoint 284 — единое космическое пространство карты вселенных (2026-11-01)

- Карта вселенных кампании визуально переведена из набора отдельных карточек в единый горизонтальный космический атлас.
- Убраны самостоятельные фоны, рамки и тени карточек; 3D-модели остаются отдельными выразительными точками на общем фоне.
- Добавлена тонкая световая линия маршрута за моделями, компактная типографика, аккуратные индикаторы статуса и прогресса.
- Сохранены горизонтальная прокрутка, snap-навигация, кнопки перехода, статусы доступности и блок неизведанного сектора.
- 3D-модели, их загрузчик и fallback не изменялись; выбор вселенной и переход к карте планет не менялись.
- Изменён только CSS визуального слоя карты вселенных.
- Source commit: `baeffc0e9fb533225841071ebf2fc3f4d4e890b4`.
- Публикацию и внешний вид на телефоне проверить после GitHub Actions.

## Checkpoint 285 — статусы рядом с названиями вселенных и номерами планет (2026-11-01)

- Все три статуса планет перенесены к числовому идентификатору: бирюзовый маркер текущей/доступной планеты, золотая галочка пройденной, серый знак закрытой.
- У вселенных индикаторы «ДОСТУПНО», «ПРОЙДЕНО» и «ЗАКРЫТО» перенесены с верхнего правого угла к подписи UNIVERSE NN.
- Плавающие бейджи поверх 3D-объектов скрыты; цветовая система и смысл статусов сохранены.
- Изменён только CSS презентации карты кампании; вычисление доступности, прогресс, переходы и 3D-модели не менялись.
- Source commit: `7df066d8cf0d7d3ff965b766cff5da0d445e094d`.
- Публикацию и визуальное отображение на телефоне проверить после GitHub Actions.


## Checkpoint 286 — отдельная атмосферная среда для карты вселенных и карты планет (2026-11-01)

- Добавлены две разные, но визуально родственные фоновые среды только для кампании.
- Карта вселенных получила глубокий графитово-синий космос с мягкими туманностями, редкими звёздами и подчёркнутой глубиной пространства; существующая линия маршрута сохранена.
- Карта планет получила более близкую и спокойную атмосферу: холодное межпланетное свечение, лёгкие звёздные точки и затемнение по краям, чтобы 3D-планеты оставались главным акцентом.
- Декоративные слои реализованы CSS-градиентами и псевдоэлементами без внешних видео/изображений, сетевых запросов и новых тяжёлых ресурсов.
- Все фоновые слои находятся за DOM-картой, имеют `pointer-events:none`; дорожка планет, SVG-маршрут и 3D-модели остаются поверх фона. Навигация, порядок миров, статусы и прогресс не менялись.
- Добавлена очень медленная смена интенсивности атмосферного свечения; при `prefers-reduced-motion` анимация отключается.
- Изменён только презентационный CSS в `site/index.html`; игровой процесс, прогресс, покупки, инвентарь, сохранения, загрузчик и модели 3D не затронуты.
- Source commit: `d27f6441babe13d709d048f477389c08a3a56ff1`.
- Проверены наличие обеих независимых атмосфер, отключение перехвата касаний и поддержка reduced-motion. Публикацию и внешний вид на телефоне проверить после GitHub Actions; визуальная проверка на физическом устройстве не заявляется.
- Resume phrase: **TETRIOS.LX — КОНТРОЛЬНАЯ ТОЧКА 287. ПРОВЕРИТЬ НА ОПУБЛИКОВАННОМ САЙТЕ ДВА ФОНА: КАРТА ВСЕЛЕННЫХ — ГЛУБОКИЙ КОСМОС С ТУМАННОСТЯМИ; КАРТА ПЛАНЕТ — БЛИЖНЕЕ МЕЖПЛАНЕТНОЕ ПРОСТРАНСТВО. УБЕДИТЬСЯ, ЧТО 3D-МОДЕЛИ ОСТАЮТСЯ ГЛАВНЫМИ, ПРОКРУТКА И КАСАНИЯ РАБОТАЮТ, НА МОБИЛЬНОМ НЕТ ЛИШНЕЙ ТЯЖЕСТИ. ПРОГРЕСС И НАВИГАЦИЮ НЕ ТРОГАТЬ. 🤘😎**

## Checkpoint 288 — definitive campaign map atmosphere replacement
- User reported that the new universe/planet map backgrounds were not visible after successful web deployment.
- Inspected the current source CSS cascade and `site/universes-3d.js`. The shared WebGL canvas uses `alpha:true` and clears with alpha 0, so it should not paint an opaque layer over the map backgrounds.
- Found legacy galaxy viewport background layers still declared in the shared-cosmos style block. Although the final atmosphere block was later in source order, the new atmosphere was too subdued to create an obvious visual change on mobile.
- Removed the legacy galaxy viewport background fill from the shared-cosmos block and replaced the final atmosphere block with explicit `background` shorthands for both viewports. The galaxy map now has stronger blue/violet/teal nebula layers and star fields; the planet map has a distinct teal/blue close-space atmosphere with violet edge glow and stars.
- Kept decorative pseudo-elements behind map content with `pointer-events:none`; 3D canvas/rendering, models, navigation, scrolling, game progress, saves, purchases and inventory logic unchanged.
- Static source verification only. Wait for the web deployment to succeed and user to verify on the published site/mobile device.
- Source commit: `91d45ed7ded5b478e04d7da027a3a2087fe6bf8e`.
## Checkpoint 289 — correct 3D canvas layer within campaign map
- User reported that the newly published atmospheres were visible but still appeared partially covered by another layer.
- Inspected `site/universes-3d.js`: the transparent WebGL canvas was appended to `document.body` as a fixed full-viewport overlay with `z-index:9999`, above the campaign map and its DOM layers.
- Moved the WebGL canvas into the active map viewport as an absolutely positioned transparent layer. Its offset now tracks the viewport's horizontal/vertical scroll position, keeping the canvas pinned to the visible scrollport while the map content moves.
- Established explicit layer order: atmospheric pseudo-elements at z-index 0, WebGL canvas at z-index 1, map tracks and labels at z-index 2. Canvas remains pointer-events:none.
- Universe/planet model generation and navigation unchanged; no progress, saves, purchases or inventory touched.
- Static source edits completed; must wait for web deployment and verify both maps on a real phone. Do not claim visual confirmation before user testing.
- `site/universes-3d.js` source commit: `fe44a2e2ce4ee1af83f0637d901b9cca54e4dc83`.
- `site/index.html` source commit: `0dcb29a4bb2c4073b52a630216b934799bb409b4`.
## Checkpoint 290 — remove opaque active universe-card backing
- Follow-up diagnosis found a legacy `#campaign .bb-galaxy-card.is-current` rule that paints a dark gradient panel over the shared nebula, even after the general card rule was made transparent.
- Added a final targeted override forcing all universe card states to transparent backing while retaining only the subtle translucent biome glow on the current card.
- No planet models, universe models, map navigation, progress, saves, purchases or inventory changed.
- Source commit: `9dc3b63fb96d9d781f82d38b088ab317727c6515`.
- Await web deployment and phone verification; this is a targeted code-level fix, not yet visually confirmed.

## Checkpoint 314 — signature 10×23 arena in 2D and 3D (2026-11-02)
- Reduced the shared logical board from 10×25 to 10×23. Canvas backing is now 300×690 and CSS aspect ratio is 10:23.
- Updated `site/arena-3d.js`: 3D shell, board planes, side glows, grid (23 row intervals), border, rails, beacons, camera framing, block positions and line-clear/landing/rotation effects now use the 23-row vertical span.
- 3D block cell centres are mapped from row 0..22 to y=+11..-11, with grid boundaries at ±11.5. The board remains 10 columns wide.
- Gravity interval, scoring, controls, collision and line-clear rules were not deliberately changed; the logical grid dimensions drive the existing game core.
- Source commits: `a99cfbf01656bf3972bf0a0106f874e0f8776369` (3D) and `6bb43c6ae9d5d0253e6473b9a10545ab2dbaa431` (2D/core).
- Static checks passed for the 10×23 logical dimensions, 300×690 canvas, 10:23 CSS ratio, 23-row 3D grid and updated 3D board/camera geometry. Deployment and real-device verification remain pending.
- Resume phrase: **TETRIOS LX — КОНТРОЛЬНАЯ ТОЧКА 314. ПРОВЕРИТЬ НА ОПУБЛИКОВАННОМ САЙТЕ АРЕНУ 10×23 В ОБЫЧНОМ И 3D-РЕЖИМЕ. УБЕДИТЬСЯ, ЧТО 3D-СЕТКА ИМЕЕТ 23 РЯДА, ФИГУРЫ СОВПАДАЮТ С КЛЕТКАМИ, ВЕРХ И НИЗ АРЕНЫ НЕ ОБРЕЗАНЫ, КАМЕРА ПОМЕЩАЕТ ВСЁ ПОЛЕ. ПРОВЕРИТЬ BLOCK RUN, ДВИЖЕНИЕ, ПОВОРОТ, СТОЛКНОВЕНИЯ И ОЧИСТКУ ЛИНИЙ. СКОРОСТЬ ПАДЕНИЯ НЕ МЕНЯТЬ. 🤘🏆**

## Checkpoint 315 — open 3D arena and expanded playfield (2026-11-02)

- User asked to remove the 3D board from its heavy rectangular block and use the unused space toward the lower-right of the play area.
- Removed the solid 3D shell, opaque board planes, full top edge, corner beacons and bottom base bar. The board now floats in the game space with the cell grid, restrained side guides and short corner accents instead of a closed rectangular box.
- Tightened the orthographic camera framing (from a 24.2-unit arena envelope with 2.5% padding to a 23.55-unit envelope with 0.8% padding) so the 10×23 grid occupies more of the available 3D canvas.
- Shifted the camera target slightly upper-left so the arena appears slightly farther right and down, using the spare space requested by the user. Gameplay coordinates and cell dimensions remain unchanged.
- The 10-column × 23-row grid, 2D canvas and gameplay logic are unchanged; this is a 3D presentation/camera update only.
- Source commit: `e4cc2602329c71c5cf8686635c93814dd69cb4cd` (`site/arena-3d.js`).
- Static checks passed for removal of the solid shell/planes/base/beacons, tighter camera framing, lower-right visual shift and preservation of the 23-row grid. Web deployment and physical-device visual verification are not yet confirmed.
- Resume phrase: **TETRIOS LX — КОНТРОЛЬНАЯ ТОЧКА 315. ПРОВЕРИТЬ ОТКРЫТУЮ 3D-АРЕНУ: ПОЛЕ БОЛЬШЕ НЕ ДОЛЖНО ВЫГЛЯДЕТЬ ЗАКЛЮЧЁННЫМ В ТЯЖЁЛУЮ ПРЯМОУГОЛЬНУЮ КОРОБКУ. УБЕДИТЬСЯ, ЧТО СЕТКА 10×23 СТАЛА КРУПНЕЕ, СМЕЩЕНА ЧУТЬ ВПРАВО И ВНИЗ, ВСЕ 23 РЯДА И 10 КОЛОНОК ПОМЕЩАЮТСЯ, ФИГУРЫ И ЭФФЕКТЫ НЕ ОБРЕЗАНЫ. ПРОВЕРИТЬ 3D НА ТЕЛЕФОНЕ И В BLOCK RUN; 2D, СКОРОСТЬ ПАДЕНИЯ И ИГРОВУЮ ЛОГИКУ НЕ МЕНЯТЬ. 🤘🏆**
