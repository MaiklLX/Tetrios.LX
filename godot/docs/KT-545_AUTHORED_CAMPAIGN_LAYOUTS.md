# KT-545 — Authored campaign layouts and mission runner foundation

## Status
Implementation in progress on `godot/kt493-gallery-validated-2026-11-08`. PR #81 remains Draft/open/unmerged. No main merge, public deployment or APK release.

## Scope of this slice
- Add a deterministic, validated authored starting-layout contract to the isolated campaign piece runtime.
- Allow planet definitions to supply optional bottom-up board rows before the first piece spawns.
- Keep ordinary planets on the existing empty-board fallback when no authored layout is present.
- Preserve the existing standard piece bag and the campaign-only Cargo Hook schedule.
- Keep the shared Classic model, Sprint/Marathon and Block Run unchanged.

## First Star Caravan authored layouts
- Planet 033 — Cargo Corridor (`cargo_corridor`): three bottom rows, 26 occupied cells.
- Planet 036 — Offset Bay (`offset_bay`): three bottom rows with staggered gaps.
- Planet 046 — Staggered Joint (`staggered_joint`): three bottom rows with offset passages.

Rows are authored top-to-bottom within the bottom stack. Each row is exactly 10 characters. A dot is an empty cell; digits 0–6 select an existing standard block color/type. Full rows, empty rows, invalid symbols, malformed widths and layouts that could overlap the spawn zone are rejected. Layout application is atomic: invalid input must not mutate the live board.

## Runtime behavior
- The layout is applied to a fresh campaign-owned 10×23 board before the initial piece is spawned.
- The first active piece remains a standard piece unless the planet explicitly declares the already-approved Cargo Hook event.
- Cargo Hook remains restricted to authored campaign planets; it does not enter Classic, Sprint/Marathon or Block Run.
- Leaving an unfinished planet still restarts that attempt; completed progression and rewards persist.

## Validation
- Unit tests cover valid layout application, exact occupied-cell count, invalid-layout rejection without mutation and safe standard-piece spawning.
- Catalog tests cover layout metadata and malformed-row rejection.
- Live integration test launches Planet 033 through the real campaign entry point and verifies the authored board is active without mutating the shared Classic model.
- Visual CI captures Planet 033 briefing and live arena screens.
- Full Godot CI must pass before this KT is accepted.

## KT-545.2 — authored mission contracts and multi-layout verification
- Added explicit mission contracts for the three starting-layout missions rather than relying only on the generated chapter formula:
  - Planet 033: line objective 12, guided difficulty, expected duration 90–150 seconds.
  - Planet 036: line objective 12, standard difficulty, expected duration 120–180 seconds.
  - Planet 046: line objective 13, standard difficulty, expected duration 150–210 seconds.
- The catalog validator now rejects unknown objective families, negative targets, incompatible objective fields, unsupported difficulty bands, malformed duration ranges and non-array event schedules.
- Campaign progression applies the authored mission contract to the live campaign session definition; ordinary planets continue using the bounded formula fallback.
- Catalog regression tests verify the resolved objective and pacing fields and reject malformed contracts.
- Live integration now launches all three authored layouts through the actual campaign entry point, checks occupied-cell totals (26 / 27 / 27), confirms a standard tetromino spawns, and continues to verify shared Classic isolation.
- Visual capture now includes briefing and live-arena captures for all three layout missions. These are CI screenshots, not static gallery concepts.

## KT-545.3 — complete Star Caravan mission pacing audit
- Every one of the 30 Star Caravan planets now resolves a supported objective type, difficulty band, expected duration range and deterministic event-schedule field through the campaign progression contract.
- The baseline pacing ladder is bounded by planet position: planets 001–009 guided, 010–019 standard, 020–029 advanced, and the chapter finale mastery. The three authored-layout missions retain their explicit overrides.
- The campaign catalog test now walks all 30 live planet definitions and checks objective, difficulty, duration and event-schedule completeness, in addition to the authored layout and malformed-data tests.
- This is a metadata and validation audit, not a claim that all 30 encounters have unique mechanics or bespoke visual content.

## Remaining KT-545 work
- Inspect the new CI screenshot captures for all three layouts and adjust any unfair or visually confusing gap patterns.
- Add deterministic completion-path simulation for each authored layout; successful spawn alone is not proof of fair playability.
- Complete the remaining 30-node Star Caravan objective/difficulty/duration audit; do not label briefing-only entries as live mechanics.
- Full Godot CI must pass on the final KT-545 head before this checkpoint is accepted.

## Acceptance boundary
This slice proves the authored-layout runtime seam; it does not mean the full Star Caravan chapter or all 360 planets are complete. No modifier registry entry becomes live without a dedicated runtime implementation, briefing, deterministic tests and visual proof.


