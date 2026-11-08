# KT-525 — Functional Home Hub Navigation

Status: implementation committed to the existing Godot development branch. Draft PR #81 remains the review boundary.

## Delivered
- App startup now opens a dedicated Block Buddies home hub instead of dropping directly into the three-mode selector.
- Home hub includes distinct hit targets for Cosmic Campaign, Block Run, Daily Tasks, Heroes and Shop.
- Campaign and Block Run routes enter the existing Classic / Sprint / Marathon selector.
- The mode selector now has an explicit return-to-home target.
- Heroes, Shop and Daily Tasks open separate in-app section screens with a clear Home return target. These are intentional staged section shells, not fake purchase or progression flows.
- Existing gameplay scene, arena geometry, HOLD, DROP, pause, Block Run systems and mode lifecycle remain in place.

## Validation added
- Integration coverage for Home → mode selector → Home.
- Integration coverage for Home → Daily Tasks → Home.
- Integration coverage for Heroes and Shop navigation.
- Existing gameplay/model and visual capture suites remain the required CI gate.

## Scope / safety
- Development branch only: `godot/kt493-gallery-validated-2026-11-08`.
- PR #81 remains Draft and unmerged.
- No changes to `main`, public deployment, backup/archive branch, or APK release.
- Physical-device validation is still required before any release decision.

## Next
1. Turn the Cosmic Campaign route into the 12-universe atlas and 30-node planet path.
2. Build real Heroes, Shop and Upgrades screens with state-backed interactions.
3. Implement daily tasks and reward receipts only after their persistence model is agreed and tested.
