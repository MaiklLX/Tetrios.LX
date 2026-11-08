## KT-533 — Isolated campaign tempo and score adapters
- Added `campaign_effect_session.gd`, a reversible session adapter for six source-audited low-risk Daily rules: gravity, gravityFlip, artifactHunt, echoCombo, comet and pulse.
- Ported source-defined thresholds and outcomes: gravity −55 ms every 25 active seconds (150 ms floor); gravityFlip −30 ms per cleared line with accumulated penalty restored every 30 active seconds (150 ms floor); artifact +50% for eight seconds after each four cleared lines; echo +0.25 per cleared line up to ×2.5 and resets on a lock without a clear; comet +200 points inside its two-second window; pulse ×1.5 line-clear score and −25 ms on every fifth dropped piece (180 ms floor).
- The adapter accepts active-time deltas only for time-based rules, counts piece-drop events for Pulse, exposes deterministic result dictionaries and a snapshot, rejects unsupported high-risk modifiers, and does not mutate the live board or global modes.
- Added deterministic tests for thresholds, multi-interval time steps, expiry, score math, caps, resets, fifth-piece Pulse cadence, minimum gravity floor and unsupported modifiers; added the suite to GitHub Actions.
- Deliberate boundary: no live campaign scene integration in KT-533. Next is to wire the adapter only into campaign sessions behind an explicit feature gate, verify real piece/line events, and keep Classic/Block Run unchanged. KT-534 remains the first original special-piece prototype.
- No main merge, public deployment, APK build/release, or save-data changes.

## KT-534 — First original campaign special-piece geometry prototype
- Added an isolated `campaign_special_piece.gd` prototype for the five-cell `cargo_hook` pentomino (display name: «Грузовой крюк»).
- Defines four normalized, distinct rotations, centered spawn positioning, board-boundary/occupied-cell fit checks, and deterministic horizontal wall kicks.
- Added tests for five-cell preservation, four unique rotations, normalized bounds, rotation wraparound, centered spawn on the 10-column board, wall/floor/occupied-cell rejection, successful rotation, right-wall kick, and safe rejection when all candidate poses are blocked.
- The module is not imported by `game_model.gd`, does not enter the seven-bag, does not alter saves, and is not wired into live gameplay. It is a campaign-only prototype for geometry validation; Classic and Block Run remain untouched.
- KT-533 Pulse test correction: the 180 ms floor requires 24 fifth-piece triggers (120 drops from a fresh session), not 21 triggers. Adapter behavior remains 25 ms per fifth dropped piece.
- Next: review visual readability and play-feel of the Cargo Hook in a dedicated campaign preview, then decide whether/how to integrate it behind the campaign-only feature gate. No main merge, public deployment, or APK release.
