# WORKING PROGRESS — MOBILE ARENA QA (2026-11-04, update 2)

Repository: MaiklLX/Tetrios.LX  
Branch: feature/gameplay-evolution-389-2026-11-03  
Source HEAD before this progress note: 241b15e27cd7b70c5d31ee77a2df6ad3135a110d

## Confirmed result from the previous cross-platform run

Runs 41785635599 and 41785635354 completed with failure on the visual-preview step. Their artifacts were uploaded and inspected:
- Artifact 13301830510 from run 41785635599.
- Artifact 13301770680 from run 41785635354.

The failure is a real mobile layout defect, not a browser startup failure:
- iOS WebKit 390×844: board cabinet bottom = 664.03px; goals panel top = 651.52px; overlap = 12.51px.
- iOS WebKit 430×932: board cabinet bottom = 678.98px; goals panel top = 696px; clearance = 17.02px.
- Both mobile targets retain the 10:23 cabinet ratio (0.4347826).
- Right utility rail reports overflow-y:auto and has scrollable content (390: maxScroll 33px; 430: maxScroll 16px).
- No page errors or console errors in either WebKit target. One campaign audio request was cancelled during page transition; treat as non-fatal unless reproduced as a user-facing audio defect.
- Desktop Chromium arena ratios are 10:23; no page or console errors. Desktop screenshots were reviewed. The desktop layout itself was not changed by the mobile CSS correction.

The 390×844 screenshot visibly confirms that the lower monster/objective panel is painted over the bottom of the board. This must be fixed before final QA acceptance.

## Changes since previous progress record

1. Commit 552f2d292fde9a3d57c826c6e9747a661b219cfc — added a 390px-only mobile CSS clearance override. It preserves the 10:23 cabinet height and shifts the lower information/control rows down rather than shrinking the playfield.
2. Commit 241b15e27cd7b70c5d31ee77a2df6ad3135a110d — expanded cross-platform QA diagnostics to record the left rail, computed grid tracks, and actual last utility-card visibility after scrolling.

## Current verification runs

New commit triggered:
- Cross-platform Visual Preview run 41786869987 (in progress at last poll).
- Cross-platform Visual Preview run 41786869354 (duplicate PR-triggered run, in progress at last poll).
- Mobile Arena Visual Preview run 41786870043 (pending at last poll).

No result from these runs is accepted yet. Wait for completion, download artifacts, inspect screenshots and geometry report, and confirm the new 390px-only correction produces at least 3px clearance. Confirm the final utility card is actually visible after scroll, not merely that scrollTop changes.

## Outstanding gates

- Validate 390×844 after the new CSS override.
- Validate 430×932 unchanged.
- Validate desktop 1440×900 and 1920×1080 unchanged.
- Verify side rail final card visibility after scrolling.
- Check gameplay interactions and Android browser emulation after visual geometry is stable.
- Create final acceptance checkpoint #402 only after all required evidence passes.

## Guardrails

- Do not modify main.
- Do not merge PR #50.
- Do not alter Golden Desktop Baseline #372.
- No APK build or deployment until QA is complete and the final checkpoint is recorded.
- Keep the arena 2D-only, preserve other Three.js systems, preserve 10:23 ratio and all HUD/gameplay information.
- Main menu/submenu polish remains after arena QA and the user's preliminary APK playtest.

## Continuation phrase

TETRIOS LX — продолжаем мобильную арену по рабочей фиксации 2026-11-04 update 2. Репозиторий MaiklLX/Tetrios.LX, ветка feature/gameplay-evolution-389-2026-11-03; исходный HEAD 241b15e27cd7b70c5d31ee77a2df6ad3135a110d. Предыдущие прогоны 41785635599/41785635354 подтвердили реальный дефект WebKit 390×844: корпус арены 10:23 заканчивается на y=664.03, панель целей начинается на y=651.52 (перекрытие 12.51px). На 430×932 зазор 17.02px; правая колонка прокручивается, maxScroll 33/16px. Добавлен CSS override 390px-only в коммите 552f2d2 и диагностические метрики grid/left rail/final utility card в коммите 241b15e. Проверь новые прогоны 41786869987, 41786869354 и 41786870043, получи артефакты и вручную осмотри все размеры. Не объявляй QA закрытой, пока 390px не имеет минимум 3px зазора и последняя карточка правой колонки реально видна после прокрутки. main не менять, PR #50 не сливать, Golden Desktop Baseline #372 не трогать, APK не собирать и не публиковать до финальной КТ-402.
