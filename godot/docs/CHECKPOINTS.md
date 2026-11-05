# Godot migration checkpoints

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
- Add board/movement/rotation/line-clear tests to CI.
- Require a green CI run before starting the visual production pass.

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

