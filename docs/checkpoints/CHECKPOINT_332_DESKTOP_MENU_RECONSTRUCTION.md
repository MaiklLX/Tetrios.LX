# CHECKPOINT 332 — Desktop home menu reconstruction
Date: 2026-11-02

## Base and preservation
- Started from user checkpoint #331: `205527c7b3dacbd7eba6363daa23c91400bc04b9`.
- Preserved the three original mode buttons and their existing `data-mode` hooks: campaign, rogue, daily.
- No JavaScript, game rules, save data, mobile breakpoint rules, or gameplay arena logic changed.

## Root cause
- The desktop home dashboard was still governed by the legacy fixed-height 12-column grid in `site/visual-overhaul.css`.
- The three mode cards were assigned only the old seven-column `modes` region, while the hero, APK, streak and other dashboard panels occupied competing grid regions.
- The later inline desktop CSS changed the inner mode cards but did not replace the parent dashboard grid geometry.
- The external stylesheet was loaded after the inline style, so a final, higher-specificity desktop-only override in the external stylesheet is the correct single source of truth.

## Implementation
- `site/visual-overhaul.css`: added a desktop-only dashboard reconstruction at `min-width:901px`.
- Rebuilt the desktop grid: hero with a right utility rail, full-width section label, three equal-width mode cards across the full content width, then supporting dashboard panels.
- Removed the fixed-height/clipped desktop dashboard behavior; it now grows naturally and keeps the complete dashboard reachable.
- Restyled the three mode cards as consistent vertical cards with readable descriptions and tags; all remain visible together.
- Kept all other home features in deliberate, non-overlapping grid areas.
- `site/index.html`: bumped the visual stylesheet cache key to `20261102-desktop-menu-1` so desktop browsers/PWA clients fetch the new rules.

## Commits
- CSS reconstruction: `8700784f37c4e4d60b671b17db54508c9c764cfe`
- Stylesheet cache-bust: `852ef9aaf727d99101c8936e3586c7b0c115d2a3`

## Verification still required
- Source confirms all three mode buttons and their original hooks remain present.
- Combined status endpoint returned no status entries at check time; this is not proof of deployment success.
- Confirm the website deployment workflow completes successfully, then hard-refresh the PC web version and visually verify the full-width three-card mode row and every supporting panel.
- User visual confirmation remains required.
- Mobile layout is protected by the desktop-only `min-width:901px` scope; still perform a mobile regression check after deployment.

## Continuation phrase
`TETRIOS LX — контрольная точка 332: исправлена первопричина сломанного ПК-меню. В site/visual-overhaul.css заменена старая desktop-сетка на полноценную адаптивную структуру; Кампания, Блок-ран и Ежедневный вызов стоят в одном ряду на всю ширину. Кэш CSS обновлён в site/index.html. Коммиты 8700784 и 852ef9a. Проверить Web Deploy и внешний вид после Ctrl+F5; мобильную версию не менять.`