## KT-546.1 — boss phase contract hardening
- The boss catalog validator now checks every phase independently: phase titles must be present, quotas cannot be negative, and no phase may have both line and score quotas set to zero.
- Three-phase encounters must retain a positive total line-clear requirement across the full encounter; malformed phase data fails closed before it can enter a live campaign session.
- Added regression cases for negative phase quotas and an empty/unwinnable phase; the tests also verify that each boss's three phase quotas sum exactly to the encounter-wide line and score targets.
- Existing authored bosses remain three sequential phases with per-phase progress baselines; the live HUD now displays both active quotas when a phase requires both.
- This is a data-integrity and player-readability improvement. It does not add unimplemented attack patterns or claim new boss mechanics.
- CI validation is required on the resulting branch head before this checkpoint is accepted.


## KT-547.1 — campaign reward ledger and collection summary
- Added a campaign-wide reward summary: marks earned, marks still available, total campaign planets, completion ratio and boss-mark contribution.
- Universe progress now also reports marks earned and marks available within that 30-planet universe, so a future collection/reward screen can show meaningful local goals without recalculating economy rules in UI code.
- Modern saves with reward receipts now validate the ledger as a whole: every completed planet must have exactly one receipt and the sum of receipt marks must match the saved campaign mark total. Partial ledgers and mismatched totals fail closed without mutating live progress.
- Legacy imports remain compatible: they preserve the historic mark total and do not fabricate per-planet receipts. The summary uses the imported total as the source of truth.
- Added tests for earned/available summaries, per-universe totals, duplicate-claim protection, partial-ledger rejection, mismatched totals and legacy mark preservation.
- This checkpoint establishes reliable reward accounting and progression data. It does not yet introduce spendable currency, shop prices, or unapproved reward unlocks.


## KT-547.2 — коллекция реликвий кампании
- Добавлен отдельный каталог коллекции без зависимости от UI и без введения новой валюты.
- Коллекция содержит 49 предметов: 12 реликвий за полное прохождение каждой вселенной, 36 знаков командиров за победы над боссами на каждой десятой планете и одну финальную корону за завершение всех 360 планет.
- Предметы открываются автоматически из подтверждённого прогресса. Повторные прохождения не создают дополнительные копии и не меняют экономику меток.
- Каталог предоставляет единый сводный счётчик, процент коллекции и поиск предмета по стабильному ID; отсутствующий прогресс обрабатывается безопасно.
- Добавлен отдельный regression test и включён в Godot CI.
- Это фундамент коллекционной системы и проверяемые правила открытия. Визуальная витрина, инвентарь экипировки и магазин пока не подключены.


## KT-547.3 — промежуточные достижения кампании
- Добавлен независимый каталог из 36 промежуточных достижений: по три на каждую из 12 вселенных.
- Пороговые планеты внутри каждой вселенной: 005, 015 и 025. Они дополняют боссов на 010, 020 и 030, формируя шесть заметных этапов на маршрут из 30 планет.
- Каждое достижение имеет стабильный ID, заголовок, описание и подпись награды «Знак пути». Награда является отметкой достижения, не валютой и не меняет баланс меток.
- Разблокировка вычисляется только по факту завершения нужной планеты; прогресс одной вселенной не открывает достижения следующей.
- Добавлены общий и локальный сводные счётчики, процент выполнения и безопасная обработка отсутствующего прогресса/неверного номера вселенной.
- Добавлен отдельный regression test и отдельный шаг Godot CI; тест проверяет 36 достижений, пороги 005/015/025 и изоляцию вселенных.
- На маршруте вселенной отображаются число полученных отметок и следующая цель. В карточке планеты 005/015/025 показана отдельная награда: до прохождения — как цель, после прохождения — как полученная отметка.
- Отдельного экрана-галереи достижений пока нет; текущая интеграция намеренно компактна и не перегружает маршрут.


## KT-547.4 — визуальная связь промежуточных достижений с маршрутом
- Карточка планеты теперь распознаёт достижение текущего рубежа 005/015/025 и показывает награду «Знак пути».
- До завершения планеты подпись объясняет, что это награда за рубеж; после подтверждённого завершения меняется на «Отметка получена».
- На остальных планетах карточка остаётся прежней: дополнительная панель не занимает место и не отвлекает от цели уровня.
- Ветка CI теперь действительно запускает `campaign_achievements_test.gd` отдельным шагом. До этого тест существовал, но был пропущен в workflow; это исправлено.
- Интеграция не меняет валюту, сохранение, общую экономику или правила разблокировки.


