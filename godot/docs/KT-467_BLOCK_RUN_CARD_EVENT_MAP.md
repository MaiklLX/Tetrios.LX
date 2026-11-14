# BLOCK BUDDIES — KT-467
## Block Run card event and effect audit

- Date: 2026-11-08
- Branch: `godot/kt428-buddy-companion-2026-11-07`
- Source baseline: `main@38c61b606187b88ce8a48a1c6b71d264aecf4258`
- Parent checkpoint: KT-466

This is a source audit, not a claim that all effects have already been ported. The trigger names below are derived from the live Web source's line-clear, lock, timer, level-up, spawn-collision, rotation, render and encounter paths.

## Confirmed event map

| Card | Source event / trigger | Observed behavior |
|---|---|---|
| `score` | Line clear / combo; monster damage | Adds `15% × rank` per combo step to score multiplier. Monster damage from a clear also scales by `1 + floor(rank/3)`. |
| `shield` | Spawn collision / would-be top-out | Consumes shield charges; rebuilds a safer board. Charges are initialized from Shield + Armor ranks. |
| `mult` | Line clear scoring | Score multiplier is `1 + 0.5 × rank`. |
| `slow` | Level-up gravity; attack timer synergy | Adds `25 ms × rank` to the next gravity interval at level-up; with Memory, monster attack timer is reduced by 8 seconds after an attack (see source contract). |
| `resonance` | Every fourth cumulative line | Adds `rank` to level charge when the fourth-line boundary is crossed. |
| `magnet` | Double-or-better clear | Adds `250 × rank` score on a 2+ line clear. |
| `glow` | Line clear scoring | Adds `10% × rank` to score multiplier. |
| `echo` | Every fifth cumulative line | Adds `rank` to level charge. |
| `unstable` | 90-second timer tick | Adds `500 × rank` score. |
| `dust` | Single-line clear | Adds `100 × rank` score. |
| `armor` | Shield setup / spawn collision | Adds its rank to Shield charges; Shield + Armor activates Iron Fortress rescue behavior. |
| `burst` | Triple-or-better clear; monster damage | Adds `600 × rank` score at 3+ lines and `2 × rank` extra monster damage on 3+ clears. |
| `prism` | Piece creation / render | Changes active-piece colors with a procedural prism animation; visual effect, not a score modifier. |
| `memory` | Level-up progression; attack timer synergy | Reduces next level's line threshold by rank; together with Slow, reduces monster attack interval by 8 seconds. |
| `hold` | Hold action | Raises Hold uses per falling piece to `1 + rank`. |
| `reactor` | Every tenth cumulative line | Adds `needLines × rank` to level charge. |
| `comet` | Level-up | Awards +300 score when the level-time check is under 35 seconds. The current source assigns its local `t0` immediately before checking, so the condition is effectively always true; treat as a source bug to resolve deliberately, not as an intentional balance rule. |
| `rift` | Monster defeat / room transition | Clears up to `min(3, rank)` bottom rows. |
| `stable` | Rotation collision / wall kick | Expands horizontal kick search to `min(4, 1 + rank)` cells. |
| `luck` | No runtime trigger found | The card is present in the catalog and rank-description fallback, but no active gameplay consumer was found in the audited source range. Do not invent an effect; decide whether to repair or retire it after a wider source/history check. |
| `void` | Level-up | Attempts one safe empty-row compression per level; reverts if it would collide with the freshly spawned piece. |
| `gear` | Piece lock / placement count | Every fifth placed piece awards `25 × rank` score. |
| `flash` | Double-or-better clear | Triggers the clear flash visual. |
| `neuron` | Line clear during first 30 seconds | Adds a fixed ×1.25 score multiplier while the run is under 30 seconds. |
| `infinity` | Every tenth cumulative line | Adds `rank` to the separate Block Run relic wallet (`nrRelics`). Do not merge it with campaign marks or coins. |
| `tide` | 45-second timer tick | Adds `rank` to level charge. |
| `fortress` | Level-up gravity; Shield + Armor synergy | Adds `15 ms × rank` to the gravity interval at level-up; with Shield + Armor, the rescue clears more rows with a lower random fill density. |
| `shift` | Successful rotation | 25% chance to award `25 × rank` score. |
| `reserve` | Monster attack resolution | One charge absorbs one full attack without adding garbage rows; rank grants the initial charge count. |
| `nova` | Spawn collision / would-be top-out | One-time emergency rescue; consumes the card and clears `rank` bottom rows. |
| `aura` | Active-piece rendering | Adds a visual aura around the falling piece while active boosts exist. |
| `hunter` | Double-or-better clear / monster damage | Adds `rank` extra monster damage on a 2+ line clear. |
| `mirror` | New piece creation | Mirrors the next piece horizontally when cumulative lines are a nonzero multiple of seven. |
| `loop` | Card draft / level-up progression | Immediately reduces the current line threshold by one when drafted; at level-up reduces the next threshold by rank, minimum three. |
| `plasma` | Successful line clear | Resets the next automatic drop interval after a clear. |

## Exact synergy contracts

1. `score + mult` — **КОМБО-РЕАКТОР**, +12% to clear scoring.
2. `shield + armor` — **ЖЕЛЕЗНАЯ КРЕПОСТЬ**, shield survives additional attacks and uses the wider rescue-board pattern.
3. `slow + memory` — **ХРОНОКОНТРОЛЬ**, monster attacks arrive less often (8-second interval adjustment in the source).

## Porting rules for KT-468+

- Implement effects as explicit events: `piece_locked`, `line_cleared`, `timer_second`, `level_up`, `piece_spawn_collision`, `piece_rotated`, `monster_attack`, and `monster_defeated`.
- Keep every effect behind Block Run mode ownership; never leak card ranks, relic effects, or attack timers into Classic, Sprint, Marathon, Campaign or Daily.
- Use deterministic inputs for random outcomes (for example Shift's 25% roll and Shield's rescue pattern) so model tests can prove caps and outcomes.
- Preserve separate currencies: coins for goal rewards, Block Run relics for Infinity, campaign marks for Campaign.
- Implement the three simultaneous goals and replacement/reward behavior separately from cards. The Web source creates three goals at run start; each completed goal grants 10–25 coins and is replaced by a new goal.
- Preserve hero abilities as a separate subsystem: five heroes, level-5 unlock, 45-second cooldown; do not turn them into cards.
- Resolve source inconsistencies explicitly before balancing: Luck has no observed runtime consumer; Comet's local timer check is currently always satisfied; Slow's description and the level-up interval math should be reconciled against intended behavior.

## Not yet implemented in Godot

No card event effects are wired to the native board yet. KT-466 provides the catalog/rank/synergy and encounter foundation only. The next implementation stage is the deterministic event dispatcher and effect-state model, followed by board integration and adversarial tests.
