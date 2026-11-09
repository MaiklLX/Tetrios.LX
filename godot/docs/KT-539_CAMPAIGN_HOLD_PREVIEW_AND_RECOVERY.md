# KT-539 — Campaign Hold, preview and checkpoint recovery contract

## Scope
This checkpoint hardens the campaign-only Cargo Hook lifecycle and defines a separate recovery boundary. It does not change the shared Classic/Sprint/Marathon model, Block Run, the standard seven-piece bag, or their save formats.

## Hold and preview rules
- Hold remains one use per falling piece; eligibility resets only after lock.
- Empty Hold stores the active piece and draws the next standard tetromino.
- Occupied Hold swaps the stored piece back into the active slot; the incoming piece starts in its canonical base orientation.
- The five-cell Cargo Hook keeps ID 7 and its cyan/gold preview rendering. It never enters the random standard bag.
- The existing live preview row reads Hold and Next from the campaign runtime while a campaign is active; all other modes continue to read the shared model.

## Campaign checkpoint envelope
Added `campaign_piece_store.gd`, with a dedicated versioned envelope:
- `store_version`: campaign store format version.
- `planet_id`: authored planet identity; a checkpoint cannot be loaded into a different planet.
- `runtime`: the complete versioned campaign runtime snapshot, including board, active pose, bag, Hold state, counters and special-piece identity.

The adapter validates the entire snapshot in a temporary campaign runtime before writing or mutating a destination runtime. Restore rejects missing files, unsupported envelope versions, mismatched planet IDs, malformed snapshots and invalid runtime state. Its default path is `user://campaign_run_v1.save`; tests use a separate temporary user path.

## Integration boundary
KT-539 deliberately introduces and tests the adapter without enabling automatic resume or changing the live launch/retry lifecycle. That wiring needs a separate explicit lifecycle decision: when to checkpoint (pause, app background, periodic active play), when to clear after completion/retry, and how to present a recoverable run to the player. Until that is approved and tested, the adapter is a validated isolated capability, not a claim that campaign progress auto-resumes after an app restart.

## Validation
- Added `campaign_piece_store_test.gd`: exact round-trip recovery, campaign planet binding, rejection without partial mutation, invalid planet save rejection and independent cleanup.
- Registered the suite in the Godot Native Project Check workflow.
- No shared save migration, main merge, public deployment, APK release or physical-device claim.
