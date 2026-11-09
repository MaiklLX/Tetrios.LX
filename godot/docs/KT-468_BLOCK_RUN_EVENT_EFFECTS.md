# BLOCK BUDDIES — KT-468
## Deterministic Block Run card event effects

- Date: 2026-11-08
- Branch: `godot/kt428-buddy-companion-2026-11-07`
- Source baseline: `main@38c61b606187b88ce8a48a1c6b71d264aecf4258`
- Parent checkpoints: KT-466 domain foundation, KT-467 source event audit

### Implemented

Added `godot/scripts/block_run_effects.gd`. It is a deterministic rules layer: methods accept explicit ranks and event context and return effect outcomes. It does not access scene nodes, browser storage, wall-clock time, or random APIs, and it is not yet wired to the live board.

Implemented event calculations:
- Card draft: Loop's immediate threshold reduction; Slow's source-observed initial drop adjustment; Shield + Armor charge initialization; Reserve charge initialization; Hold counter reset.
- Piece lock: Gear bonus every fifth placement; Hold limit calculation including Pixel's hero-specific override.
- Line clear: base score multiplier, Score + Mult synergy, Glow, Neuron, Dust, Magnet, Burst, Flash, Resonance, Echo, Reactor, Infinity relics, monster damage from Score/Burst/Hunter, and Plasma drop reset.
- Timer second: Tide at 45-second boundaries and Unstable at 90-second boundaries.
- Level-up: Memory/Loop/Chrono threshold changes, Slow/Fortress gravity interval changes, Void compression request, and an explicit Comet source-review gate.
- Rotation: Stable kick range and deterministic Shift roll.
- Piece spawn: Mirror, Prism and Aura flags.
- Spawn collision: Shield/Armor rescue charges and Iron Fortress rescue profile; one-time Nova rescue.
- Monster defeat: Rift bottom-row clear capped at three.

### Fidelity safeguards

- Pixel's Hold limit takes precedence over the Hold card exactly as in the Web source.
- Iron Fortress rescue geometry is represented as five randomized bottom rows starting at row 18, with 10% fill probability; the normal shield path uses three rows starting at row 20, with 22% fill probability.
- Shift accepts an injected deterministic roll; no random generator is called from the effects model.
- Comet does not silently reproduce the legacy local-timer bug. The model returns `comet_requires_source_review` and no score award until its intended timing rule is decided.
- Luck remains catalog-only because the audited Web source has no active gameplay consumer for it.

### Tests and validation

- Added `godot/tests/block_run_effects_test.gd`.
- Added a dedicated CI stage: `Run Block Run event effect tests`.
- Coverage includes score multipliers and card bonuses, monster damage, level charge and relic boundaries, timer boundaries, level-up math, deterministic rotation, Mirror/Prism/Aura, Pixel Hold override, Shield + Armor rescue geometry, Nova one-time rescue, Rift cap, Gear placement bonus, and card-draft state.
- Godot Native Project Check run `42462909799` on HEAD `cdf419b0f73eddc71f12e88aee4578a6f9edffd0`: **SUCCESS** — import, parse, existing gameplay tests, migration tests, Block Run model tests, Block Run event-effect tests and scene smoke test all passed.

### Still pending

- The event model is not yet connected to `game_model.gd` or `main.gd`; no player-facing Block Run gameplay is exposed.
- Remaining work: integrate board mutations (Void, Shield, Nova, Rift), attack countdown into the active session, three live goals with replacement/reward settlement, relic wallet, hero abilities, encounter HUD, card draft UI, game-over/result flow and responsive QA.
- The mode remains hidden from the selector until those pieces form a complete playable loop.
- No storage/persistence work, main merge, deployment, APK build/release or physical-device validation.
