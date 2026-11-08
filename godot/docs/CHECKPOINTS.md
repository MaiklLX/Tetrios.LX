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
