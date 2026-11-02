# CHECKPOINT 330 — Desktop menu and arena polish
Date: 2026-11-02

## Baseline
- Main branch implementation commit: `fbb8d8071bbc837857403484a0820c62978ebb24`
- Previous stable screen-navigation fix remains in place.
- Campaign entry already existed in the HTML as `button[data-mode="campaign"]`; its click handler remains unchanged.

## Changes
- Added a desktop-only polish layer inside `bb-desktop-mobile-layout-v1`.
- Widened desktop app and screen containers from 760/620px to 900/820px.
- Reduced the desktop hero header vertical footprint to bring the mode selector into view sooner.
- Explicitly forced the campaign mode card to render visibly and gave it a stronger cyan visual emphasis.
- Increased desktop playfield vertical allowance and widened the right information rail to 116px.
- Kept the board canvas aspect ratio at 10:23; game coordinates and gameplay logic were not changed.
- No changes to JavaScript, game mechanics, campaign progression, or mobile-specific CSS.

## Safety verification
- Compared the current file against checkpoint #327 after normalizing the entire desktop-only style block.
- All content outside `bb-desktop-mobile-layout-v1` is byte-for-byte identical to checkpoint #327.
- This confirms mobile markup, styles outside the desktop-only block, and JavaScript were not modified by this pass.

## Deployment
- Web Deploy for commit `fbb8d8071bbc837857403484a0820c62978ebb24` was queued at checkpoint creation.
- Do not mark the deployment complete until GitHub Actions reports success.
- Desktop visual confirmation is still required from the user; no browser screenshot verification was available during implementation.

## User verification
1. Hard-refresh the desktop page.
2. Confirm the cyan-highlighted **Кампания** button is visible under the main hero.
3. Open Campaign and confirm the atlas and campaign entry point.
4. Start a mode and check that the board is larger while the side rail remains usable.
5. Mobile remains outside the scope of this desktop-only change.

## Continuation phrase
`TETRIOS LX — продолжить с контрольной точки 330: desktop-меню, видимая кнопка «Кампания», расширенная игровая арена. Проверить Web Deploy fbb8d8071bbc837857403484a0820c62978ebb24, затем собрать обратную связь по главному меню и полю. Мобильную версию не менять.`
