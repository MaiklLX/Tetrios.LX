# Godot migration checkpoints

## KT-GODOT-002.1 — CI failure diagnosis and repair
- Date: 2026-11-06
- Branch: `godot/android-native-foundation-2026-11-05`
- Previous head inspected: `05149289b089b86e557e6bd7b8b0b159545ef80e`.
- GitHub Actions run #12 reached project import successfully, but the log exposed three GDScript type-inference errors in `godot/scripts/main.gd` (layout width/offset and control label), plus an invalid untyped-array assignment into `Array[Vector2i]` in `game_model.gd`.
- The model test then stopped at its first assertion without calling `quit()`; the runner eventually cancelled the job at its 15-minute limit. This was a test-harness hang after a real assertion failure, not evidence of a successful test run.
- Repair commits: `4ca0a48c994e3fe5b9de93a8f2824cec98d1320f` (explicit UI types), `34ea244f884ae5d49a253512af06a0510bc7c5ec` (typed-array assignment), `0ec1c6b2b0202289814866c1aa17c1cc0257f723` (seeded, fail-fast model tests), `146ee5cb892459ea7464c906e5de02bd99ea5f3d` (script parse check and test-step timeout).
- Validation status: **PASS** — GitHub Actions run #19 (`42210305113`) on commit `88d8437fe0362350f9e8b9df75cdf2826f15a26c` completed successfully on 2026-11-06. Godot 4.4.1 project import, explicit `main.gd` parse check, seeded model tests, and headless scene smoke test all passed. The test output confirmed the 10×23 board, seven-bag, spawn centering, movement, rotation, and single-line clear. This is a green technical foundation check, not full legacy gameplay parity.
- No APK built. No changes to `main` or the existing web implementation. The gameplay board remains 2D; no 3D arena was introduced.

## KT-GODOT-001 — Foundation established
- Date: 2026-11-05
- Branch: `godot/android-native-foundation-2026-11-05`
- Commit: `489e9624c8c349cd2d754436895f291c146cd84f`
- Status: **PASS — initial engine smoke test**
- Godot: 4.4.1
- Verified in GitHub Actions: project import and headless scene launch both passed.
- Included: portrait-first project settings, Compatibility renderer, 10×20 board model, seven tetromino definitions, movement, rotation with basic wall kicks, gravity, soft/hard drop, line clear, score/level, and touch/keyboard prototype controls.
- Not included yet: final 3D Buddy models, final UI, all legacy modes, existing progression/rewards, persistence, Android export/signing.
- No APK built. No changes to `main` or the existing web game.

## KT-GODOT-001.1 — Deterministic model checks
- Added CI checks for board dimensions, all seven four-cell tetromino definitions, seven-bag completeness and boundary, spawn centering, movement, rotation, and a deterministic single-line clear fixture.
- Passed in Godot Native Project Check run #19 on 2026-11-06.
- This is an initial regression suite only; the broader parity fixtures in `PARITY_MATRIX.md` remain open.

## KT-GODOT-002 — Source parity audit
- Inventory current source game modes, rules, timers, objectives, rewards, hero identities, progression, and save data.
- Build a parity matrix with references to source files and test fixtures.
- Do not silently simplify or invent legacy rules.

## Control phrase for a new chat
`BLOCK BUDDIES GODOT — KT-GODOT-001.1. Продолжаем нативную Android-версию в ветке godot/android-native-foundation-2026-11-05. main не трогать, старую игру не ломать, APK пока не собирать. Сначала проверить Godot CI и детерминированные тесты, затем провести полный аудит исходных режимов и начать визуальную сцену с 3D Buddy.`


## KT-GODOT-001.2 — Legacy board dimensions and tetromino identity
- Date: 2026-11-05
- Source baseline: `main@8fc2b889524d3dcaf87439efe57aa74dc68e1042`
- Godot branch: `godot/android-native-foundation-2026-11-05`
- Corrected the native board from 10×20 to the source game's 10×23.
- Reordered the seven tetromino definitions to source order I/T/J/L/O/S/Z.
- Matched the seven source piece colors.
- Updated deterministic model fixture and board layout sizing.
- Source parity audit started in `godot/docs/PARITY_MATRIX.md`; still in progress. Score, rotation, randomizer, timers, Hold, mode progression, rewards and persistence are not yet parity-approved.
- No APK built. No change to `main`.



