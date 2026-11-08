# KT-523 — HOLD preview interaction regression coverage

Date: 2026-11-08

## Scope
- Added an integration-level regression check for the dedicated HOLD preview-card tap target in the Godot main scene.
- The test verifies that the first tap stores the current piece and spawns the next piece at its normal spawn origin.
- The test verifies that a second tap before the active piece locks does not perform another swap.
- Existing board-tap rotation, swipe, and game-model Hold rules remain unchanged.

## Safety
- Development branch: `godot/kt493-gallery-validated-2026-11-08`
- Public `main` remains untouched.
- Draft PR #81 remains unmerged.
- No deployment or APK build/release was requested or performed.

## Validation
- Commit: `467ce9ced07e47640865b96bf681aa2e58899d94`
- CI validation is pending for this commit.
