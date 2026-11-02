# CHECKPOINT 331 — Desktop menu: all modes visible together
Date: 2026-11-02

## Implementation
- Main implementation commit: `971611772d24506bd8eab8522dc4630d55ca7b68`
- Replaced the previous campaign-only emphasis rule with a compact three-column desktop mode selector.
- Restored neutral ordering: Campaign, Block Run, Daily Challenge. No `order:-1` override remains.
- Explicitly keeps all three mode buttons visible in the desktop menu at once.
- Reduced hero and APK download vertical footprint to make room for all mode cards.
- Preserved the existing campaign, rogue, and daily buttons and their handlers; no JavaScript/game logic changes.
- Retained desktop arena sizing changes from checkpoint #330.

## Verification
- HTML source contains all three mode buttons: `campaign`, `rogue`, `daily`.
- Confirmed desktop-only rule uses a three-column grid.
- Compared current source to checkpoint #327 after normalizing the desktop-only style block: all content outside that block remains byte-for-byte identical.
- Therefore mobile markup, non-desktop styles, and JavaScript are unchanged.

## Deployment
- Web Deploy run: `41455717625`
- Status at checkpoint creation: in progress. Verify final Actions result before claiming deployment success.
- User visual confirmation still required after hard refresh.

## Continuation phrase
`TETRIOS LX — контрольная точка 331: вернуть полное desktop-меню. На ПК три режима одновременно в компактной сетке: Кампания, Блок-ран, Ежедневный вызов; порядок исходный, ничего не заменяет друг друга. Проверить Web Deploy 41455717625 и внешний вид после Ctrl+F5. Мобильную версию не менять.`
