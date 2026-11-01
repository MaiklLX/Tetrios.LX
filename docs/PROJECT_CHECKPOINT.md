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
