# KT-449 — Daily archive and calendar-date audit

- Date: 2026-11-08
- Branch: `godot/kt428-buddy-companion-2026-11-07`
- Web source baseline: `main@38c61b606187b88ce8a48a1c6b71d264aecf4258`.
- Scope: read-only inspection of the existing Web daily quest archive and challenge date handling; no Web source changes.

## Confirmed Web behavior

- `bbDailyArchive` is a JSON object keyed by local calendar date (`YYYY-MM-DD`).
- Each saved archive entry is written by `bbSaveDailyQuests()` as `{ date, quests }`; each quest contains `id`, `title`, `target`, `progress`, `reward`, and `claimed`.
- The Web archive is trimmed to the latest 90 lexicographically sorted date keys only when `bbSaveDailyArchive()` runs. Loading alone does not trim it.
- The challenge catalog signature is stored as the exact `JSON.stringify()` output of the daily rule descriptors (`title`, `symbol`, `desc`, `goal`, `rule`, `mod`). When it differs from the current Web catalog, only `bbDailyChallengeAssignments` is removed. Challenge history and reward markers are not cleared.
- Completed challenge history takes precedence over generated assignments for that date. Existing assignment records are reused while the catalog signature remains unchanged.
- Daily reward markers, challenge history, current quest set, and historical quest archive are distinct state. Migration does not settle rewards or regenerate dates.

## KT-449 implementation

- The pure parser now validates archive date keys, matching embedded `date`, and each historical quest record.
- Calendar dates are checked against month lengths and Gregorian leap-year rules; impossible dates such as `2026-02-29` are rejected.
- Archives over 90 entries are preserved in full and surfaced with a warning. Migration deliberately does not apply the Web save-time trim, because that would silently destroy user history during import.
- Catalog signature remains an opaque source string and is copied unchanged. Godot must not compare it against a newly authored catalog or regenerate past assignments until a separately versioned daily catalog compatibility plan exists.
- Added adversarial fixtures for mismatched archive dates and impossible calendar dates, plus a 91-entry preservation test.

## Safety boundary

- No localStorage access, no `user://` writes, no reward grant, no cloud sync, and no import execution.
- No edits to `main`, no merge, deployment, APK build or release.
- Existing raw source backup remains the recovery source if a record needs manual review.
