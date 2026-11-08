# KT-526 — Live Cosmic Campaign Navigation

Status: implementation committed on the existing Godot development branch. Draft PR #81 remains the review boundary.

## Delivered
- Home → Cosmic Atlas now opens a live in-game campaign screen rather than the static concept gallery.
- Atlas renders all 12 named universes, with 30 planet slots represented per universe (360 total).
- Selecting a universe opens its 30-node serpentine route, including special milestone markers at planets 010, 020 and 030.
- Selecting a node opens a planet detail screen with a clear objective panel and a start action.
- Back navigation is hierarchical: Planet → Route → Atlas → Home.
- Starting the currently unlocked entry planet opens the existing mode selector; backing out restores the selected planet.
- Campaign menus suspend gravity and Block Run elapsed-time advancement; Buddy is hidden so it cannot overlap navigation content.
- Layout adapts to narrow portrait screens and larger portrait viewports.

## Validation added
- Visual capture coverage for the live Atlas, Universe Route and Planet Detail screens.
- Integration assertions for all 12 universe hit targets and 30 route-node hit targets.
- Navigation assertions for opening the first planet, returning from mode selection, and backing out to Home.
- A timer-freeze assertion while the campaign map is open.

## Explicit limitations / next work
- Only Universe 01 / Planet 001 is currently marked playable. The other 11 universes and 29 remaining planets in the first universe are visible but locked.
- Planet start currently hands off to the existing Classic / Sprint / Marathon mode selector. Dedicated campaign level objectives, rewards, completion receipts, sequential unlocks and persistent progress are not implemented yet.
- These progression systems must be modeled and tested before the atlas is presented as a complete campaign.

## Scope / safety
- Branch: `godot/kt493-gallery-validated-2026-11-08`.
- PR #81 remains Draft and unmerged.
- No changes to `main`, public deployment, backup/archive branch, or APK release.
- Physical-device verification remains required before any release decision.
