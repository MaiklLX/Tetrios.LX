# BLOCK BUDDIES — KT-470
## Block Run encounter/session integration

- Date: 2026-11-08
- Branch: `godot/kt428-buddy-companion-2026-11-07`
- Parent: KT-469

### Implemented

Added `godot/scripts/block_run_session.gd`, a deterministic run coordinator that composes the isolated encounter model, event effects and board adapter:
- Starts and resets a fresh room-1 encounter and 10×23 board.
- Applies card drafts to run-local threshold, gravity, Hold and shield state.
- Counts piece placements and applies Gear score bonuses.
- Routes line-clear scoring, combo multipliers, monster damage, level charge and Infinity relic gain into the encounter.
- Advances the one-second run clock, resolves Tide/Unstable timers and decrements the enemy attack countdown.
- Resolves Breach/Crossfire/Siege attacks and inserts their rows into the session board.
- Honors Reserve attack absorption and reports board overflow as a failed run.
- On enemy defeat, advances the encounter and applies Rift bottom-row clearing.

### Regression tests

Added `godot/tests/block_run_session_test.gd` and CI step `Run Block Run session integration tests`.
Tests cover initialization, card drafting, line-clear damage/score routing, timed attack insertion, Reserve absorption, top-out failure and rejection of events after failure.

### CI

Run `42463408749`, run #143, HEAD `6b8bd27f280ef2eabaf4ef0e90457535557af18a`: **SUCCESS**.
All stages passed: import, main script parse, existing gameplay tests, Web migration tests, Block Run model, effects, board adapter, session integration and scene smoke test.

### Explicit limitations

- This is a tested domain/session coordinator; it is not yet attached to the live `main.gd` gameplay scene. Block Run is still not selectable/playable from the UI.
- Shield/Nova rescue mutation, three simultaneously tracked goals and reward replacement/settlement, hero abilities, card draft/encounter HUD and run-end presentation remain pending.
- Level progression and board gravity still need final source-parity wiring in the scene.
- No persistent storage, main merge, deployment, APK build/release or physical-device validation.
