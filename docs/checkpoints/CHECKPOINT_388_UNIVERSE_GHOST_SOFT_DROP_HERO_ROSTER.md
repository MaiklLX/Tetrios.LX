# TETRIOS LX — CHECKPOINT #388
## Clean universe atlas, gradual soft-drop and future hero placement

**Date:** 2026-11-03  
**Branch:** `mobile/golden-arena-adaptation-2026-11-03`  
**PR:** #48 — open, not merged  
**Code commit:** `857a45b2c626be258eb6b8d78de666d6a19f6804`  
**Main baseline:** `7c0f8d6dd7c2e6653db983359c780175600b6496` — unchanged

### Fixes

1. **Universe atlas**
   - Removed the extra companion-model slot from each universe card. The two overlapping 3D visuals were perceived as a ghost/duplicate beside every universe.
   - Kept the 12 distinct showcase planet models and all 40 CC0 models in the library for future scene composition.
   - The 360 campaign planets remain deterministic procedural variants.
   - Added seven silhouette families to the procedural planet generator: round, flattened, tall, elongated, egg-shaped, multi-lobed and faceted. Surface colors, patches, rings and moons remain independently varied.

2. **Falling blocks**
   - Slow downward touch drags now move the active piece during `touchmove`, one grid row per 28 CSS pixels.
   - The movement is visible step-by-step instead of being accumulated and applied as a multi-row jump at `touchend`.
   - A genuinely fast downward flick (at least 110 px in under 220 ms) retains the Hard Drop gesture. The explicit Hard Drop button remains unchanged.
   - Horizontal swipes and tap-to-rotate remain separate.

3. **Future hero**
   - Removed the locked teaser from the pre-level hero picker.
   - Added it to the dedicated `Отсек героев` roster as a disabled, non-selectable card.
   - It does not create a playable character or change gameplay data.

4. **Regression checks**
   - Validator now rejects a rendered companion slot on universe cards.
   - Validator checks incremental soft-drop behavior and verifies the future hero teaser belongs to the heroes roster, not the pre-level picker.

### Verification

- Android WebView source audit **#221** — SUCCESS.
- Mobile Arena Visual Preview **#76** — SUCCESS.
- Android APK build **#798** — running at checkpoint creation; no APK is declared ready until the run completes and artifact is verified.
- No production deployment performed.
- Golden Desktop Baseline #372 unchanged; `main` unchanged; PR #48 remains open and unmerged.

### Manual device checks still needed

- Confirm slow swipe visibly advances exactly one row per drag threshold.
- Confirm fast flick still produces a full Hard Drop.
- Confirm the universe cards no longer show the ghost duplicate.
- Confirm the hero teaser appears only in the dedicated heroes compartment.
- Check performance and visual variety of irregular/faceted planet silhouettes on the actual Android device.

### Continuation phrase

`TETRIOS LX — продолжаем с #388: убран призрак на карте вселенных, 7 форм процедурных планет, постепенный soft-drop по одной клетке, быстрый Hard Drop сохранён, секретный герой только в отсеке героев. Проверяем APK #798 и Android.`
