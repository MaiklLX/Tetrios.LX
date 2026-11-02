# CHECKPOINT 329 — Desktop hidden selector specificity correction

Date: 2026-11-02

## Problem
The previous hotfix used `.screen[hidden]`, but desktop rules such as `#shopScreen { display:block !important; }` have stronger ID-selector specificity. As a result, hidden screens could still be forced visible.

## Fix
In `site/index.html`, inside the existing `@media (min-width: 901px)` block, replaced the generic selector with explicit ID selectors:
`#menu[hidden], #shopScreen[hidden], #heroes[hidden], #campaign[hidden], #daily[hidden], #game[hidden] { display:none !important; }`

## Mobile safety check
Compared the current `site/index.html` with checkpoint #327 commit `1eb765d45564fbbb48b68ad47e374140d5f04178` after removing the single desktop-only style block. The remaining source is byte-for-byte identical. This confirms no mobile CSS, markup, or JavaScript changed in this correction.

## Implementation
- Commit: `616bcffb9e8323af5418c02a21350bc953c37c97`
- Web deploy: https://github.com/MaiklLX/Tetrios.LX/actions/runs/41454177996

## Verification status
- Source-level selector specificity corrected.
- Mobile/non-desktop source confirmed identical to checkpoint #327.
- Web deployment was in progress when this checkpoint was written.
- No visual browser verification has been performed. After deployment, confirm initial load shows only the main menu and each secondary screen opens alone.

## Continuation phrase
TETRIOS LX — КОНТРОЛЬНАЯ ТОЧКА 329. DESKTOP HIDDEN SELECTOR SPECIFICITY: В bb-desktop-mobile-layout-v1 ИСПОЛЬЗУЕТСЯ ID-СПИСОК #menu[hidden], #shopScreen[hidden], #heroes[hidden], #campaign[hidden], #daily[hidden], #game[hidden] С display:none!important. Сверка показала: после исключения desktop-only CSS-блока остальной site/index.html байт-в-байт совпадает с checkpoint #327. Коммит 616bcffb9e8323af5418c02a21350bc953c37c97. Проверить deploy и переключение экранов. Мобильную часть не менять.