## KT-446 — Web save audit and migration contract
- Date: 2026-11-08
- Branch: `godot/kt428-buddy-companion-2026-11-07`
- Read-only Web source baseline: `main@38c61b606187b88ce8a48a1c6b71d264aecf4258` (`site/index.html`).
- Added `godot/docs/SAVE_MIGRATION_CONTRACT.md` with the actual localStorage key inventory, helper-expanded key names, sampled record shapes, legacy aliases, daily reward markers, transient-vs-durable state split, reset-flow warning, proposed versioned native profile/run documents, migration precedence and 12 required regression fixtures.
- Extended `godot/docs/PARITY_MATRIX.md` with the detailed audit reference and important corrections.
- Key finding: the live Web wallet is loaded from helper key `bb_coins`; direct aliases `coins` and `bbCoins` are not consistently synchronized. Migration must detect conflicts and must never add these values together.
- Campaign marks (`bbCampaignMarks`) and Block Run relics (`nrRelics`) are separate currencies. Hero XP/levels and campaign perks are per hero. Daily challenge assignments, history, completion, replay, quest archive, reward markers and visit streak are distinct records.
- The actual campaign-perk helper key is `bb_bbCampaignPerks_<heroId>`, since `bbPut()` adds the `bb_` prefix.
- KT-445 remains an in-memory run snapshot only. No Godot disk persistence, autosave, Web import, cloud sync or Android device test is included in this checkpoint.
- Status: **source audit + proposed contract complete; implementation pending**. Next safe step is pure migration fixtures and a read-only parser/validator. Atomic disk writes remain gated until conflict and recovery tests pass.
- No writes to `main`, no deployment, no merge, no APK build, no user-data reset or modification.


## KT-447 — Read-only Web save parser and regression fixtures
- Date: 2026-11-08
- Added `godot/scripts/web_save_migration.gd`: pure read-only parser for a supplied localStorage snapshot. It returns a candidate profile, validation errors/warnings, coin alias conflicts, unknown keys and a deep raw source backup. It does not access localStorage, files, `user://`, or grant rewards.
- Added representative fixtures in `godot/tests/fixtures/web_save_profiles.json` and isolated regression suite `godot/tests/web_save_migration_test.gd`; CI now runs it as a distinct step.
- Covered empty profile, full representative profile, matching and conflicting coin aliases, conflict without primary wallet, malformed JSON, legacy Plush XP/level, legacy single-slot cosmetic fallback, unknown-key retention, daily reward marker retention/malformed marker, and input immutability.
- Parser accepts finite whole-number JSON numeric values (Godot may decode integer JSON numbers as floats) and normalizes them to integers. Fractional values remain invalid. Fixed legacy cosmetic fallback so it is used when the default per-hero equip map is empty.
- Validation: workflow run `42450365090`, commit `55e0a8701b97c5b3e45dbcf7576d8d8417504b1c` — Godot import, main script parse, gameplay model tests, Web migration fixture tests and scene smoke test all **SUCCESS**.
- Earlier test attempts caught real issues: strict JSON integer typing, test-suite indentation, and a legacy cosmetic fallback condition. Those were corrected before the successful run. No production save data was accessed or changed.
- Still not implemented: persistent storage, atomic writes, backup rotation, actual Web import, reward settlement, cloud sync or physical Android verification. Continue adversarial fixtures and conflict-review design before any storage integration.
- No edits to `main`, no merge, deployment, APK build or release.


## KT-448 — adversarial migration validation
- Extended `web_save_migration.gd` to validate consumable IDs/counts, permanent perk IDs, hero-scoped campaign perk IDs/ranks, equipped cosmetic hero mappings, current daily quest schema, challenge date records and date ranges.
- A daily reward marker with no matching challenge-history entry is retained but sets `requires_review`; no reward is granted. This avoids silently discarding ambiguous history.
- Added adversarial fixtures for unknown consumables/perks/heroes, incomplete daily quest records and orphan reward markers. Corrected the representative daily quest fixture to include all observed fields.
- Added `godot/docs/KT-448_ADVERSARIAL_MIGRATION_VALIDATION.md`.
- CI workflow run `42450599486` on HEAD `31b0545a9a7447b3b42c86ee1c1238327009cc16`: import, parse, gameplay tests, migration tests and scene smoke test all **SUCCESS**.
- Remaining gaps: historical daily archive and catalog-signature drift, full cosmetic catalog validation, hero skill state, mode-specific interrupted runs, and review UI. No persistent storage or actual import is enabled.
- No main edits, merge, deployment, APK build or user-data modification.


