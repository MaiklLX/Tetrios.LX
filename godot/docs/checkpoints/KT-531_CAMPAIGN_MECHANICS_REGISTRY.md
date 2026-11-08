# KT-531 — Campaign mechanics registry foundation

- Date: 2026-11-08
- Branch: `godot/kt493-gallery-validated-2026-11-08`
- Parent: KT-530 (campaign mission variety and bounded progression).
- Scope: introduce a data-only mechanics registry for the 12-universe campaign.

## Implemented
- Added `campaign_mechanics.gd` with one authored mechanic family and introductory description for each of the 12 universes.
- Added a catalog of six Daily-Challenge-style modifier candidates: accelerated gravity, rotation limit, clear surge, hazard cells, unstable layout and hero ability cooldown.
- Modifier definitions are explicitly marked as candidates. They are not asserted to be a verbatim copy of the legacy Daily Challenge catalog; source parity review remains required.
- Added deterministic planet assignment: the opening universe remains modifier-free; ordinary planets receive at most one modifier; boss planets may receive two only when an explicit compatibility pair is approved.
- Added validation for unknown, duplicate, excessive and incompatible modifiers.
- Every assigned modifier returns preview metadata. The registry is data-only and reports `mechanics_live=false`; it does not change gravity, input, board state, piece generation or hero skills.

## Tests
- New isolated `campaign_mechanics_test.gd` covers all 12 universe definitions, index validation, ordinary/boss modifier caps, pair compatibility, duplicate/unknown IDs, deterministic assignment, previews and the no-live-effects boundary.
- CI includes a dedicated Campaign mechanics registry test step.

## Next KT sequence
- KT-532: audit the exact legacy Daily Challenge rule catalog and map only source-confirmed effects to campaign-safe adapters.
- KT-533: implement the campaign modifier runtime adapter with deterministic, reversible session rules.
- KT-534: introduce the first non-standard piece family behind a feature gate, with model and board-collision tests.
- KT-535+: introduce universe-specific obstacles/hazards one family at a time, then perform cross-universe difficulty and accessibility balance.

## Safety
- No edits to `main`, no merge, public deployment, backup branch/tag, APK build/release or physical-device claims.
- No existing campaign saves or progress formats changed.
- No player-facing campaign behavior changed by this checkpoint.