## KT-547.5 — полка наград кампании
- В Космический атлас добавлен отдельный вход «Полка наград»; экран открывается внутри кампании и возвращается обратно в атлас.
- Полка визуализирует все 49 предметов коллекции: 12 реликвий вселенных, 36 знаков победы над боссами и корону за все 360 планет.
- Полученные награды выделяются золотом и знаком завершения; недоступные остаются на полке в приглушённом виде с замком. Состав и расположение постоянны — игрок видит не только то, что уже заработал, но и то, к чему ещё идёт.
- Выбор любой ячейки открывает название, описание и состояние награды. На компактном экране используется сетка 7×7 без отдельной прокрутки.
- Полка читает существующий каталог `campaign_collection.gd`; новые валюты, магазин, сохранения и условия разблокировки не добавлялись.
- CI должен подтвердить разбор GDScript и регрессионные тесты коллекции/кампании перед принятием этапа.


## KT-547.6 — вход на полку наград с главного экрана
- Кнопка «★ Полка наград» перенесена из Космического атласа в главный хаб рядом с ежедневными заданиями; вход доступен сразу после запуска игры.
- На кнопке отображается живой счётчик полученных предметов из существующего каталога (например, `18 / 49`), без отдельного сохранения или новой системы учёта.
- Экран атласа больше не дублирует вход на полку. Возврат с полки, открытой с главного экрана, ведёт обратно в главный хаб; остальные маршруты кампании не меняются.
- Изменена только навигация и размещение кнопки. 49 предметов, условия разблокировки, награды и прогресс остаются прежними.
- Требуется полный Godot CI на новом HEAD; PR #81 остаётся Draft, без merge, публикации и APK.


## KT-547.7 — визуальные категории полки наград
- Три семейства наград получили разные силуэты: гранёная реликвия вселенной, щит-знак побеждённого босса и отдельная корона за все 360 планет.
- Цветовые акценты категорий различаются: бирюзовый для реликвий, розовый для знаков боссов, золотой для финальной короны. Закрытые предметы сохраняют узнаваемую форму, но приглушены и отмечены замком.
- Добавлена компактная легенда категорий и подробное условие получения выбранной награды.
- Когда собраны реликвия и все три знака конкретной вселенной, четыре предмета получают дополнительную бирюзовую отметку завершённого набора.
- Сетка остаётся 7×7, без прокрутки; каталог, 49 ID и правила получения не меняются. Тесты дополнены проверкой трёх стабильных категорий и условия финальной короны.
- Требуется полный Godot CI на актуальном HEAD; PR #81 остаётся Draft, без merge, публикации и APK.


## KT-547.8 — уникальный визуальный характер наград
- У 12 реликвий теперь разные авторские силуэты, привязанные к темам вселенных: росток, компас, солнечное ядро, снежинка, лунный серп, перо, песочные часы, портал, парящие острова, механизм, осколок разлома и маяк.
- 36 знаков боссов больше не выглядят одинаковыми щитами: форма медальона меняется между четырьмя типами, а центральный знак различается по трём ступеням босса.
- Цвета наград привязаны к палитре соответствующей вселенной; цвет остаётся дополнительным признаком, а не единственным способом различить предмет.
- Корона сохраняет отдельный золотой силуэт. Категорийная легенда остаётся прежней, чтобы игрок быстро понимал тип награды.
- В каталог добавлены только стабильные visual_variant для отрисовки. ID, количество наград, правила получения, прогресс и экономика не меняются.
- Regression test проверяет 12 уникальных вариантов реликвий, 36 уникальных вариантов знаков боссов и отдельный вариант короны.
- Требуется полный Godot CI на итоговом HEAD. PR #81 остаётся Draft; без merge, публикации и APK.

## KT-547.9 — получение наград и увеличенный осмотр
- При успешном завершении планеты сравниваются состояния коллекции до и после сохранённого прогресса; в очередь попадают только действительно новые награды.
- Сразу после успешного завершения планеты новая награда показывается поверх экрана результата: увеличение эмблемы, световое кольцо и короткий звёздный всплеск. Игрок сам подтверждает переход к следующей награде.
- Если игрок ещё не открыл полку, очередь новых наград остаётся доступной в текущей игровой сессии и будет показана при следующем входе в коллекцию.
- Если завершение вселенной выдаёт сразу реликвию и знак финального босса, показываются оба трофея по очереди.
- В панели выбранной награды добавлена кнопка «ОСМОТР». Повторное нажатие на выбранную ячейку тоже открывает просмотр.
- Увеличенный просмотр использует тот же авторский силуэт и цвет вселенной, показывает название и описание. Закрывается касанием или Escape.
- Награды, ID, условия и прогресс не меняются. Очередь раскрытия строится только по факту нового разблокирования, без повторного показа уже полученных предметов в рамках текущей сессии.
- Добавлены тесты: получение знака за босса 010 и одновременное получение реликвии плюс знака босса 030 при закрытии первой вселенной.
- PR #81 остаётся Draft; без merge, публикации и APK.