## KT-449 — Daily archive and calendar-date audit
- Date: 2026-11-08
- Branch: `godot/kt428-buddy-companion-2026-11-07`
- Added strict validation for actual Web daily quest archive records: date key, matching embedded date, quest array and complete quest fields.
- Date validation now rejects impossible Gregorian dates, including non-leap-year February 29.
- Archive entries above 90 are retained in full with a warning; import does not reproduce the Web save-time trim.
- Catalog signature is preserved byte-for-byte as an opaque source string. It is not recalculated and does not trigger assignment/history deletion in the native migration parser.
- Added malformed archive/date fixtures and a 91-entry no-trim regression test.
- Parser remains pure/read-only. No storage writes, rewards, cloud sync, main edits, merge, deployment or APK build.


## KT-465 — Three-mode selector layout and Marathon regression QA
- Date: 2026-11-08
- Branch: `godot/kt428-buddy-companion-2026-11-07`; PR #77 remains Draft/open.
- Corrected the three-card mode selector vertical spacing: title and subtitle now clear the first card; card hitboxes remain distinct; instructions clear the Marathon card.
- Extracted responsive mode-card geometry into `_mode_select_layout(viewport)` and added geometry assertions at 360×800, 375×812, 412×915 and 720×1280.
- Generalized the objective progress helper name so it no longer implies Sprint-only behavior.
- Added Marathon failure-path checks: game over at 99/100 lines, correct `MARATHON FAILED` title, 99/100 progress and elapsed-time display; added card-tap launch coverage.
- Validation: Godot Native Project Check run `42461758390` on code HEAD `ede9fdcb1124dfa6d75e0316e0bc477aa7ac3bbe` — import, main script parse, gameplay/model tests, Web migration tests and scene smoke test all **SUCCESS**.
- The prior intermediate CI attempts exposed a type annotation omission, a stale local variable name and a test setup issue; each was corrected before the successful run above.
- No changes to `main` or the Web game; no merge, deployment, APK build/release, persistence integration or user-data modification. Physical Android runtime remains unverified.


## KT-466 — Block Run Roguelike native domain foundation
- Date: 2026-11-08; branch `godot/kt428-buddy-companion-2026-11-07`; PR #77 remains Draft/open and unmerged.
- Audited original Web source at `main@38c61b606187b88ce8a48a1c6b71d264aecf4258`.
- Added isolated `block_run_model.gd`: 35 card definitions, three source synergies, room/floor/boss progression, source-matched enemy HP, attack cycles/timers, deterministic garbage patterns, enemy damage and room transition, five-rank card drafting, Reserve charges and four goal families.
- Added `block_run_model_test.gd` and a dedicated CI step. Tests cover room 1, room 5 boss, Breach/Crossfire/Siege patterns, deterministic garbage rows, room transitions, rank cap, score+mult and slow+memory synergies, Reserve absorption, Chrono timing and all goal types.
- CI run `42462476795` on HEAD `22ae4ba386fd67c3dde07b9cbcd653a7c0ce8bcd`: **SUCCESS** — import, main parse, gameplay tests, migration tests, Block Run model tests and scene smoke test.
- The mode is not yet selectable/playable: encounter HUD, board integration, all 35 card event effects, three simultaneous goals/reward settlement, five hero abilities, relic economy and run-end flow remain next stages.
- No save/storage work, main changes, merge, deployment, APK build/release or physical-device test.


## KT-467 — Block Run card event/effect audit
- Audited all 35 card IDs against the legacy Web runtime paths: piece lock, line clear, timer tick, level-up, spawn collision, rotation, render, monster attack and monster defeat.
- Added `godot/docs/KT-467_BLOCK_RUN_CARD_EVENT_MAP.md` with the observed trigger/effect for every card and the three exact synergies.
- Identified two source discrepancies that must not be silently copied as design intent: Luck has no observed runtime consumer in the audited source, and Comet's local timer check is assigned immediately before use, making its under-35-second condition effectively always true. Slow's prose description also needs reconciliation with its actual level-up interval math.
- Defined the event dispatcher contract for KT-468: piece lock, line clear, timer second, level-up, spawn collision, rotation, monster attack and monster defeat. Random outcomes must be deterministic in tests.
- No native card effects have been wired yet; this checkpoint is an audit gate before implementation.
- No main merge, deployment, APK build/release, persistence or user-data changes.


