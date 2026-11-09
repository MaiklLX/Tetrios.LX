# KT-542 — Campaign completion master plan

## Status
Planning checkpoint created on the Godot development branch. This is a content-and-systems completion plan, not a claim that all 360 planets are already individually authored. PR #81 remains Draft/open/unmerged. No main merge, public deployment, or APK release.

## Product decision
The Cosmic Campaign is a core pillar of Block Buddies, not a temporary mode or a decorative 360-node map. The campaign should be worth playing from Planet 001 through Planet 360 before public release. We are not optimizing for the earliest possible release date; campaign completeness and player retention come first.

## Verified current foundation
- 12 universes and 360 sequentially unlocked planet nodes exist in the progression model.
- Planet definitions currently derive most mission targets from a bounded formula. Mission families include line-clear, score-only, survival, and combined boss objectives.
- Every tenth planet is currently a boss gate; the existing milestone labels are Guardian / Champion / Final.
- A data-only universe-mechanics registry exists for 12 thematic families. Most entries are explicitly marked planned; this is a catalog, not 12 fully playable universe mechanics.
- Six candidate campaign modifiers exist in a registry, but are not yet a complete authored/live content set.
- An isolated effect adapter supports six audited rule effects, but it is not yet a fully authored 360-planet modifier schedule.
- The five-cell Cargo Hook is integrated as an authored first-piece event on Planet 031 through a campaign-owned runtime. It is intentionally excluded from Classic, Sprint/Marathon and Block Run.
- Campaign progression, completion receipts, marks and save storage exist. Exiting/relaunching an unfinished level starts that level over; completed progression and rewards persist.
- Automated Godot CI validates the current branch. Physical Android/iOS playtesting and release packaging remain outstanding.

## Release definition for a complete campaign
A campaign is content-complete only when:
1. All 12 universes have a distinct identity, mechanic introduction, visual language, mission rhythm and boss finale.
2. All 360 nodes have authored or deliberately composed mission definitions. A formula may assist balancing, but must not be the only source of variety.
3. Every mechanic is taught safely before it is tested under pressure. No surprise rule changes, invisible hazards or unfair random failures.
4. Each universe introduces a small number of mechanics, revisits them in varied combinations, and ends with a memorable boss encounter.
5. Special pieces, hazards, obstacles and character abilities have clear previews, readable telegraphs, predictable rules and campaign-only isolation.
6. The campaign has a satisfying opening, chapter transitions, escalating mastery, a final universe and a proper completion/credits/reward sequence.
7. Rewards have a clear purpose and a persistent, validated claim path. No UI may imply that a reward has been credited when it has not.
8. Every mission can be completed, failed, retried and exited without corrupting progression or duplicating rewards.
9. Difficulty, mission duration, special-piece frequency and modifier combinations are playtested across early, middle and late campaign.
10. All campaign content is covered by deterministic tests, visual captures and full playthrough checkpoints; then verified on real phones.

## Campaign content architecture

### A. Planet definition
Move from implicit formula-only mission construction toward a versioned authored definition assembled from:
- stable planet ID and universe/chapter ID;
- mission family and explicit objective parameters;
- authored board seed/layout where applicable;
- primary mechanic and optional compatible secondary modifier;
- special-piece event schedule (never a random insertion into the standard bag);
- character ability rules/cooldown;
- difficulty budget and expected duration band;
- reward marks and optional cosmetic/collection reward;
- tutorial hint / pre-run briefing / in-run telegraph;
- completion, failure and retry presentation metadata.

Formula-generated targets remain a balancing fallback, not a replacement for authored design.

### B. Universe identity and mechanic rollout
Each universe must receive a fully playable signature mechanic, with this progression:
- safe introduction and visual explanation;
- low-pressure practice;
- focused mastery missions;
- combinations with previously learned mechanics;
- a boss that tests the mechanic fairly;
- a short transition that previews the next universe.

The 12 current themes remain the starting creative direction: Green Plains, Star Caravan, Firelands, Ice Crown, Lunar Colony, Expedition Wings, Sands of Time, Interworld Gates, Sky Archipelago, Drone Station, Cosmic Rift and Far Frontier. Names and themes can be refined, but each must map to real gameplay.

