# KT-540 — Campaign checkpoint lifecycle integration

## Behavior
- Campaign runs checkpoint every 10 seconds of active play. Paused time is excluded.
- Entering the in-game pause state writes a checkpoint immediately.
- Godot's application-paused notification pauses the campaign and writes a checkpoint before suspension.
- On next app launch, a valid checkpoint is restored into the campaign-owned runtime and the run opens paused, requiring an explicit Resume action.
- The campaign timer is restored with the board/runtime snapshot, so elapsed objective time does not reset on resume.
- A checkpoint is cleared when the player retries, completes the planet, returns to the route, or starts a different standard mode.
- A checkpoint for a planet that is no longer the current unlocked planet is discarded rather than applied to a different run.

## Integrity and reward safety
- Restore uses the validated campaign-only envelope from KT-539 and binds the payload to its planet ID.
- Only running sessions are checkpointed. Completed/failed sessions are not written as resumable runs.
- Completion remains processed by the existing guarded `campaign_completion_processed` path; restored sessions start as running and cannot replay an already-completed reward receipt from a checkpoint.
- Campaign progression/reward persistence remains in the existing campaign progression store. The new run checkpoint does not write to the standard game save.
- Checkpoint writes are isolated to `user://campaign_run_v1.save`.

## Validation boundary
- The checkpoint store suite verifies the versioned runtime payload and elapsed-time/planet identity recovery.
- CI also parses the live main scene and runs all Classic, Campaign, Block Run, visual capture and scene smoke suites.
- Actual OS background/foreground suspension behavior still needs physical Android/iOS device testing. CI does not claim to simulate mobile lifecycle callbacks.
- No public deployment, main merge or APK release.