## KT-468 — Deterministic Block Run card event effects
- Added `godot/scripts/block_run_effects.gd`: pure deterministic event calculations for card draft, piece lock, line clear, timer second, level-up, rotation, piece spawn, spawn collision and monster defeat.
- Implemented source-grounded effects for scoring/multipliers, line/monster damage, level charge, relic gain, Flash/Plasma, Tide/Unstable, Memory/Loop/Slow/Fortress, Stable/Shift, Mirror/Prism/Aura, Shield/Armor/Nova/Rift, Gear, Reserve and Hold. Comet is gated for source-bug review; Luck remains unimplemented because no runtime consumer was found.
- Preserved Pixel's hero-specific Hold override and exact Shield/Iron Fortress rescue geometry.
- Added `godot/tests/block_run_effects_test.gd` and a dedicated CI step.
- CI run `42462909799` on HEAD `cdf419b0f73eddc71f12e88aee4578a6f9edffd0`: **SUCCESS** — import, parse, gameplay, migration, Block Run model, Block Run event-effect tests and scene smoke test.
- The effect layer is still isolated and not connected to the live board. Board mutations, active run integration, goals/rewards, hero abilities, relic wallet, HUD/draft/result UI and responsive QA remain pending.
- No storage work, main merge, deployment, APK build/release or physical-device test.


## KT-469 — Block Run board mutation adapter
- Added `godot/scripts/block_run_board.gd`: validated 10×23 board mutations for deterministic garbage insertion, top-out reporting, bottom-row clearing and rescue-row patterns.
- Added `godot/tests/block_run_board_test.gd` and CI stage `Run Block Run board mutation tests`.
- CI run `42463302261` on HEAD `5dcecbf891c9ac098ae86f0d36bcfbc4fc6b48ad`: **SUCCESS** — import, parse, gameplay, migration, Block Run model/effect/board tests and scene smoke test all passed.
- This is an isolated adapter and is not yet wired into the live main scene or piece-lock loop. Next: connect attacks/rescues to the active board, then goals/rewards, hero skills and encounter/draft UI.
- PR #77 remains Draft/open/unmerged. No main merge, deployment, APK build/release, persistence or physical-device test.


