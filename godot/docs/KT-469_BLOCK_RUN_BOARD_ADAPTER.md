# BLOCK BUDDIES — KT-469
## Block Run board mutation adapter

- Date: 2026-11-08
- Branch: `godot/kt428-buddy-companion-2026-11-07`
- Parent: KT-468

### Implemented

Added `godot/scripts/block_run_board.gd`, a separate, validated board-mutation layer:
- Inserts one or more deterministic garbage rows at the bottom while shifting the board upward.
- Reports top-out overflow when any cells are displaced from the top.
- Validates the full 10×23 board and every incoming row before mutation; malformed input is rejected without partial writes.
- Clears a bounded number of bottom rows while preserving the 10×23 board dimensions.
- Builds deterministic rescue-row patterns with explicit holes for later Shield/Nova/Rift integration.

### Tests

Added `godot/tests/block_run_board_test.gd` and CI step `Run Block Run board mutation tests`.
Coverage: empty-board garbage insertion, hole preservation, top-out detection, atomic malformed-row rejection, bottom-row clearing, deterministic rescue pattern dimensions and hole counts.

CI run `42463302261` on HEAD `5dcecbf891c9ac098ae86f0d36bcfbc4fc6b48ad`: **SUCCESS**.
The complete validation job passed: project import, main script parse, existing gameplay tests, migration tests, Block Run model tests, Block Run event-effect tests, board mutation tests and scene smoke test.

### Scope boundary

This is a tested board adapter, not yet a player-facing mode. The helper is not yet called from the active main scene or standard piece-lock loop. Next integration stage must connect enemy attacks and rescue outcomes to the actual board, then add three live goals, reward settlement, hero skills and encounter/draft UI. Block Run remains hidden from the selector until the complete loop is playable.

No changes to main, deployment, APK, persistent storage, or user data. Physical Android device not tested.
