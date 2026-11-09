# KT-448 — Adversarial Web profile validation

- Date: 2026-11-08
- Branch: `godot/kt428-buddy-companion-2026-11-07`
- Parent: KT-446 audit and KT-447 read-only parser.
- Status: **ADVERSARIAL VALIDATORS AND FIXTURES PASS / CI SUCCESS**
- Safety: still read-only; no actual import, storage writes, reward settlement or user data access.

## Added validation

Extended `scripts/web_save_migration.gd` to validate known data structures before a candidate profile can be accepted:

- Consumable inventory IDs are restricted to the observed IDs `quick`, `shield`, `magnet`; counts must be non-negative whole numbers.
- Permanent perk IDs are restricted to the observed IDs `heart`, `rainbow`, `lucky`.
- Per-hero campaign perk maps must reference a known hero; perk IDs are restricted to `guardian`, `tactician`, `scout`; ranks must be non-negative whole numbers.
- Equipped cosmetic mappings must use known hero IDs and non-empty string cosmetic IDs.
- Current daily quests require a valid date, a quests array, and quest records with string id/title, positive target, non-negative progress/reward and boolean claimed flag.
- Daily challenge assignment/history records require date-shaped keys and object values.
- Date checks now validate separators, digits, year, month and day ranges.
- A daily reward marker without a matching challenge-history record is preserved but sets `requires_review` and emits a warning. It never grants or repeats a reward.

## New adversarial fixtures

Added cases for:
- unknown consumable ID;
- unknown permanent perk ID;
- campaign perk key referencing an unknown hero;
- malformed/incomplete daily quest record;
- daily reward marker without matching challenge history.

The representative valid daily quest fixture was also corrected to include the full observed fields: id, title, target, progress, reward and claimed.

## CI validation

- Workflow run: `42450599486`
- Head commit: `31b0545a9a7447b3b42c86ee1c1238327009cc16`
- Godot 4.4.1 import: SUCCESS
- Main script parse: SUCCESS
- Gameplay model tests: SUCCESS
- Web migration tests (normal + adversarial fixtures): SUCCESS
- Scene smoke test: SUCCESS

## Remaining limits

This is still a candidate parser, not a production migration. Full field/range parity is not yet established for every historical daily archive, every cosmetic catalog revision, every hero skill state or every mode-specific run state. No profile file format has been committed to disk. Coin conflicts and reward/history discrepancies require a future review UI and explicit user confirmation before any import can occur.

## Next safe work

1. Continue auditing remaining source fields and historical schema drift.
2. Add tests for daily archive trimming, catalog-signature changes and malformed date ranges.
3. Design a review report for conflicting currencies and orphan reward markers.
4. Only then design atomic persistent profile storage, backup/restore and idempotent import.

## Recovery phrase

`BLOCK BUDDIES — KT-448. Adversarial read-only migration validation added for inventory IDs, hero campaign perks, cosmetic equip maps, daily quest schema, challenge date records and orphan reward markers. CI 42450599486 passed on 31b0545a9a7447b3b42c86ee1c1238327009cc16. Still no persistent storage/import. Continue source audit and review UI; do not write user data, touch main, merge, deploy or build APK without approval.`
