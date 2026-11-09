# KT-536 — Campaign special-piece integration contract

## Status
**Design-only checkpoint.** The Cargo Hook silhouette remains pending the user's visual approval. No gameplay integration is authorized by this document.

## Current verified boundaries
- `campaign_special_piece.gd` is a pure geometry prototype: five cells, four normalized rotations, centered spawn, fit checks and deterministic horizontal wall kicks.
- `campaign_special_piece_preview.tscn` is a review-only scene. It is loaded only by the visual-capture test.
- `game_model.gd` remains the shared 10×23 model for Classic, Sprint/Marathon and Block Run. Its seven-bag contains exactly seven four-cell tetrominoes; its save validator currently expects four active cells and piece IDs in the seven-piece range.
- Campaign progression currently launches a campaign rules session using the same shared model. Therefore, simply placing a fifth cell into the current model would cross an important boundary: shared save validation, piece identity, Hold, rotation and palette assumptions must all be considered.
- Campaign modifiers and special pieces are campaign-only. No modifier or special piece may enter Classic, Sprint/Marathon, Block Run or other modes.

## Recommended integration shape
1. Keep `game_model.gd` and its seven-bag contract unchanged.
2. Introduce a campaign-owned runtime/model boundary for non-standard pieces. It must own special-piece identity, spawn schedule, active geometry, rotation state, Hold compatibility, lock/line-clear handoff and campaign-run snapshot data.
3. Reuse the shared board dimensions and board rendering primitives where safe, but do not smuggle special-piece IDs into the standard seven-piece ID range or serialize a five-cell piece through the existing four-cell save schema.
4. Make campaign mode choose the campaign runtime explicitly at launch. All other mode launch paths must continue to instantiate/use the existing shared model.
5. Keep campaign special-piece appearance and collision identity separate. Palette/skin changes must never change geometry or collision cells.
6. Treat the five-cell piece as a deliberate authored event, not a random addition to the standard seven-bag. The campaign level definition must explicitly opt into it and preview it before the run begins.
7. If the player can Hold a special piece, test both directions (special→standard and standard→special), one-use-per-piece rules, reset behavior and save/restore. If that contract cannot be guaranteed in the first integration, disable Hold for the special piece with a clear in-game explanation rather than silently losing or duplicating it.

## Required test gates before any live scene connection
- Geometry: five unique cells in every orientation; four distinct rotations; normalized bounds; deterministic wall kicks; blocked rotation preserves the exact previous pose.
- Board rules: spawn collision, left/right/floor bounds, occupied-cell rejection, lock placement, line clear, top-out and board-rescue interactions.
- Lifecycle: spawn cadence, Hold in both directions, hard/soft drop, restart, pause/resume, completion/failure and campaign return navigation.
- Persistence: standard save schema remains byte-for-byte compatible; campaign snapshot records special-piece identity and geometry version; malformed/unknown IDs fail closed without partially mutating a run.
- Isolation: explicit regression assertions that Classic, Sprint, Marathon and Block Run always use the original seven-piece bag and four-cell piece definitions.
- Visual QA: review the user-approved silhouette in the live campaign board at 720×1280, 360×800 and 412×915; ensure the fifth cell does not reduce the board size or overlap HUD/controls.

## Staged implementation after approval
- KT-537: build and test the isolated campaign piece runtime contract; no live mode connection.
- KT-538: integrate behind an explicit campaign-only runtime selection and a single authored test planet; preserve all existing mode paths.
- KT-539: add campaign preview copy/visual treatment, Hold behavior and persistence fixtures as applicable.
- KT-540: end-to-end campaign playthrough and visual regression, including all existing mode-isolation tests.

## Stop conditions
- Do not change the Cargo Hook silhouette until the user approves or requests a revision.
- Do not wire any special piece into the live campaign until the user approves the visual and the isolated runtime tests pass.
- Do not alter Classic, Sprint/Marathon, Block Run, the seven-bag, standard save schema, main branch, public deployment or APK release.
- PR #81 remains Draft and unmerged.
