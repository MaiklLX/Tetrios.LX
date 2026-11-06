# Godot migration checkpoints

## KT-GODOT-002.1 — CI failure diagnosis and repair
- Date: 2026-11-06
- Branch: `godot/android-native-foundation-2026-11-05`
- Previous head inspected: `05149289b089b86e557e6bd7b8b0b159545ef80e`.
- GitHub Actions run #12 reached project import successfully, but the log exposed three GDScript type-inference errors in `godot/scripts/main.gd` (layout width/offset and control label), plus an invalid untyped-array assignment into `Array[Vector2i]` in `game_model.gd`.
- The model test then stopped at its first assertion without calling `quit()`; the runner eventually cancelled the job at its 15-minute limit. This was a test-harness hang after a real assertion failure, not evidence of a successful test run.
- Repair commits: `4ca0a48c994e3fe5b9de93a8f2824cec98d1320f` (explicit UI types), `34ea244f884ae5d49a253512af06a0510bc7c5ec` (typed-array assignment), `0ec1c6b2b0202289814866c1aa17c1cc0257f723` (seeded, fail-fast model tests), `146ee5cb892459ea7464c906e5de02bd99ea5f3d` (script parse check and test-step timeout).
- Validation status: **PASS** — GitHub Actions run #19 (`42210305113`) on commit `88d8437fe0362350f9e8b9df75cdf2826f15a26c` completed successfully on 2026-11-06. Godot 4.4.1 project import, explicit `main.gd` parse check, seeded model tests, and headless scene smoke test all passed. The test output confirmed the 10×23 board, seven-bag, spawn centering, movement, rotation, and single-line clear. This is a green technical foundation check, not full legacy gameplay parity.
- No APK built. No changes to `main` or the existing web implementation. The gameplay board remains 2D; no 3D arena was introduced.

## KT-GODOT-001 — Foundation established
- Date: 2026-11-05
- Branch: `godot/android-native-foundation-2026-11-05`
- Commit: `489e9624c8c349cd2d754436895f291c146cd84f`
- Status: **PASS — initial engine smoke test**
- Godot: 4.4.1
- Verified in GitHub Actions: project import and headless scene launch both passed.
- Included: portrait-first project settings, Compatibility renderer, 10×20 board model, seven tetromino definitions, movement, rotation with basic wall kicks, gravity, soft/hard drop, line clear, score/level, and touch/keyboard prototype controls.
- Not included yet: final 3D Buddy models, final UI, all legacy modes, existing progression/rewards, persistence, Android export/signing.
- No APK built. No changes to `main` or the existing web game.

## KT-GODOT-001.1 — Deterministic model checks
- Added CI checks for board dimensions, all seven four-cell tetromino definitions, seven-bag completeness and boundary, spawn centering, movement, rotation, and a deterministic single-line clear fixture.
- Passed in Godot Native Project Check run #19 on 2026-11-06.
- This is an initial regression suite only; the broader parity fixtures in `PARITY_MATRIX.md` remain open.

## KT-GODOT-002 — Source parity audit
- Inventory current source game modes, rules, timers, objectives, rewards, hero identities, progression, and save data.
- Build a parity matrix with references to source files and test fixtures.
- Do not silently simplify or invent legacy rules.

## Control phrase for a new chat
`BLOCK BUDDIES GODOT — KT-GODOT-001.1. Продолжаем нативную Android-версию в ветке godot/android-native-foundation-2026-11-05. main не трогать, старую игру не ломать, APK пока не собирать. Сначала проверить Godot CI и детерминированные тесты, затем провести полный аудит исходных режимов и начать визуальную сцену с 3D Buddy.`


## KT-GODOT-001.2 — Legacy board dimensions and tetromino identity
- Date: 2026-11-05
- Source baseline: `main@8fc2b889524d3dcaf87439efe57aa74dc68e1042`
- Godot branch: `godot/android-native-foundation-2026-11-05`
- Corrected the native board from 10×20 to the source game's 10×23.
- Reordered the seven tetromino definitions to source order I/T/J/L/O/S/Z.
- Matched the seven source piece colors.
- Updated deterministic model fixture and board layout sizing.
- Source parity audit started in `godot/docs/PARITY_MATRIX.md`; still in progress. Score, rotation, randomizer, timers, Hold, mode progression, rewards and persistence are not yet parity-approved.
- No APK built. No change to `main`.

