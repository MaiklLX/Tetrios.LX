# Interim progress — Mobile Utility HUD Redesign

**Date:** 2026-11-04  
**Repository:** `MaiklLX/Tetrios.LX`  
**Branch:** `feature/gameplay-evolution-389-2026-11-03`  
**Source code HEAD at this checkpoint:** `2aff9eaf861d73420f17a60179013b1a62e47d36`

## Completed

- Replaced the experimental equal-shrink utility-rail patch with a mobile-only compact HUD dock.
- Preserved the original DOM nodes, IDs, event targets, and game logic for charge, next piece, boost, Chrono Rift, timer, Hold, hero skill, and Hard Drop.
- Added compact functional styling, clear accent colors, concise labels, a distinct green Hard Drop target, and a dedicated Hold action.
- Increased the Hard Drop touch target while keeping it inside the rail.
- Kept all changes scoped to portrait mobile CSS; desktop layout and Golden Desktop Baseline #372 were not intentionally changed.
- Updated cross-platform visual QA to check that all visible utility cards fit inside the rail without scrolling or clipping, and added WebKit targets for 375, 390, 412, and 430 px.

## Verified

- Mobile Arena Visual Preview run `41789173885`: **success**.
- Tested Chromium mobile viewport sizes 375×812 and 412×915.
- Arena ratio measured approximately 0.43478 (10:23) on both sizes.
- Hard Drop and Hold controls remain present and tappable; right rail stays beside the arena; goals remain below the arena; no page errors were reported.
- Visual artifact: `13303025535` (`tetrios-mobile-arena-preview`).

## Still running / not yet accepted

- Cross-platform Visual Preview runs `41789173881`, `41789167504`, and `41789175163` were still running at checkpoint creation.
- WebKit 390×844 and 430×932, desktop Chromium 1440×900 and 1920×1080, and the new no-scroll / all-cards-visible assertions are not yet accepted.
- The first CSS-only fit attempt at `b38f2de65e47f95ef21a60ae16b66c659857709e` failed its old scroll-based QA expectation; it was superseded by the HUD redesign and updated QA assertions.
- The separate mobile preview at `1d4b076df6568c2a724623d4b02ecf6b29e1128d` and `a00ebf6ff40d121cd7edc4bd8af2e20b0caa7a81` failed horizontal content-overflow checks; concise HUD labels and the Hold icon treatment were corrected in `2aff9eaf861d73420f17a60179013b1a62e47d36`, after which the mobile preview passed.

## Guardrails

- Do not modify `main`.
- Do not merge draft PR #50.
- Do not alter Golden Desktop Baseline #372.
- Do not deploy or publish.
- Do not build an APK until mobile and cross-platform QA are closed and a separate build stage is explicitly approved.
- Do not create final checkpoint #402 until the complete mobile and desktop visual review is accepted.
- Keep the arena 2D-only and preserve the 10:23 ratio, counters, timers, goals, monster indicators, abilities, and all game controls.

## Next actions

1. Inspect the cross-platform run artifacts and screenshots for all four mobile widths and both desktop widths.
2. Confirm every live HUD card and both action buttons fit within the rail without internal scrolling or clipped text.
3. Confirm no arena/goals overlap, no horizontal overflow, no page/console errors, and desktop visuals remain unchanged.
4. Fix any issues found and rerun the affected checks.
5. Continue functional gameplay QA only after visual geometry is stable.

## Continuation phrase

**TETRIOS LX — MOBILE HUD / КТ-ПРОМЕЖУТОЧНАЯ.** Продолжаем в `MaiklLX/Tetrios.LX`, ветка `feature/gameplay-evolution-389-2026-11-03`, исходный HEAD `2aff9eaf861d73420f17a60179013b1a62e47d36`. Мобильный HUD-док уже реализован; Mobile Arena Visual Preview прошёл на 375×812 и 412×915. Не менять main, не сливать PR #50, не трогать Golden Desktop Baseline #372, не публиковать и не собирать APK. Сначала дождаться и проверить Cross-platform Visual Preview на 390×844, 430×932, 1440×900 и 1920×1080, проверить скриншоты, отсутствие прокрутки/обрезки карточек, overlap и ошибок. Затем исправить найденное и повторить QA. Финальный КТ-402 пока не закрывать.
