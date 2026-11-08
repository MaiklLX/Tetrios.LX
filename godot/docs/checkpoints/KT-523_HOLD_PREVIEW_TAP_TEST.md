# KT-523/524 — HOLD preview and paused-touch regression coverage

Date: 2026-11-08

## Scope
- Added integration-level regression checks for the dedicated HOLD preview-card tap target.
- The first tap must store the current piece and spawn the next piece at its shape-centered spawn position.
- A second tap before the active piece locks must not perform another swap.
- HOLD and DROP taps must not mutate gameplay while paused.
- The expected spawn position is derived from the actual tetromino shape, avoiding random-piece-dependent test failures.
- Existing board-tap rotation, swipe, and game-model Hold rules remain unchanged.

## Safety
- Development branch: `godot/kt493-gallery-validated-2026-11-08`
- Public `main` remains untouched.
- Draft PR #81 remains unmerged.
- No deployment or APK build/release was requested or performed.

## Validation
- KT-523 commit: `467ce9ced07e47640865b96bf681aa2e58899d94`
- KT-523 CI: passed (run #324).
- KT-524 test hardening commit: pending CI.
