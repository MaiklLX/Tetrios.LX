# KT-545 — Authored campaign layouts and mission runner foundation

## Status
Implementation in progress on `godot/kt493-gallery-validated-2026-11-08`. PR #81 remains Draft/open/unmerged. No main merge, public deployment or APK release.

## Scope of this slice
- Add a deterministic, validated authored starting-layout contract to the isolated campaign piece runtime.
- Allow planet definitions to supply optional bottom-up board rows before the first piece spawns.
- Keep ordinary planets on the existing empty-board fallback when no authored layout is present.
- Preserve the existing standard piece bag and the campaign-only Cargo Hook schedule.
- Keep the shared Classic model, Sprint/Marathon and Block Run unchanged.

## First Star Caravan authored layouts
- Planet 033 — Cargo Corridor (`cargo_corridor`): three bottom rows, 26 occupied cells.
- Planet 036 — Offset Bay (`offset_bay`): three bottom rows with staggered gaps.
- Planet 046 — Staggered Joint (`staggered_joint`): three bottom rows with offset passages.

Rows are authored top-to-bottom within the bottom stack. Each row is exactly 10 characters. A dot is an empty cell; digits 0–6 select an existing standard block color/type. Full rows, empty rows, invalid symbols, malformed widths and layouts that could overlap the spawn zone are rejected. Layout application is atomic: invalid input must not mutate the live board.

## Runtime behavior
- The layout is applied to a fresh campaign-owned 10×23 board before the initial piece is spawned.
- The first active piece remains a standard piece unless the planet explicitly declares the already-approved Cargo Hook event.
- Cargo Hook remains restricted to authored campaign planets; it does not enter Classic, Sprint/Marathon or Block Run.
- Leaving an unfinished planet still restarts that attempt; completed progression and rewards persist.

## Validation
- Unit tests cover valid layout application, exact occupied-cell count, invalid-layout rejection without mutation and safe standard-piece spawning.
- Catalog tests cover layout metadata and malformed-row rejection.
- Live integration test launches Planet 033 through the real campaign entry point and verifies the authored board is active without mutating the shared Classic model.
- Visual CI captures Planet 033 briefing and live arena screens.
- Full Godot CI must pass before this KT is accepted.

## KT-545.2 — authored mission contracts and multi-layout verification
- Added explicit mission contracts for the three starting-layout missions rather than relying only on the generated chapter formula:
  - Planet 033: line objective 12, guided difficulty, expected duration 90–150 seconds.
  - Planet 036: line objective 12, standard difficulty, expected duration 120–180 seconds.
  - Planet 046: line objective 13, standard difficulty, expected duration 150–210 seconds.
- The catalog validator now rejects unknown objective families, negative targets, incompatible objective fields, unsupported difficulty bands, malformed duration ranges and non-array event schedules.
- Campaign progression applies the authored mission contract to the live campaign session definition; ordinary planets continue using the bounded formula fallback.
- Catalog regression tests verify the resolved objective and pacing fields and reject malformed contracts.
- Live integration now launches all three authored layouts through the actual campaign entry point, checks occupied-cell totals (26 / 27 / 27), confirms a standard tetromino spawns, and continues to verify shared Classic isolation.
- Visual capture now includes briefing and live-arena captures for all three layout missions. These are CI screenshots, not static gallery concepts.

## KT-545.3 — complete Star Caravan mission pacing audit
- Every one of the 30 Star Caravan planets now resolves a supported objective type, difficulty band, expected duration range and deterministic event-schedule field through the campaign progression contract.
- The baseline pacing ladder is bounded by planet position: planets 001–009 guided, 010–019 standard, 020–029 advanced, and the chapter finale mastery. The three authored-layout missions retain their explicit overrides.
- The campaign catalog test now walks all 30 live planet definitions and checks objective, difficulty, duration and event-schedule completeness, in addition to the authored layout and malformed-data tests.
- This is a metadata and validation audit, not a claim that all 30 encounters have unique mechanics or bespoke visual content.

## Remaining KT-545 work
- Inspect the new CI screenshot captures for all three layouts and adjust any unfair or visually confusing gap patterns.
- Add deterministic completion-path simulation for each authored layout; successful spawn alone is not proof of fair playability.
- Complete the remaining 30-node Star Caravan objective/difficulty/duration audit; do not label briefing-only entries as live mechanics.
- Full Godot CI must pass on the final KT-545 head before this checkpoint is accepted.

## Acceptance boundary
This slice proves the authored-layout runtime seam; it does not mean the full Star Caravan chapter or all 360 planets are complete. No modifier registry entry becomes live without a dedicated runtime implementation, briefing, deterministic tests and visual proof.


## KT-546.1 — boss phase contract hardening
- The boss catalog validator now checks every phase independently: phase titles must be present, quotas cannot be negative, and no phase may have both line and score quotas set to zero.
- Three-phase encounters must retain a positive total line-clear requirement across the full encounter; malformed phase data fails closed before it can enter a live campaign session.
- Added regression cases for negative phase quotas and an empty/unwinnable phase.
- Existing authored bosses remain three sequential phases with per-phase progress baselines; the live HUD now displays both active quotas when a phase requires both.
- This is a data-integrity and player-readability improvement. It does not add unimplemented attack patterns or claim new boss mechanics.
- CI validation is required on the resulting branch head before this checkpoint is accepted.
