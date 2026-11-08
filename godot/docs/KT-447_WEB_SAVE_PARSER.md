# KT-447 — Read-only Web save migration parser and regression fixtures

- Date: 2026-11-08
- Branch: `godot/kt428-buddy-companion-2026-11-07`
- Parent audit: KT-446, `SAVE_MIGRATION_CONTRACT.md`
- Status: **READ-ONLY PARSER IMPLEMENTED / FIXTURES PASS / CI SUCCESS**
- Safety: parser has no filesystem writes, no `user://` access, no Web/localStorage access, and no reward-settlement behavior.

## Implementation

Added `godot/scripts/web_save_migration.gd` as a pure parser. It accepts a Dictionary snapshot of Web localStorage key/value pairs and returns:

- `ok`: whether the candidate can be imported without structural errors.
- `requires_review`: whether a conflict needs explicit reconciliation.
- `errors`, `warnings`, and `conflicts`.
- `unknown_keys`: unrecognized keys are surfaced, never silently imported.
- `source_backup`: deep copy of every original key/value pair.
- `profile`: candidate native profile sections for currencies, campaign, heroes, inventory, cosmetics, daily state, stats and settings.

No mutation is made to the input dictionary. The parser does not write or delete anything.

## Conservative handling rules

1. `bb_coins` is authoritative when present because that is the key loaded by the Web runtime. Divergent `coins` / `bbCoins` aliases are recorded as conflicts and set `requires_review`; the raw source is retained.
2. If `bb_coins` is absent, matching aliases can be used. Divergent legacy aliases block the candidate rather than guessing.
3. Plush legacy XP/level aliases are fallback-only when per-hero values are absent.
4. Campaign marks and relics remain separate balances.
5. Per-hero campaign perks and hero progression remain scoped by hero ID.
6. Daily reward markers are imported as markers only; no reward is granted. Malformed markers block import.
7. Legacy single-slot cosmetic equip maps to the selected hero only when the per-hero map is absent.
8. Unknown keys remain in the backup and are listed for review.
9. Malformed JSON or invalid typed fields mark the candidate invalid; no partial disk write or model mutation is possible because this module has no persistence integration.

## Fixtures

Added `godot/tests/fixtures/web_save_profiles.json` with:
- empty/default profile;
- representative profile containing currencies, heroes, perks, inventory, cosmetics, campaign, daily state and stats;
- primary wallet with conflicting legacy alias;
- conflicting aliases without primary wallet;
- malformed JSON;
- legacy Plush progression and single-slot cosmetic fallback;
- unknown key preservation;
- malformed daily reward marker.

The dedicated `web_save_migration_test.gd` suite exercises these fixtures, including input immutability and preservation of the raw source backup. It runs as a separate CI step from gameplay-model tests.

Godot's JSON parser represents numeric JSON values as integral floats in some paths. The validator accepts only finite whole-number floats (as well as integer strings for raw localStorage aliases), then normalizes them to integers in the candidate. Fractional and malformed values remain rejected. The legacy single-slot cosmetic fallback is applied when the default per-hero map is empty; the original key remains in the source backup.

## Not included / gates remain

- No persistent profile save file.
- No atomic write/backup rotation.
- No import execution or automatic migration.
- No reward payout or settlement.
- No Web code changes, main-branch writes, deployment, APK build, or physical Android validation.
- This is not yet a full proof of every Web key/value range; it is the first parser slice with representative fixtures. Additional field-specific validators and date/schema constraints remain before production migration.

## CI validation

- Workflow run: `42450365090`
- Commit: `55e0a8701b97c5b3e45dbcf7576d8d8417504b1c`
- Godot 4.4.1 import: SUCCESS
- Main script parse: SUCCESS
- Gameplay model tests: SUCCESS
- Web save migration fixture tests: SUCCESS
- Scene smoke test: SUCCESS

## Next

1. Add adversarial fixtures for malformed hero maps, invalid perk IDs, daily quest shape drift, reward-marker/history disagreement and unsupported future native versions.
2. Decide an explicit review UX for coin conflicts before any import can be confirmed.
3. Only after those tests pass, design atomic profile storage and backup recovery as a separate milestone.

## Recovery phrase

`BLOCK BUDDIES — KT-447. Read-only parser in godot/scripts/web_save_migration.gd; fixtures in godot/tests/fixtures/web_save_profiles.json. Parser accepts a localStorage snapshot, preserves source_backup, reports unknown keys and coin alias conflicts, and never writes storage or grants rewards. CI run 42450365090 passed on 55e0a8701b97c5b3e45dbcf7576d8d8417504b1c. Continue with adversarial fixtures; do not enable disk writes/import or touch main/deploy/build APK without approval.`
