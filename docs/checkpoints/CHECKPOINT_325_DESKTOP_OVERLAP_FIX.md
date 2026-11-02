# TETRIOS LX — CHECKPOINT 325
## Desktop overlap correction: grid aligned to actual DOM

Date: 2026-11-02
Branch: `main`
Implementation commit: `c4d5b9f0adc57232d8578bd2f0faf32b884a677c`

### User feedback
The entire desktop web page now fits in one full-monitor browser viewport, but many interface elements overlap. Preserve the one-viewport goal while removing collisions and clipping. Continue creating checkpoints and continuation phrases.

### Root cause found
The desktop dashboard rules had been built around an inaccurate assumption about the shop module:
- `bbApplyHero()` moves the real `#openShop` button into `#rpgPanel`.
- The original `.shopbuttons` wrapper is intentionally hidden by an earlier global rule (`#menu .shopbuttons { display:none !important; }`).
- The previous grid allocated a separate `shop` cell to this hidden wrapper and allocated a separate `rpg` cell to `#rpgPanel`, even though the latter actually contains the visible shop button.
- The previous row tracks used nonzero minimum sizes, allowing content to overflow their allotted space when the viewport became short.
- The game side rail used auto-sized minimum-height rows; cards could demand more height than the available arena.

### Changes
Added desktop-only stylesheet `bb-desktop-overlap-correction-v2`:
- Rebuilt the main-menu grid to match the actual direct-child DOM.
- Reassigned `#rpgPanel` to the visible shop slot because `#openShop` is dynamically moved there.
- Kept the hidden `.shopbuttons` wrapper out of the layout.
- Put the daily quests across the full dashboard width, with the three quest cards side by side.
- Placed visit streak, hero selection, and currency panels in the same middle row.
- Changed row tracks to `minmax(0, fraction)` sizing so grid content cannot force tracks beyond the available viewport.
- Applied min-width/min-height constraints, controlled overflow, and reduced internal padding/type sizes proportionally.
- Rebuilt the game side rail as two fixed proportional rows of three cards plus the full-width hero-skill row.
- Made gameplay layout use flex sizing from the remaining arena height instead of a fragile percentage height calculation.
- Added tighter short-window and 901–1100px rules.

### Validation performed
- Current file fetched from main after commit.
- New stylesheet present.
- CSS brace balance = 0.
- All new rules are inside desktop media queries (min-width 901px).
- Campaign mode markup remains present.
- Existing shop relocation JavaScript remains present.
- No mobile breakpoint rules were added or modified by this patch.
- Visual browser inspection has not been performed; overlap reduction must still be confirmed on desktop.

### Actions
At the time of checkpoint creation, the deployment and APK workflows for the implementation commit were still running. Verify final workflow conclusions before claiming publication. Previous Release APK workflow failures remain separate from this CSS change.

### Next verification
1. Check deployed web action for commit `c4d5b9f...`.
2. Test main menu at 1920×1080, 1366×768, and 1280×650.
3. Confirm hero heading, three game modes, visit streak, hero selector, currency, quests, reset, shop, and stats do not collide.
4. Open gameplay and confirm 10×23 board, HUD, six side cards, and hero skill slot do not collide.
5. If collisions remain, inspect actual computed geometry and adjust only desktop CSS; do not alter mobile layout or gameplay logic.

### Continuation phrase
`TETRIOS LX — КОНТРОЛЬНАЯ ТОЧКА 325. DESKTOP OVERLAP FIX: ПРОВЕРИТЬ НОВУЮ СЕТКУ ПО ФАКТИЧЕСКОЙ DOM-СТРУКТУРЕ, ЧТОБЫ ГЛАВНОЕ МЕНЮ И АРЕНА ОСТАВАЛИСЬ В ОДНОМ ОКНЕ БЕЗ ПЕРЕКРЫТИЙ. ОСОБО ПРОВЕРИТЬ МАГАЗИН В #rpgPanel, РЕСУРСЫ, ЕЖЕДНЕВНЫЕ ЗАДАНИЯ, КАРТОЧКИ БОКОВОЙ ПАНЕЛИ И СЛОТ СПОСОБНОСТИ ГЕРОЯ. РАЗМЕРЫ 1920×1080, 1366×768, 1280×650 И 901–1100 PX. МОБИЛЬНУЮ ВЁРСТКУ И ИГРОВУЮ ЛОГИКУ НЕ МЕНЯТЬ.`
