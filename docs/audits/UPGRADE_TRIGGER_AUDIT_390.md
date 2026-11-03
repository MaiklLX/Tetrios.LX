# Upgrade trigger audit — 2026-11-03
Base: `site/index.html` at Block Run attack implementation commit `815cd906ea2a92bfdd60f232ab26450d98b19939`.

## Confirmed cards with no gameplay trigger/reference in the current source
These IDs occur in the upgrade catalogue, but a search of their exact upgrade IDs found no `boosts.includes(id)`, `bbGetUpgradeRank(id)`, `bbGetRogueCardRank(id)` or dedicated gameplay trigger:
- `prism` — catalogue says new pieces shimmer in different shades; no card-owned gameplay/render trigger found (hero Prism references are unrelated).
- `stable` — no rotation handling tied to the card.
- `luck` — no rare-piece or score trigger.
- `void` — no field compression trigger.
- `gear` — no every-fifth-turn score trigger.
- `shift` — no rotation bonus trigger.
- `aura` — no card-owned visual aura trigger.
- `plasma` — no drop-delay reset trigger.

These are not to be treated as active effects merely because their catalogue descriptions exist. Do not add more cards until these are implemented or explicitly marked unavailable.

## Active or dedicated implementation paths needing more precise balance/description audit
- `score`, `mult`, `slow`, `resonance`, `magnet`, `glow`, `echo`, `unstable`, `dust`, `burst`, `memory`, `reactor`, `rift`, `infinity`, `tide`, `fortress`, `loop`, `mirror`: direct gameplay checks exist.
- `shield`: dedicated loss-prevention/charge logic exists; not all behavior is expressed through a simple `boosts.includes('shield')` check.
- `armor`: dedicated shield-charge and Fortress-synergy paths exist; no simple `boosts.includes('armor')` check.
- `hold`: dedicated hold-capacity path exists.
- `comet`: fast-level reward path exists, but current reward is fixed at +300; catalogue does not define rank scaling.
- `flash`: line-clear visual trigger exists, but current rank does not scale the effect.
- `neuron`: early-run score multiplier exists, but current rank does not scale the effect.
- `reserve`: dedicated Block Run attack-absorption charge path exists.
- `nova`: dedicated loss-prevention path exists; outside Block Run the current effect is one row, while Block Run rank can scale it.
- `hunter`: dedicated Block Run monster-damage path exists through its card rank.

## Catalogue text mismatches already identified
- `mult` says pieces fall faster as well as score ×1.5; the observed clear-score path applies a score multiplier, while falling speed is not changed by this card.
- `glow` says it gives pieces a soft visual glow; the observed gameplay trigger adds a score multiplier. A visual glow trigger was not found.
- `prism` says pieces shimmer in different shades; no upgrade-owned rendering trigger was found.
- Several cards have fixed effects despite rank-up UI suggesting every card improves with rank (`comet`, `flash`, `neuron`).

## Safe implementation order
1. Add dedicated automated checks that detect these inactive IDs and keep them from being mistaken for implemented effects.
2. Implement each missing effect with clear event ownership and mode gating; keep all roguelike-only effects isolated to Block Run.
3. Align catalogue text and rank descriptions with actual effect formulas.
4. Add deterministic tests for stacking, caps, cooldowns, and trigger frequency.
5. Do not change the 35-card count or remove cards from the pool without a separate user-facing decision/checkpoint.
