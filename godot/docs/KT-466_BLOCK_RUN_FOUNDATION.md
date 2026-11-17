# BLOCK BUDDIES — KT-466
## Block Run Roguelike: source audit and native domain foundation

- Date: 2026-11-08
- Branch: `godot/kt428-buddy-companion-2026-11-07`
- PR: #77, Draft / open / unmerged
- Web source baseline: `main@38c61b606187b88ce8a48a1c6b71d264aecf4258`
- Godot base: `godot/android-native-foundation-2026-11-05`

### Confirmed source contract

- Block Run is a distinct fourth mode; it is not Classic, Sprint, or Marathon.
- The original mode has 35 upgrade cards, ranks capped at five, and three explicit synergies: score+mult, shield+armor, slow+memory.
- Room progression advances the floor every five rooms; every fifth room is a boss.
- Normal enemy HP: `5 + floor*2 + floor(room/2)`; boss HP: `18 + floor*7 + room*2`.
- Normal initial attack delay: `max(23, 34-floor*2)`; boss initial delay: 20 seconds.
- Normal attacks alternate Breach (one row, one hole) and Crossfire (two rows, two holes each). Boss attacks alternate Siege (two rows, one hole each) and Crossfire.
- After an attack, the base interval is `max(17, 34-floor*2)` for normal rooms and `max(12, 20)` for bosses. Chrono Control (slow+memory) subtracts eight seconds before the floor clamp.
- Garbage holes are deterministic from room, attack index, and row index. Reserve cards absorb one complete attack per charge.
- The source creates run goals from four families: lines, score, survival time, and level. Rewards are 10–25.
- Hero abilities are separate from cards and remain tied to the five existing hero identities and their level-5 unlock / 45-second cooldown. Detailed hero action parity remains a later task.

### Implemented in KT-466

- Added `godot/scripts/block_run_model.gd`, a separate run-domain model; it does not alter Classic/Sprint/Marathon board logic.
- Added all 35 source card definitions and the three exact synergy definitions.
- Added room/floor/boss setup, source-matched HP and attack timers, deterministic attack profiles and garbage rows, enemy damage/room advancement, five-rank card drafting, Reserve charge behavior, and deterministic goal construction.
- Added isolated tests covering room 1 / room 5 boss, both attack families, room transition, rank cap, card/synergy behavior, Reserve absorption, Chrono timing, and all four goal types.
- Added a dedicated Godot CI step for the Block Run model suite.

### Explicitly not implemented yet

- No fourth mode selector entry yet: it will be exposed only after the native run loop, card draft UI, encounter HUD, and failure/reward flow are connected.
- Card effects beyond the currently modeled encounter/card rank contracts are not yet ported. The full 35-card trigger/effect map must be audited and implemented event-by-event before the mode is playable.
- Hero active abilities, shield/Nova emergency save interactions, three-goal simultaneous tracking/reward settlement, relic wallet, room clear effects, run-end results and persistence are still pending.
- No save/storage work was performed. No main merge, deploy, APK build/release, or physical-device validation.

### Validation
- Validation: Godot Native Project Check run `42462476795` on HEAD `22ae4ba386fd67c3dde07b9cbcd653a7c0ce8bcd` — **SUCCESS**. Import, main script parse, existing gameplay tests, Web migration tests, dedicated Block Run model tests and scene smoke test all passed.
- CI caught and corrected two issues before acceptance: typed-array construction in the attack-cycle selector, and a Crossfire fixture that expected one row instead of the source-defined two. The final run passed after both corrections.
