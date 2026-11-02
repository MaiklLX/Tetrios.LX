# CHECKPOINT 343 — DESKTOP HOME QUEST ATLAS V2

Date: 2026-11-02
Branch: `desktop/home-quest-atlas-v2`

## Scope
- Desktop-only visual refinement of the main dashboard's daily quests.
- Modified only `site/desktop-shell.css` plus this checkpoint.
- No HTML, JavaScript, quest rules, reward values, progress calculations, persistence, or event handlers changed.
- Mobile styles remain unchanged.

## Changes
- Removed the nested-card appearance from the daily quest panel on desktop.
- Presented the three daily missions as a clean horizontal mission strip with readable titles, progress, progress bars, and rewards.
- Added restrained hover feedback and cyan/violet hierarchy consistent with the cosmic dashboard.
- Reduced visual prominence of the destructive reset-progress control without changing its action.

## Static verification
- New rules are inside `@media (min-width: 901px)`.
- No max-width/mobile media rules introduced in this patch.
- HTML and gameplay scripts unchanged.
- CSS brace balance and changed-file scope checked before PR.

## Next
- Merge after checks and verify Pages deployment.
- Continue desktop screen audit after browser visual check.
