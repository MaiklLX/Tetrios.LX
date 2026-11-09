# KT-544A — Star Caravan authored mission presentation

## Implemented
- Live planet-detail UI now uses the authored Star Caravan mission title instead of only a generic planet number.
- The detail screen displays a short authored briefing, the objective family, concrete target/reward values, and a visible signature-event or boss identity line.
- Layout adapts between compact portrait phones and wider portrait screens; mission briefing is wrapped into a bounded number of readable lines.
- The visual capture suite now includes:
  - `30-star-caravan-authored-planet-detail.png`
  - `31-star-caravan-guardian-briefing.png`
  - `32-star-caravan-cargo-hook-mission-briefing.png`
- These captures exercise the first mission, the first boss milestone and the Cargo Hook showcase briefing.

## Scope boundary
This is the first player-facing presentation layer for the authored chapter. It does not claim that boss phases, hazards or additional mechanics are already playable. The current gameplay objectives and Cargo Hook runtime remain as previously implemented. The other 11 universes continue to use the existing fallback definitions.

## Protected behavior
- No shared gameplay model changes.
- No Classic, Sprint/Marathon or Block Run behavior changes.
- No save schema, reward, unlock or exit/restart policy changes.
- No main merge, public deployment or APK release.

## Validation
- Added the three new screenshot captures to the existing Godot visual-capture test.
- Exact latest commit: `4a372e8dad767d46319429df870afd42480f0958` (visual test update); CI result must be checked against the latest branch HEAD before acceptance.
