# KT-ARENA-REPAIR-001 — Restore the desktop gameplay rails

- Date: 2026-11-05
- Base: `8fc2b889524d3dcaf87439efe57aa74dc68e1042` (KT-405.5 public web release)
- Working branch: `fix/desktop-arena-rail-2026-11-05`
- Scope: desktop gameplay layout only; no game rules, balance, or mobile CSS changes.

## Root cause found

The desktop stylesheet forced the gameplay area into a three-column grid and placed the board in column 2 and the right tools in column 3, but the first column had no mounted left rail. The live `.gamehud` remained a direct child of `#game`, outside `.playlayout`. The legacy `.gameleftcol` styles and dynamic goal mounting already existed, but the HUD was not moved into that rail. This left an empty reserved column and broke the accepted visual balance.

## Repair

- `bbGoalsRail(game)` mounts the existing live `.gamehud` into the left rail on desktop only; mobile retains its HUD-above-board layout and lower goal rail. A resize sync handles breakpoint changes.
- Desktop grid explicitly reserves equal side rails around the centered 10×23 board.
- Left HUD, goals, center board, and right-side tools receive explicit grid placement.
- The narrower desktop breakpoint reduces both rails symmetrically.
- The change does not alter gameplay state, score, timers, rewards, touch controls, or the mobile breakpoint rules.

## Acceptance still pending

- Run the existing cross-platform visual preview and inspect desktop captures at 1440×900 and 1280×720.
- Confirm the board is centered, all four HUD metrics are visible on the left, goals remain below them, and all right-side tools remain readable.
- Confirm mobile screenshots and gameplay-mode validation remain green. A first mobile preview exposed the need to keep HUD relocation desktop-only; this was corrected before acceptance.
- Do not deploy to `main` until the preview is reviewed and the user approves the release.

## Recovery phrase

`TETRIOS LX — KT-ARENA-REPAIR-001. Исправляем ПК-арену в ветке fix/desktop-arena-rail-2026-11-05: HUD и цели слева, поле 10×23 строго по центру, инструменты справа. Мобильную версию и механику не менять. Сначала Chromium visual preview 1440×900 и 1280×720, затем review; main не обновлять без отдельного подтверждения.`
