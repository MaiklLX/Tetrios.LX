# KT-544B — Three-phase Star Caravan boss encounters

## Implemented
- Added optional sequential boss-phase support to the existing mode-session coordinator. The path is inactive unless a campaign definition explicitly supplies `boss_phases`.
- Each phase has a player-facing title and its own line/score quotas. Progress baselines reset at phase transitions, so work from the previous phase cannot satisfy the next phase.
- Universe 02 bosses now have distinct three-stage encounter scripts:
  - Planet 040, «Страж конвоя»: «Разведка заслона» → «Перехват конвоя» → «Разрыв блокады».
  - Planet 050, «Чемпион каравана»: «Навигационный тест» → «Тяжёлый конвой» → «Вызов чемпиона».
  - Planet 060, «Адмирал дальнего пути»: «Внешний периметр» → «Штурм флагмана» → «Решающая доставка».
- Campaign launch and retry load the authored phase list. The active HUD displays the current phase number/title and its current phase objective.
- Catalog validation now requires exactly three valid, non-empty phases for each of the chapter's three boss milestones.
- Added unit tests for phase transitions, independent progress baselines, near-miss rejection and final completion.
- Extended live integration to launch Planet 040, complete all three phases through the campaign session, and verify the 5-mark reward and unlock of Planet 041.

## Balance note
Phase quotas are incremental. The first phase requires line clears but no additional score quota; score earned there remains part of the total campaign score. Later phases require their own additional score. The campaign's overall line/score thresholds remain enforced by the persistent progression model at completion.

## Isolation and safety
- The phase system is optional and dormant in Classic, Sprint/Marathon and Block Run.
- No board mutations, special pieces, save schema, reward rules or exit/restart policy changes.
- No main merge, public deployment or APK release.

## Validation
- Dedicated boss-session and campaign live-integration suites have been extended.
- Full GitHub Actions result is pending for the current PR head; no pass is claimed until the run completes.
