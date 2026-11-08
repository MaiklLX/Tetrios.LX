# KT-532 — Daily Challenge source audit and campaign compatibility

- Date: 2026-11-08
- Source: `site/index.html` on development branch, exact `dailyRules` catalog and per-mod gameplay handlers.
- Parent: KT-531.
- Scope: distinguish source-confirmed Daily Challenge mechanics from generic campaign ideas and decide which can be reused safely.

## Source-confirmed catalog (17 rules)
1. `sun` — Solar Resonance: every fourth line grants extra level charge.
2. `gravity` — Quiet Gravity: gravity speed increases every 25 seconds.
3. `gravityFlip` — Gravity Flip: each cleared line accelerates gravity; accumulated acceleration resets every 30 seconds.
4. `glitchReactor` — Glitch Reactor: after every four cleared lines, warn; after two seconds, change board palette for four seconds.
5. `artifactHunt` — Artifact Hunt: every four cleared lines grants an eight-second +50% line-clear score window.
6. `redZone` — Red Zone: top three rows are dangerous after a piece locks; survive 60 seconds, with score bonuses every five seconds.
7. `echoCombo` — Echo Combo: each consecutive line clear adds ×0.25 score multiplier up to ×2.5; locking without a clear resets it.
8. `chronoRift` — Chrono Rift: line clear starts a 20-second countdown; another clear resets it; expiry fails the challenge.
9. `chroma` — Chromatic Storm: palette changes after a line clear.
10. `comet` — Comet Hunt: line clear within two seconds of a piece drop gives bonus score.
11. `mirror` — Mirror Sector: left/right movement is reversed.
12. `pulse` — Core Pulse: every fifth piece falls faster; line clears score ×1.5.
13. `silent` — Relic Silence: next-piece preview is hidden until spawn.
14. `blindAssembly` — Blind Assembly: next-piece preview is hidden until appearance.
15. `prismaticChaos` — Prismatic Chaos: palette changes after every line clear.
16. `lastShield` — Last Shield: first fatal spawn collision is rescued by clearing upper rows.
17. `singularity` — Singularity: periodic short gravity impulses every 20 seconds.

## Compatibility decisions
- Safe early campaign candidates: `gravity`, `gravityFlip`, `artifactHunt`, `echoCombo`, `comet`, `pulse`. They alter tempo or score and can be isolated behind session-local adapters.
- Visual-only candidates: `glitchReactor`, `chroma`, `prismaticChaos`. Palette changes must never change collision IDs or gameplay state.
- High-risk candidates requiring separate design/tests: `redZone`, `chronoRift`, `mirror`, `lastShield`, `singularity`.
- Preview-only candidate: `silent` / `blindAssembly`; preview suppression must not alter piece generation or fairness. Merge as one concept, not two stacked effects.
- `sun` depends on Block Run level-charge semantics and is not directly portable to campaign objectives.
- No source rule is copied into the campaign runtime in this checkpoint. Existing six generic candidates remain non-live until the adapter stage.

## New non-standard pieces
The legacy source defines seven standard tetrominoes only. The new campaign piece family is therefore original Block Buddies design, not a port of a legacy Daily Challenge mechanic. KT-534 must define geometry, rotation states, spawn fit, collision, lock, line clear and preview before enabling it.

## Next
- KT-533: implement isolated, reversible campaign adapters for low-risk effects only, with deterministic session tests.
- KT-534: add first original special piece (candidate: 3-cell satellite/triad or 5-cell cargo shape), behind feature gate.
- Later: visual anomalies, board hazards, movement inversion and survival pressure after dedicated fairness review.

## Safety
No public/main edits, no deployment, no APK build/release, no existing save migration and no live campaign behavior changes.