## KT-470 — Block Run encounter/session integration
- Added `godot/scripts/block_run_session.gd`, composing encounter model, deterministic card effects and board adapter.
- Session now routes card drafts, placement bonuses, line-clear scoring/damage, relics, timer events, enemy attack countdown, garbage insertion, Reserve absorption, top-out failure and Rift room-clear effect.
- Added `godot/tests/block_run_session_test.gd` and CI stage `Run Block Run session integration tests`.
- CI run `42463408749` (#143) on HEAD `6b8bd27f280ef2eabaf4ef0e90457535557af18a`: **SUCCESS** — import, parse, gameplay, migration, Block Run model/effects/board/session tests and scene smoke test all passed.
- Session coordinator is not yet connected to `main.gd`; Block Run remains hidden and is not yet playable. Shield/Nova rescue, three live goals/rewards, hero abilities, draft/encounter HUD and run-end UI remain.
- PR #77 remains Draft/open/unmerged. No main merge, deployment, APK build/release, persistence or physical-device test.


## KT-471 — Three live Block Run goals and reward replacement
- Date: 2026-11-08; branch `godot/kt428-buddy-companion-2026-11-07`; PR #77 remains Draft/open and unmerged.
- Extended `block_run_session.gd` to create exactly three active goals at run start, using the four source goal families: lines, score, survive time and level.
- Goal targets and rewards use the source formulas from `bbCreateRogueGoal()`: +3–6 lines, +400–1000 score, +15–35 seconds, +1–2 levels, and 10–25 coins.
- Added live goal-state snapshots and completion events. A completed goal emits a single reward event and is immediately replaced in the same slot with a new goal based on current run progress.
- Goal checks are routed after piece-lock score, line-clear score/progress and one-second timer updates. Reward totals remain run-local events; no persistent wallet or save storage is changed yet. The eventual scene/profile integration must consume each event once and credit the existing coin system exactly once.
- Regression coverage: exactly three initial goals, unique active IDs, reward/target ranges, line-goal completion/replacement, survive-goal timer completion, score-goal completion, and existing combat/attack/Reserve/top-out behavior.
- CI run `42467057040` on code HEAD `d4c230d3695c785bbc0c32d0298bf9d615535bdd`: **SUCCESS** — gameplay, migration, Block Run model/effects/board/session tests, real rendered screenshot capture, artifact upload and scene smoke test.
- Real screenshot artifact: `block-buddies-visual-checks` (selector + Classic arena, 720×1280); available from GitHub Actions run `42467057040`.
- Remaining: connect session to `main.gd` and the real board/piece lifecycle; wire exact Shield/Nova rescue mutations; then add hero skills, card draft, encounter/goals HUD, reward settlement and run-end UI. Block Run remains hidden and not playable until these are complete.
- No main merge, deployment, APK build/release, persistence work or physical-device test.


## KT-472 — Five source-matched Block Run hero abilities
- Date: 2026-11-08; branch `godot/kt428-buddy-companion-2026-11-07`; PR #77 remains Draft/open and unmerged.
- Added `use_hero_skill(hero_id, hero_level)` to the isolated Block Run session. All five legacy hero branches are represented: Captain Plush clears the top `2 + tier` rows; Prism deals `8 + tier × 5` enemy damage; Blip delays the next attack by `12 + tier × 4` seconds; Pixel clears `tier` bottom rows and adds the same level charge; Spark deals `12 + tier × 5` enemy damage.
- Hero ability tier follows the source formula `1 + floor((level - 5) / 5)`; skills are locked below level 5 and share a 45-second run-time cooldown. Cooldown advances only with active run seconds.
- Prism/Spark enemy defeat applies the already implemented Rift effect when drafted. Ability mutations remain run-local; no persistent XP, wallet, or save data is touched.
- Regression coverage includes all five heroes, level-4 lockout, level-10 tier scaling, attack delay, board mutations, enemy damage, and cooldown rejection/countdown.
- CI run [42467652778](https://github.com/MaiklLX/Tetrios.LX/actions/runs/42467652778) on code HEAD `0ce7ed5fba9a30bebeef406375612283317a7598`: **SUCCESS** — import, main parse, gameplay, migration, Block Run model/effect/board/session tests, rendered screenshot capture/upload and scene smoke test.
- Real rendered screenshot artifact: `block-buddies-visual-checks`, 720×1280 selector and Classic arena. These screenshots confirm existing scenes render; they do not depict Block Run, which is still not connected to the main scene.
- Remaining: connect session to the live piece/board lifecycle; integrate Shield/Nova rescue mutations; build card draft, encounter/goals HUD, reward settlement and run-end UI. Block Run remains hidden and not playable.
- No main merge, deployment, APK build/release, persistence work or physical-device test.


## KT-473 — Block Run Shield / Iron Fortress / Nova rescue mutations
- Date: 2026-11-08; branch `godot/kt428-buddy-companion-2026-11-07`; PR #77 remains Draft/open.
- Added session-level `on_spawn_collision()` that applies the existing source effect decision and mutates the isolated 10×23 Block Run board.
- Shield consumes one charge and randomizes the source-defined lower 3 rows at 22% fill; Shield + Armor (Iron Fortress) randomizes lower 5 rows at 10% fill. The mutation uses a deterministic run seed for reproducible tests.
- Nova clears its rank-scaled number of bottom rows and marks the one-time rescue as consumed. A second spawn collision cannot reuse Nova.
- Added regression coverage for charge consumption, board mutation, Iron Fortress combination, Nova row clearing and one-time use.
- First test attempt exposed a GDScript static type inference issue in a test fixture; explicit typing fixed it. Final CI run [42468010685](https://github.com/MaiklLX/Tetrios.LX/actions/runs/42468010685) on HEAD `d79a40dc78d112f5ea6b077ac3b24e278687c816`: **SUCCESS** — import, main parse, gameplay, migration, Block Run model/effects/board/session tests, rendered screenshot capture/upload and scene smoke test.
- Real rendered screenshot artifact: `block-buddies-visual-checks`, 720×1280; current Classic arena screenshot is also available in the run artifacts. It confirms existing Classic rendering only; it is not a Block Run screen.
- Status boundary: rescue logic is implemented and tested inside the Block Run session. It is not yet called from the live game model or main scene. Block Run remains hidden/unplayable until the live board/piece lifecycle, draft/HUD and run-end flow are integrated.
- No main merge, deployment, APK build/release, persistent storage changes or physical Android test.
