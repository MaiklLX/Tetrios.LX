# KT-543 — 360-planet catalog audit and chapter authoring matrix

## Status
Read-only audit of the current campaign progression and mechanics definitions. No gameplay changes. Branch `godot/kt493-gallery-validated-2026-11-08`; PR #81 remains Draft/open/unmerged.

## Executive finding
The campaign has a strong structural skeleton, but it is not yet a fully authored 360-level experience. The current progression model generates most node definitions from a bounded formula. This is useful for progression scaffolding and early balancing, but it does not by itself provide 360 distinct reasons to play.

## Exact current mission distribution
The current `get_planet_definition()` rules apply the same local positions in each of 12 universes:

| Mission family | Local nodes per universe | Total nodes |
|---|---:|---:|
| Standard line-clear | 21 | 252 |
| Score-only | 3 (05, 15, 25) | 36 |
| Survival-only | 3 (04, 14, 24) | 36 |
| Boss combo (lines + score) | 3 (10, 20, 30) | 36 |
| **Total** | **30** | **360** |

Every universe currently has three boss milestones. Node 360 is also the final campaign completion milestone and receives an additional mark reward. Ordinary missions use a bounded chapter/local target curve; survival duration also scales by chapter and local section. Bosses have no time limit.

## Current modifier schedule from the data-only registry
The current registry assigns candidate modifiers only from Universe 02 onward:
- Ordinary modifier nodes: local positions 08, 18 and 28 — 3 nodes per universe across 11 universes = 33 nodes.
- Boss modifier pairs: 010 and 020 in each of Universes 02–09 = 16 boss nodes; 030 in Universes 10–12 adds 3 more = 19 paired boss nodes.
- Total scheduled registry assignments: 33 single-modifier nodes + 19 paired boss nodes = 52 nodes carrying 71 modifier entries.
- Universe 01 is intentionally modifier-free for onboarding.
- These are registry assignments and previews, not proof that every modifier has a live gameplay implementation.

Correction to the implementation gate: the six registry candidates (accelerated gravity, rotation limit, clear surge, hazard cells, unstable layout, ability cooldown) are not the same IDs as the six source-audited isolated effect adapters (gravity, gravityFlip, artifactHunt, echoCombo, comet, pulse). There is currently no complete authored mapping connecting these two sets into one playable content schedule. Do not mark the candidate registry as live campaign content until each ID has a tested runtime implementation and an authored briefing.

## Universe-by-universe current content matrix

| Universe | Theme | Current playable identity | Current authored mechanic status |
|---|---|---|---|
| 01 | Green Plains | Introductory standard rules; no registry modifiers | Foundation only |
| 02 | Star Caravan | Cargo Hook authored event on Planet 031 | First special-piece package started; not yet a full chapter arc |
| 03 | Firelands | Formula objectives + candidate registry assignments | Planned |
| 04 | Ice Crown | Formula objectives + candidate registry assignments | Planned |
| 05 | Lunar Colony | Formula objectives + candidate registry assignments | Planned |
| 06 | Expedition Wings | Formula objectives + candidate registry assignments | Planned |
| 07 | Sands of Time | Formula objectives + candidate registry assignments | Planned |
| 08 | Interworld Gates | Formula objectives + candidate registry assignments | Planned |
| 09 | Sky Archipelago | Formula objectives + candidate registry assignments | Planned |
| 10 | Drone Station | Formula objectives + candidate registry assignments | Planned |
| 11 | Cosmic Rift | Formula objectives + candidate registry assignments | Planned |
| 12 | Far Frontier | Formula objectives + candidate registry assignments | Planned |

The registry descriptions are thematic intentions. They must not be presented as already playable mechanics.

## Gaps that matter before release

### 1. Repetition risk
252 of 360 nodes are currently classified as the same standard line-clear family. Their targets vary, but their core interaction does not. Score and survival add useful rhythm, yet the mission schedule repeats identically every universe.

### 2. Authored layouts and deterministic setup
The current planet definition does not yet describe authored starting board layouts, obstacles, hazard placement, special-piece timing, or scripted events. Those need a versioned planet definition and validation layer.

### 3. Mechanic implementation mismatch
The candidate registry and isolated effect adapter use different IDs and rule semantics. A mapping/implementation contract is required before any registry assignment is treated as a live mechanic.

### 4. Universe identity
Only the Star Caravan has a live signature event today (Cargo Hook on Planet 031). The other 11 universe themes are mostly catalog descriptions, not implemented gameplay identities.

### 5. Boss depth
All 36 bosses currently share the same structural boss-combo objective family with stronger quotas and Guardian / Champion / Final labels. The separate boss-session groundwork does not yet establish 12 unique authored encounters with phases, signature rules and individual presentation.

### 6. Rewards
Campaign marks and exactly-once receipts exist and persist. A complete, meaningful reward sink/collection loop is not yet established. Do not imply marks can already buy or unlock content unless the corresponding spend/unlock flow exists.

### 7. Completion presentation
The progression model has a campaign-complete state, but the final player-facing 360th-node finale, universe transitions, chapter story beats and post-campaign destination still need a complete authored presentation.

## Recommended authoring standard for each universe
For each 30-node chapter, use a consistent but varied rhythm:
- 001–003: safe onboarding / mechanic introduction;
- 004: survival or pressure exercise that reinforces the introduced skill;
- 005–007: focused objective variants and practice;
- 008–009: first authored modifier or layout, then mastery;
- 010: Guardian boss;
- 011–013: recovery / mechanic remix;
- 014: survival remix;
- 015–017: score, efficiency or precision challenge;
- 018–019: advanced mechanic use;
- 020: Champion boss;
- 021–023: combined mechanic exercises;
- 024: late-chapter survival test;
- 025–027: special event, score/precision, and mastery;
- 028–029: final modifier/layout and boss preparation;
- 030: universe finale boss.

This rhythm is a template, not a mandate to repeat identical mechanics in all 12 universes. Each chapter's signature mechanic must alter the authored variants and boss design.

## Immediate implementation sequence
1. Create a versioned authored planet-definition schema while retaining formula fallback for unmigrated nodes.
2. Add a static validator that audits every node for objectives, difficulty bounds, mechanic implementation, briefing, special-event preview, reward and boss metadata.
3. Convert Universe 02 into the first complete authored chapter, using Cargo Hook as its signature mechanic and making Planet 031 a deliberate early showcase rather than the only meaningful special event.
4. Build a reusable authored layout/event runner.
5. Only then scale the chapter template and mechanics to the remaining universes.

## Acceptance gates for KT-543
- A deterministic audit enumerates exactly 360 unique IDs and 12 complete chapters.
- Mission-family totals match the distribution above.
- All scheduled modifier assignments are listed and validated; unimplemented assignments are explicitly marked planned/disabled.
- Every boss node is identified, and every universe has a defined signature-mechanic status.
- The report distinguishes implemented, isolated prototype, registry-only, and planned content.
- Existing Classic, Sprint/Marathon and Block Run model contracts remain unchanged.

## Protected boundaries
Campaign-only mechanics stay campaign-only. The unfinished-level rule remains restart-from-beginning; completed progression and marks persist. No main merge, public deployment or APK release.