### C. Mission rhythm
Use a deliberate chapter rhythm rather than repeating the same objective every few nodes:
- onboarding / safe practice;
- focused skill test;
- score or efficiency challenge;
- survival / endurance challenge;
- authored board or special-piece event;
- mechanic combination;
- optional mastery challenge;
- boss milestone at nodes 010 / 020 / 030.

The current line, score and survival families are retained, but each chapter should add authored variants and environmental objectives. Boss nodes remain untimed unless a specific timer is taught and justified.

### D. Special content
- Cargo Hook remains the first approved special piece, authored on Planet 031.
- Additional special pieces require their own silhouettes, rotation/fit contracts, previews, Hold tests, and authored planet placements.
- Hazards and obstacles must be visible before launch and remain deterministic.
- Visual-only effects must never change collision or gameplay identity.
- One Touch-style precision challenges remain optional challenge content, not a hidden timer imposed on normal campaign missions.

### E. Boss encounters
The current boss flag and stronger quotas are only the structural start. Each universe needs a recognizable boss identity and encounter flow:
- briefing / arena preview;
- one signature mechanic with clear tells;
- multi-step objective or phases, without unfair randomness;
- boss-specific HUD and progress language;
- victory and failure presentation;
- reward summary and route transition.
Bosses must be beatable with the standard piece set unless the level briefing explicitly previews an authored special event.

### F. Rewards and long-term motivation
Campaign marks remain the progression currency foundation. Before release, define and wire their real sinks (for example, Buddy cosmetics, universe decorations, profile badges or campaign collection items). Keep cosmetic rewards non-pay-to-win. Ensure earned marks and receipts persist, prevent duplicate claims, and display only confirmed balances. Do not invent a second currency unless a concrete need emerges.

## Staged delivery gates

### KT-543 — authored campaign catalog and validation
- Introduce a versioned planet-definition schema and a catalog validator.
- Audit all 360 generated definitions; report counts by mission family, mechanic, special event and reward.
- Identify repeated or empty stretches and create a chapter-by-chapter authoring matrix.
- Add invariants: every node reachable, every mechanic referenced only when implemented, every modifier set compatible, every special event previewed, boss gates present exactly where intended.
- No live gameplay behavior changes in this gate.

### KT-544 — universe mechanic 01: Star Caravan
- Turn the existing Planet 031 Cargo Hook event into the first complete universe-specific mechanic package.
- Add safe introduction, practice, mastery, and a boss encounter that uses the mechanic.
- Add briefing copy, visual language and tests; keep the mechanic campaign-only.
- Do not expand to multiple new special pieces until this package is fun and stable.

### KT-545 — campaign mission variety and authored layouts
- Implement a reusable authored mission runner for deterministic starting layouts, objectives and optional rules.
- Build the first complete chapter's varied sequence and test its pacing.
- Keep the current generated target formula as a fallback during migration.

### KT-546 — boss encounter framework
- Add reusable boss phases, presentation states, distinct objective feedback, victory/failure flow and replay tests.
- Author one fully playable boss for Universe 01 before scaling the framework to all universes.

### KT-547 — reward sinks and collection loop
- Define a focused, non-pay-to-win use for campaign marks.
- Wire persistent unlock/claim receipts and clear earned/spendable balance semantics.
- Keep rewards separate from Block Run's run-goal receipts until the shared profile is deliberately designed.

### KT-548 — universe-by-universe content production
- Complete the remaining 11 universe mechanics in a controlled order.
- Author mission schedules, special events, boss identities, transitions and rewards.
- Add campaign visual captures and deterministic playthrough checks for each chapter.

### KT-549 — full-campaign balance and release acceptance
- Simulate and playtest early/mid/late campaign progression.
- Tune difficulty, mission length, reward pacing and mechanic frequency.
- Run a complete 001→360 progression audit, save/restart/retry/reward regression and real-device QA.
- Only after acceptance should the campaign be considered release-complete.

## Non-goals / protected boundaries
- Do not add campaign modifiers or special pieces to Classic, Sprint/Marathon or Block Run.
- Do not add automatic resume of unfinished levels; exiting a level restarts that attempt.
- Do not rush to publish the campaign while large stretches are still formulaic or placeholder-like.
- Do not merge PR #81, deploy publicly or release an APK without explicit user approval.

## Immediate next action
KT-543: inspect the actual 360-node catalog and produce a data-backed audit plus chapter authoring matrix. This should reveal exactly where the campaign is repetitive, which mechanics are only planned, and what must be built before content production can scale.
