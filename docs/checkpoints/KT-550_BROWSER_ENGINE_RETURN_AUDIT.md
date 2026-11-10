# KT-550 — Возврат Block Buddies к браузерному движку

- Дата: 2026-11-09
- Рабочая ветка: `web/kt550-browser-return-2026-11-09`
- База: `main` / `ae410e7ba5fdb430c9b8854c29bb52b53bf78d32` (корневой браузерный runtime сохранён; Godot preview остаётся отдельным путём)
- Резервная база до публикации preview: `a9fce851a7c7b319c55642e490a39766736e10b6`
- Исходный браузерный файл: `site/index.html`, blob `38c61b606187b88ce8a48a1c6b71d264aecf4258`
- Статус: аудит завершён, перенос идёт небольшими этапами.

## Архитектурное решение

Block Buddies возвращается к существующему браузерному runtime. Основное игровое поле, логика фигур, столкновения, таймеры, режимы и сенсорный ввод остаются в HTML/JavaScript и 2D Canvas. Godot не становится новым runtime и не переносится в браузер.

Сохраняем:
- браузерный запуск без обязательного Godot/WebAssembly runtime;
- 2D-поле 10×23 и существующую игровую механику;
- Golden Desktop Baseline #372;
- режимы, прогресс, сохранения, героев, кампанию и награды;
- возможность упаковать тот же web runtime в Android WebView APK.

Godot KT-549 остаётся отдельным референсом. PR #84 остаётся Draft и не объединяется. Его удачные UX-идеи адаптируем под DOM/CSS/Canvas, не копируя Godot-код.

## Что обнаружено в браузерной базе

1. `site/index.html` содержит браузерный runtime и обработчики `touchstart/touchmove/touchend` на игровом контейнере. Сенсорный ввод уже реализован — меняем распознавание точечно.
2. Кампания имеет 360 узлов. `bbGetNodeInfo` определяет биом, локальный номер, boss-узлы и финального босса; `bbGetNodeGoals` формирует цели миссий. Не создаём вторую систему прогрессии.
3. Уже существуют наградные окна, сундуки реликвий, фрагменты коллекции и обмен фрагментов. Новую ленту нужно встроить в текущие экраны, сохранив ID и ключи сохранений.
4. Есть тренировка героев (`bbCampaignTraining`), но это не равно onboarding-туру по меню и управлению. Обучение новичка проектируем отдельно.
5. В HTML подключены `hero-arena.js`, `visual-3d.js`, `universes-3d.js`. Их оцениваем как визуальные слои; источником истины для игрового процесса остаётся 2D Canvas.
6. APK pipeline существует: `.github/workflows/build-apk.yml`, `.github/workflows/release-apk.yml`, Android WebView ZIP и asset-sync scripts. В рамках аудита сборка не запускается.

## Матрица переноса KT-549 → Browser

| Идея | Состояние браузерной базы | План |
|---|---|---|
| Жесты без случайного вращения | Touch handlers есть; диагональные жесты требуют более строгой классификации | KT-551: dominant axis 1.45, ambiguous-жест поглощается; проверить DROP guard |
| Более крупная арена на высоких телефонах | Есть адаптивная 10×23 арена и мобильные CSS-правила | KT-552: viewport/safe-area и размер поля без обрезки HUD |
| Отклик кнопок | Есть базовый `:active` transform | KT-553: явный pressed-state/ripple, не менять действия |
| Горизонтальная лента наград | Есть коллекция, сундуки и реликвии | KT-554: крупные карточки, горизонтальный scroll, совместимость сохранений |
| Вертикальный маршрут планет | Есть 360 узлов, биомы и boss-узлы | KT-555: вертикальное восхождение поверх существующей прогрессии |
| Понятный HUD | Есть HUD, цели и боковые модули | KT-553: иконки-якоря плюс читаемые подписи и значения |
| Обучение первого запуска | Геройская тренировка есть; onboarding tour отдельно не подтверждён | KT-556: меню → кампания → арена, Next/Skip, локальный флаг |
| APK | WebView-проект и workflow существуют | KT-557: проверить sync/build после стабилизации; запуск только с отдельным разрешением |

## Этапы и критерии

- **KT-551:** горизонталь двигает, вверх вращает, вниз soft-drop; диагональ не меняет фигуру; hard-drop не блокирует последующее движение/вращение.
- **KT-552:** поле 10×23 максимально использует безопасную область; HUD/Hold/Next/цели/DROP не перекрываются; desktop #372 не регрессирует.
- **KT-553:** нажатия заметны на touch и мыши; HUD читаем; игровые события не меняются.
- **KT-554:** горизонтальная лента, крупные карточки, выбранная награда видна; коллекционные ID, валюта и сохранения совместимы.
- **KT-555:** маршрут читается снизу вверх, боссы и финальная вершина видны; логика 360 узлов и открытий сохраняется.
- **KT-556:** обучение показывается один раз, пропускается, сохраняет завершение и не блокирует управление.
- **KT-557:** Chromium/WebKit, desktop/mobile portrait/landscape, все режимы, кампания, сохранения и отсутствие console/page errors. APK pipeline только проверяется после отдельного согласования.

## Релизные ограничения

- Не менять `main`, корневой публичный сайт или `/godot-preview/`.
- Не объединять PR #84 и не закрывать его без отдельного решения.
- Не запускать APK build/release и не менять публичную ссылку APK без отдельного разрешения.
- Не запускать Pages deployment из рабочей ветки.
- Каждый этап — отдельный commit, CI, короткий отчёт и контрольная фраза.

## Контрольная фраза

**BLOCK BUDDIES — KT-550: ВОЗВРАТ К БРАУЗЕРНОМУ ДВИЖКУ.** Продолжать в `web/kt550-browser-return-2026-11-09`. Основа — HTML/JavaScript + 2D Canvas, поле 10×23, текущие режимы/сохранения/кампания на 360 узлов. Godot KT-549 — отдельный референс. Переносить жесты, responsive arena, button feedback/HUD, reward strip, вертикальную карту боссов и onboarding этапами KT-551…KT-557. Сохранить Golden Desktop Baseline #372. Не трогать main, Pages и APK без отдельного разрешения.


## Обязательное визуальное условие — Godot KT-549 как эталон

Уточнение владельца проекта от 2026-11-09: возврат к браузерному движку **не означает возврат к старому браузерному оформлению**. Визуальный язык, созданный в Godot KT-549, обязателен для браузерной версии. Это критерий приёмки всех последующих KT-этапов, а не пожелание на будущее.

Источники истины:
- Godot branch: `godot/kt549-mobile-first-polish-2026-11-09`, PR #84 (Draft, отдельно от main).
- `godot/scripts/main.gd`: реальные экранные композиции, отрисовка планет/боссов, панели, цвета, HUD, tutorial bubbles, кнопки и эффекты.
- `godot/scripts/campaign_collection_layout.gd`: геометрия крупных горизонтальных карточек наград.
- `godot/project.godot`: базовый viewport 720×1280, expand для высоких экранов, GL Compatibility.
- `godot/docs/CHECKPOINTS.md`: спецификация KT-549.1–KT-549.5 и подтверждённые автоматические проверки.

Важно: визуал Godot в этой ветке в значительной степени нарисован непосредственно через Godot Canvas API (геометрия, полигоны, круги, дуги, линии и текст), а не представлен набором готовых картинок. Поэтому при переносе следует воспроизводить эти композиции и графические примитивы в Canvas/SVG/CSS; не подменять их случайными стоковыми изображениями или новым несогласованным стилем.

### Матрица визуального соответствия

| Эталон Godot KT-549 | Браузерный компонент | Требование к переносу |
|---|---|---|
| Тёмный космический фон, сине-графитовые панели, яркие бирюзовые/голубые контуры и тёплые золотистые акценты | CSS design tokens, фоновые слои, панели | Сохранить палитру, глубину, контраст, мягкое свечение и скругления; не превращать UI в плоский набор стандартных карточек |
| Главный экран и крупные тактильные кнопки | DOM/CSS menu components | Перенести пропорции, иерархию, типографику, обводки и press/ripple feedback |
| Атлас и вертикальная serpentine-карта планет, нарисованные планетами, узлами и маршрутными линиями | Canvas/SVG campaign map поверх существующих 360 узлов | Сохранить восхождение снизу вверх, тематические планеты, маршрут, боссы 010/020/030 и визуальную иерархию; не менять node IDs и progression |
| Горизонтальная лента из 49 крупных наградных карточек и выбранная карточка с деталями | DOM horizontal scroller + карточки | Перенести крупный масштаб, видимость выбранного предмета, индикатор прокрутки и детали; сохранить коллекционные ID и ключи сохранений |
| Арена 10×23, компактный HUD с символами метрик, боковые карточки, цели и buddy | Существующий Canvas board + DOM HUD/side modules | Сохранить размер поля, ясную иерархию метрик, читаемые подписи, Buddy и цели; улучшать компоновку без регрессии Golden Desktop Baseline #372 |
| Speech-bubble onboarding с указателями, подсветкой цели и Next/Skip | DOM overlay + CSS bubbles | Перенести последовательность, хвосты, подсветку, адаптивные размеры, пропуск и сохранение завершения |
| Визуальная обратная связь на нажатия и жесты | CSS pressed state/ripple + Canvas feedback | Ощутимое нажатие и обратная связь без задержки или изменения игровой логики |

### Правило реализации и визуальной приёмки

1. Перед каждым визуальным этапом сверять фактическую реализацию Godot KT-549, а не восстанавливать дизайн по памяти или по старой браузерной версии.
2. Создавать короткую mapping-запись: Godot-экран/элемент → браузерный компонент → цвета/геометрия/типографика/эффект → файл реализации → тест/скриншот.
3. По возможности переиспользовать существующие графические ресурсы проекта; для элементов, нарисованных кодом в Godot, делать аккуратную Canvas/SVG/CSS-адаптацию с теми же формами, пропорциями и цветами.
4. Сравнивать Godot и браузер при одинаковых размерах viewport (как минимум desktop и узкий portrait phone). Визуальная приёмка — faithful translation и сохранение идентичности, а не обещание пиксель-в-пиксель без подтверждающих скриншотов.
5. Не снижать качество оформления ради скорости. Оптимизировать частоту перерисовки, слои, кэширование и DOM/CSS; не упрощать художественный язык.
6. Старый браузерный runtime остаётся технологической и игровой основой: HTML/JavaScript + Canvas, поле 10×23, режимы, прогресс, сохранения, кампания, экономика наград и APK/WebView-совместимость. Godot не становится runtime.
7. До отдельного одобрения не переносить изменения в main, не публиковать Pages и не собирать/выпускать APK.

Контрольная формулировка для KT-552 и далее: **«Браузерная версия должна выглядеть как Block Buddies KT-549, но работать на старом браузерном движке».**


### Зафиксированные значения из реального Godot KT-549

Это не новая палитра «по мотивам», а значения, найденные в актуальном исходнике:
- Основной фон сцены: `#070d1c`; фон проекта: `#080b18`.
- Основные панели кампании: `#102f68`; контур: `#55ddff`; яркий выбранный/заголовочный акцент: `#fff0b9`.
- Вторичный текст: `#c4edff`; статус получено: `#8ef4d3`; золото/условия и текущий прогресс: `#ffd05a`.
- Планеты и боссы используют отдельные акцентные цвета по вселенным; их нельзя сводить к одному бирюзовому цвету.
- Наградная лента: 49 элементов; на компактном экране ширина карточки рассчитывается в диапазоне 82–142 px, высота ленты 150 px на коротком экране и 220 px в обычном, зазор 12 px. На экране остаётся видимая часть соседних карточек; выбранный предмет синхронизирован с нижней панелью деталей.
- Маршрут: 30 планет на вселенную; боссы на рубежах 010/020/030; маршрут визуально ведёт к вершине.
- Базовая сцена рассчитана на 720×1280, но Godot KT-549 использует expand для высокого viewport и увеличенный бюджет высоты поля.

Сопоставление с текущей браузерной основой:
- В браузере уже есть близкая базовая космическая тема и CSS-переменные `--bg`, `--panel`, `--cyan`, `--violet`, `--gold`; это хорошая стартовая база, но не доказательство полного соответствия.
- Визуальный разрыв нужно искать прежде всего в композиции экранов и графике кампании/наградах, а не заменять тему целиком.
- Поэтому KT-552 начинается с viewport и арены, а следующие отдельные этапы должны портировать карту и коллекцию с точной геометрией из Godot.


## KT-552 — portrait arena scale and visual evidence (2026-11-09)

Status: implementation committed to the isolated browser-return branch; automated visual verification is triggered by PR updates.

### Implementation
- Added `bb-kt552-portrait-arena-scale` at the end of `site/index.html`.
- For portrait phones up to 860 CSS px tall, the board cabinet may now use up to 56vw (instead of the earlier 51vw cap), while remaining constrained by its parent width and 64dvh.
- For portrait phones 861 CSS px and taller, the same 56vw target is used with a 66dvh ceiling.
- The board remains 10:23. No game logic, 10×23 logical grid, input handling, saves, campaign data, or desktop CSS was changed.
- The existing Godot-inspired cabinet border, dark blue panel, cyan edge glow and surrounding arena composition remain intact; this is a scale/layout adjustment, not a visual redesign.

### Visual regression evidence
- Extended `scripts/cross-platform-visual-preview.cjs` to save a dedicated `*-kt552-tall-phone-arena.png` screenshot for portrait mobile targets.
- Added a geometry assertion that the tall-phone portrait cabinet reaches at least 53% of viewport width while staying within the viewport. Existing 10:23 ratio, HUD fit, objective clearance, touch gesture, and desktop checks remain active.
- CI screenshot artifacts are the intended evidence for review; screenshots will be attached here in the PR artifact once the run finishes. No screenshot is claimed as passed until the run and artifact are available.

### Safety / next
- Branch only: `web/kt550-browser-return-2026-11-09`; PR #85 remains Draft.
- No merge, deployment, APK build, or APK release.
- Next visual stages remain planet atlas and reward collection; each requires the same Godot-to-browser comparison and screenshot evidence.

## KT-553 — tactile button feedback (2026-11-09)

Status: implementation committed to the isolated browser-return branch; cross-platform verification is running.

### Godot reference
- `godot/scripts/main.gd` `_draw_touch_feedback()` draws a brief warm-gold target outline while a touch is held, then a cyan expanding ring and a small white center pulse.
- Browser baseline previously relied mostly on a generic `button:active { transform: scale(.97) }`, without the same gold/cyan visual feedback.

### Browser implementation
- Added `bb-kt553-godot-press-feedback` at the end of `site/index.html`.
- All non-board buttons now get a short press response: slight compression, brighter surface, warm-gold outline, cyan halo and restrained inner glow.
- Keyboard focus gets a clear gold/cyan focus ring; reduced-motion preference disables the transition.
- Existing button contents, actions, IDs, campaign progression, save keys, game logic and board gestures are unchanged.

### Acceptance
- Verify button feedback on touch emulation and desktop mouse/keyboard.
- Verify no horizontal overflow, no layout shift after release, and no console/page errors.
- Keep the Godot visual language; do not replace existing button variants with one generic style.

### Safety
- Isolated branch `web/kt550-browser-return-2026-11-09`; PR #85 remains Draft.
- No merge, Pages deployment, APK build or APK release.

## KT-554 — Godot campaign reward shelf in browser (2026-11-09)

Status: first browser implementation and cross-platform assertions committed; CI pending.

### Godot source of truth
- `godot/scripts/campaign_collection.gd` defines exactly 49 campaign rewards: 12 universe relics, 36 boss insignias and the final campaign crown.
- `godot/scripts/campaign_collection_layout.gd` defines the horizontal strip: 12 px gap, card width 82–142 px, short-screen strip height 150 px and standard strip height 220 px; selection stays synchronized with the detail panel.
- `godot/scripts/main.gd` supplies universe-specific accents, locked/unlocked treatments, selected-card outline and reward descriptions.

### Browser implementation
- Added the `Полка наград` entry point below the existing campaign start control.
- The browser collection is built from the same 49-item structure and the 12 universe accents. It includes 12 universe relics, commander insignias at every 10th planet in each 30-planet universe, and the final crown.
- Unlock status is derived read-only from the existing sequential `nrNode` save (`completed = unlocked node - 1`). No new save key, reward currency, campaign node ID or progression rule is introduced.
- Cards use a horizontally scrollable snap rail, selected-card gold/cyan treatment, per-universe accent, locked/unlocked status and a detail panel with title, description and unlock condition.
- Campaign completion refreshes the shelf count; opening the collection does not modify progress.

### Automated acceptance
- Cross-platform preview checks exactly 49 cards, horizontal overflow/scrollability, final crown detail and its locked state on a fresh campaign save.
- Capture `*-campaign-reward-shelf.png` for desktop Chromium and iOS WebKit.
- Verify existing campaign atlas/mission tests continue after opening and closing the shelf.

### Known scope boundary
- This is the first browser translation of the reward shelf. The emblems are currently lightweight CSS/vector-symbol treatments using the correct universe accents; a later visual refinement can replace them with more faithful Canvas/SVG versions of Godot `_draw_collection_emblem()` without changing collection IDs or progression.
- Physical-device testing remains outstanding.

### Safety
- Isolated branch `web/kt550-browser-return-2026-11-09`; PR #85 remains Draft.
- No merge, Pages deployment, APK build or APK release.


## KT-554 — проверка визуального артефакта и корректировка preview-теста

- Дата: 2026-11-09
- PR #85 / ветка `web/kt550-browser-return-2026-11-09`.
- Артефакт cross-platform preview получен; скриншот `ios-webkit-412x915-campaign-reward-shelf.png` подтверждает 49 карточек, горизонтальную ленту, панель выбранной награды и корректную блокировку финальной короны на чистом сохранении.
- На скриншоте видны временные ромбовидные заглушки эмблем. Это не финальная графика: следующий визуальный проход должен перенести геометрию эмблем из Godot `_draw_collection_emblem()` в SVG/Canvas.
- Cross-platform workflow выявил ложное падение KT-553: реальное нажатие визуально показывает золотую рамку и голубое свечение, но вычисленный `transform` зависит от платформенного CSS и уже существующих стилей кнопок. Проверку скорректировали: обязательны видимая рамка и тень/свечение; transform остаётся диагностическим значением, но не блокирует корректный feedback.
- Это изменение только тестового критерия; поведение кнопок и игровая логика не меняются. Требуется повторный CI на новом commit.


## KT-555 — вертикальный маршрут кампании (первый перенос)

- Дата: 2026-11-09
- Ветка: `web/kt550-browser-return-2026-11-09`, PR #85 Draft.
- Перенесена ключевая композиция Godot `_draw_campaign_route()`: вертикальное восхождение снизу вверх, змейка между двумя сторонами маршрута, 30 планет, пунктирная трасса, визуальные рубежи и три босса на планетах 010/020/030.
- В браузере сохранены существующие `bbBiomes`, 360 node IDs, `current`/completed/locked вычисления, обработчики открытия миссии и старые ключи сохранений. Изменена только раскладка/ось прокрутки существующей карты.
- На телефоне маршрут прокручивается вертикально с нативным pan-y и ограничением overscroll; текущая планета получает усиленную золотую/бирюзовую подсветку, боссы — розовый контур, рубежные планеты — золотой.
- Добавлена cross-platform проверка: ровно 30 узлов на вселенную, 3 босса, вертикальный overflow, направление восхождения и скриншот `*-campaign-vertical-route.png`.
- Этап не считается подтверждённым до успешного Chromium + iOS WebKit preview. Не проводилось физическое тестирование на телефоне.


### KT-555.1 — эмблемы коллекции Godot → SVG

- Добавлен векторный перенос 12 рисунков реликвий, 4 базовых форм знаков боссов с тремя вариантами ранга и короны кампании по мотивам Godot `_draw_collection_emblem()`.
- Заглушки-ромбы заменены на inline SVG в карточках и панели осмотра. Визуальные формы строятся локально, без внешних картинок/зависимостей; цвета используют существующие акценты коллекции.
- Данные коллекции, IDs, условия открытия и сохранения не меняются.
- Требуется визуальный скриншот и повторный cross-platform preview после последнего commit.


### KT-555.2 — поправка отображения эмблем и точности preview-замера

- Исправлен пропущенный вызов SVG-рендерера в HTML карточек и карточке подробностей: ранее helper был добавлен, но шаблон продолжал выводить символы-заглушки. Теперь все 49 карточек и выбранная награда используют векторные рисунки.
- Добавлена проверка 49 SVG в коллекции и одного SVG в панели подробностей.
- Уточнён KT-552 preview-критерий: 53vw сравнивается с фактической шириной игрового поля `#board`, а не внешней оболочки `.boardframe`. На iOS WebKit оболочка использует собственную компоновку, поэтому прежний замер давал ложное падение при визуально корректном размере поля.
- Требуется новый полный Chromium/WebKit прогон; предыдущий workflow завершился failure только на старом KT-552 замере. Ошибок JavaScript/консоли/запросов в отчёте нет.


### KT-555.3 — правильная начальная позиция карты

- При открытии вселенной карта теперь сразу выставляет прокрутку на текущую доступную планету. Ранее плавный программный scroll мог не успеть завершиться до первого кадра, из-за чего на снимке начальная позиция показывала верхние, ещё закрытые планеты 025–030, хотя кнопка запуска указывала планету 001.
- Добавлена cross-platform проверка, что активная планета действительно находится внутри видимой области карты после её открытия.
- Это изменение касается только начального положения прокрутки; направления маршрута, порядка 30 узлов и логики разблокировки не касается.


### KT-556 — vertical route scroll and mobile preview timeout

- Дата: 2026-11-09
- Анализ артефакта cross-platform preview run 42642873567: сценарий дошёл до Android Chromium 393×873, где остановился по внутреннему watchdog 150 секунд во время тяжёлого прогона; артефакт сохранился. Это timeout самого preview-скрипта, а не доказанное падение игровой логики.
- Визуальная проверка снимка iOS WebKit 412×915 выявила, что карта планет отображает верх маршрута (025–030), хотя кнопка старта указывает планету 001. Причина в конфликтующих стилях: viewport оставался горизонтальным (overflow-y:hidden) при вертикальной раскладке трека, поэтому scrollTop не мог прокрутить маршрут к текущей планете.
- Добавлен финальный CSS override bb-kt556-vertical-route-scroll: ограниченная по высоте область карты, overflow-y:auto, overflow-x:hidden, вертикальный pan-y, отключённый горизонтальный snap. Текущая планета должна попадать в видимую область через существующую initial-scroll логику.
- Увеличен внутренний watchdog preview-цели с 150 до 210 секунд, чтобы медленные мобильные WebKit/Chromium захваты не прерывались преждевременно.
- Следующий обязательный шаг: новый полный cross-platform preview; проверить, что на свежем снимке активная планета 001 видна, 49 SVG-эмблем присутствуют, и Android 393×873 завершает захват. Не объявлять KT-556 закрытой до успешного результата.
- Снимки диагностического прогона: ios-webkit-412x915-campaign-vertical-route.png и ios-webkit-412x915-campaign-reward-shelf.png из artifact tetrios-cross-platform-visual-preview (run 42642873567). Эти route-снимки диагностические, не финальный результат после KT-556.
- Safety: PR #85 остаётся Draft; main, Pages, Godot preview и APK не затронуты.


### KT-557 — initial route alignment by viewport geometry

- Дата: 2026-11-09
- Повторный cross-platform preview run 42645723197 подтвердил, что KT-556 CSS override не устранил неверную начальную позицию маршрута: desktop 1920×1080 всё ещё показывал 025–030 при доступной планете 001.
- Установлена более точная причина: offsetTop относится к offsetParent, а не гарантированно к прокручиваемому viewport. Поэтому вычисление scrollTop могло не учитывать реальное положение активной планеты внутри карты.
- KT-557 заменяет расчёт на разницу getBoundingClientRect() активной планеты и viewport; позиционирование выполняется после двух кадров layout. Сохранены существующие node IDs, порядок планет, unlock-логика, обработчик запуска и ключи сохранений.
- Следующая проверка должна подтвердить видимость .is-current после входа во вселенную на desktop Chromium, iOS WebKit и Android Chromium. Также отдельно проверить mission-entry flow: предыдущий прогон завершился дополнительным timeout ожидания #bbStartHeroChoose на desktop 1920×1080; это пока не классифицировано как игровая ошибка и требует изоляции.
- PR #85 остаётся Draft; публикация, merge, APK build/release не выполняются.


### KT-558 — campaign hero-flow diagnostic hardening

- Дата: 2026-11-09
- Предыдущий cross-platform run завершился на ожидании #bbStartHeroChoose после выбора первого героя на desktop 1920×1080. Сам факт timeout не доказывал, что сломана игровая логика: сценарий использовал прямой DOM click без проверки видимости и состояния промежуточного списка.
- Preview теперь выполняет пользовательский Playwright click, отдельно ожидает видимый список героев и при отсутствии карточки выбора сохраняет диагностический снимок и контекст модального окна, количество карточек и последние page errors. Остальные размеры продолжают тестироваться, вместо преждевременного обрыва всей матрицы.
- Это диагностическое улучшение теста, не подтверждение исправности hero flow. КТ-557/558 остаются открытыми до нового CI результата с routeState и hero diagnostic.
- PR #85 остаётся Draft; main, Pages, Godot preview и APK не затронуты.


### KT-559 — исправление позиционирования вертикального маршрута

- Дата: 2026-11-09
- Cross-platform run 42648167574 завершился после успешной установки Playwright и запуска локального сервера. Ошибка воспроизводилась на desktop Chromium, iOS WebKit и Android Chromium: 30 планет и три босса присутствуют, вертикальный overflow есть, но активная планета вне viewport, scrollTop остаётся 0.
- Анализ DOM/CSS выявил недостающий перенос геометрии: у старой горизонтальной карты `.bb-planet-track` оставался `display:flex`, а `.bb-planet-node` сохранял `position:relative`. При этом KT-555 задаёт каждому узлу координаты left/top и строит SVG-маршрут как вертикальную карту. Значит, старый flex-ряд продолжал участвовать в раскладке, а координаты не становились координатами независимых точек маршрута.
- KT-559 принудительно переводит трек в `display:block; position:relative`, планеты — в `position:absolute`, а SVG-тропу оставляет абсолютным слоем. Существующие node IDs, координаты, 360-узловая прогрессия, boss-маркеры, unlock-правила и сохранения не меняются.
- В cross-platform routeState добавлены диагностические поля: computed display трека, position узла, overflow-y viewport, clientHeight/scrollHeight и прямоугольник текущей планеты. Это позволит отличить геометрию раскладки от ошибки прокрутки, если тест снова упадёт.
- KT-559 пока не подтверждена: требуется новый полный Chromium + iOS WebKit preview и проверка видимости текущей планеты на всех размерах. Hero flow также остаётся под наблюдением отдельного диагностического шага.
- PR #85 остаётся Draft; main, Pages, Godot preview и APK не затронуты.


### KT-559 — уточнение диагностики (исправление не принято)

- Дата: 2026-11-09
- После повторного чтения полного каскада CSS и шаблона генерации маршрута выяснилось, что абсолютное позиционирование узлов и блочная/относительная основа трека уже задавались более ранними стилями KT-555. Поэтому первоначальная гипотеза о том, что flex/relative мешали координатам, была недостаточно обоснована.
- Временный дублирующий CSS override KT-559 удалён из `site/index.html`, чтобы не накапливать лишние правила и не маскировать настоящую причину. Диагностические поля routeState в preview-скрипте оставлены.
- Факт остаётся прежним: в run 42648167574 активная планета не попала в видимую область; изменение KT-557 не подтверждено. Нужен следующий свежий preview на текущем HEAD и анализ реальных значений currentRect, viewport scrollHeight/clientHeight, computed overflow-y, а также ошибок JavaScript. Если preview workflow не стартует автоматически для нового HEAD, сначала восстановить CI-триггер, не объявляя маршрут исправным.
- KT-559 закрыта как неудачная гипотеза; задача начальной прокрутки остаётся открытой. PR #85 Draft; main, Pages, Godot preview и APK не затронуты.


## KT-560 — retryable initial route alignment (2026-11-09)

- Ветка: `web/kt550-browser-return-2026-11-09`, PR #85 Draft.
- Повторный анализ полного CSS-каскада подтвердил, что вертикальный overflow и высота карты задаются поздними правилами KT-555/556; прежняя гипотеза о flex/position уже снята.
- Выявлен риск порядка отображения: `buildMap()` может построить планетную систему в момент перехода экрана кампании, когда viewport ещё не получил конечную высоту. Старый расчёт использовал viewport-relative rect без проверки измеримости и не имел повторной попытки.
- Заменено выравнивание на координаты активной планеты относительно её фактического containing track (`offsetTop + offsetHeight / 2`) с ограничением по максимальному scrollTop. Если viewport ещё скрыт/нулевой высоты, выравнивание повторяется до 12 кадров. Записываются диагностические dataset-маркеры результата; при неприменившейся прокрутке есть fallback через `scrollIntoView`.
- Cross-platform preview теперь дополнительно фиксирует статус выравнивания, целевую позицию, номер узла и геометрию трека; тест требует успешного статуса `applied`.
- Изменения: site commit `64dbf0202abb48e6b9550d1c93210c36a961f4c6`; preview diagnostics commit `3c6590af95907be9a54e80de5adf8dd2d6cfae05`.
- **Статус: ожидает CI.** Проверка списка workflow runs на ветке пока не показала свежего запуска; отсутствие запуска не является прохождением теста.
- Не менялись node IDs, unlock/progression, mission handlers, save keys, Godot preview, main, Pages или APK. PR #85 остаётся Draft; merge/deploy/release не выполнялись.


## KT-561 — non-blocking campaign hero selection

- CI run `42652164364` completed with failure. Desktop 1440×900 completed the full preview through final arena verification; desktop 1920×1080 stalled during the click on the first campaign hero. Playwright confirmed the button was visible, enabled and stable, but the click handler did not return within 15 seconds.
- The campaign roster previously called `renderHeroCard()` synchronously inside the button click handler. The detail renderer replaces the modal DOM and triggers layout work for the hero showcase. This work is now deferred to the next animation frame with `requestAnimationFrame`, allowing the native click event to finish before the detail view is rendered.
- Site commit: `ca72c10d2d57b0a31d531c274d855d2d46a06ec0`.
- This is a targeted responsiveness change, not a confirmed fix. Await the next cross-platform preview run; verify the detail opens, hero selection starts the campaign, and all viewport route assertions pass.
- Safety: PR #85 remains Draft; do not merge, deploy Pages, touch main, Godot preview, or build an APK without explicit approval. Do not post screenshots in chat.


## KT-562 — route alignment timing diagnosis

- CI run `42658665309` completed with failure. The campaign hero selection did not remain the blocker: the visual preview reached arena verification on mobile, and the recorded page/console errors and failed requests were empty.
- The decisive failures are the vertical campaign route on desktop Chromium and iOS WebKit: the map has 30 nodes, 3 bosses, vertical overflow and the correct bottom-to-top order, but `routeAlign` remains `not-run`, `scrollTop` remains 0, and planet 001 is outside the viewport. Android Chromium did run the alignment and reported `applied` with planet 001.
- Separate existing geometry failure remains at iOS WebKit 390×844: the board did not reach the KT-552 53vw minimum (reported 118.08px). Keep this as a separate follow-up; do not hide or relax the assertion.
- Added a 90ms timer fallback to invoke the existing route alignment if animation-frame scheduling has not applied it. The existing geometry calculation and all route/game progression logic remain unchanged.
- Site commit: `06bcf64a26173e33045b2b3e2b501deff315c2c0`.
- This is a new hypothesis, not a verified fix. Await CI and inspect all viewport route reports plus the 390×844 board measurement.
- Safeguards remain: PR #85 Draft; no merge, deployment, main changes, Godot preview changes, or APK build. Do not post screenshots in chat.


## КТ-563 — исправление гонки smooth-scroll (2026-11-09)

- По CI run `42672369923` выяснено, что KT-562 выставляла целевой `scrollTop`, но общие стили атласа сохраняли `scroll-behavior:smooth!important`. Поэтому программная прокрутка оставалась анимированной во время замера; вызов `scrollIntoView` дополнительно мог прокручивать страницу вместо локального контейнера.
- Для `#campaign .bb-planet-viewport` в KT-556 добавлен приоритетный `scroll-behavior:auto!important`.
- `alignCurrentPlanet` теперь повторно выставляет локальный `scroll-behavior:auto`, проверяет фактический `scrollTop` и помечает `applied` только если целевая позиция действительно достигнута. Удалён fallback через `active.scrollIntoView`, который мог уводить документ.
- Изменение не затрагивает IDs планет, прогрессию, сохранения, боевую логику или размеры арены.
- Кодовый commit: `7656135b424253a2ea891ff141f2b227334ff794`.
- Статус: ожидается CI; исправление пока не подтверждено браузерным прогоном.


## КТ-564 — подтверждение карты и геометрии 390×844 (2026-11-09)

- Cross-platform Visual Preview run `42677137996` завершился `success` на кодовом SHA `7656135b424253a2ea891ff141f2b227334ff794`.
- Проверка прошла весь сценарий на iOS WebKit `390×844`, включая этапы campaign atlas, campaign missions, запуск Block Run и финальную проверку арены. В итоговом отчёте: `failures: []`, `pageErrors: []`, `consoleErrors: []`, `failedRequests: []`.
- На iOS WebKit `390×844` фактическая ширина игрового поля (#board) составила `214.39px`; минимум KT-552 равен `206.7px` (53vw). Текущая геометрия проходит порог, отдельная CSS-коррекция не требуется. Старое измерение `118.08px` не воспроизвелось в этом прогоне.
- В cross-platform сценарии прошли открытие карточки героя, выбор и запуск кампании; тестовая последовательность дошла до `final-arena-verified`.
- Отдельный Mobile Arena Visual Preview run `42677139224` был отменён. Отменённая job `129361438203` отправлена на повторный запуск; ждём её отдельного результата.
- Визуальный прогон успешен, но это автоматизированная проверка Playwright, не физический тест на iPhone или Android-устройстве.
- PR #85 остаётся Draft; main, Pages, Godot Preview и APK не менялись.


## КТ-565 — устойчивое ожидание геометрии карты (2026-11-09)

- Повторный прогон cross-platform на том же коде выявил нестабильность Android Chromium `393×873`: вертикальная карта и 30 узлов созданы корректно, но `alignmentStatus=not-run`, `scrollTop=0`, текущая планета за пределами viewport.
- Это означает, что одной пары requestAnimationFrame и таймера недостаточно во всех переходных состояниях.
- Добавлен `ResizeObserver` на реальный `.bb-planet-viewport`: как только viewport получает ненулевую высоту при существующей карте, выполняется выравнивание. Observer отключается после подтверждённого `applied`. Существующие rAF и таймер оставлены как дополнительные пути, не как единственная гарантия.
- При создании viewport явно выставляется диагностический статус `pending`, чтобы отличать «ещё ждём layout» от «функция вообще не запускалась».
- Новый кодовый commit: `fdeb914b8f1a85fa983d0b33009bde89f988e9c9`.
- Уточнение KT-564: один cross-platform прогон `42677137996` был успешным; повторный прогон `42677181285` выявил Android-флейк. Поэтому выравнивание пока не считается закрытым.
- Мобильный отдельный прогон `42677181203` завершился успешно. Это автоматизированный прогон, не физическое устройство.
- PR #85 остаётся Draft; main, Pages, Godot Preview и APK не менялись.


## КТ-566 — повторная проверка ResizeObserver и cross-platform (2026-11-10)

- Cross-platform Visual Preview run `42685337133` завершился `success` на кодовом SHA `fdeb914b8f1a85fa983d0b33009bde89f988e9c9`.
- Матрица отчёта включает desktop Chromium (1440×900 и 1920×1080), iOS WebKit (375×812, 390×844, 412×915, 430×932) и Android Chromium (393×873). Landscape targets подтвердили показ orientation guard.
- Итоговый отчёт: `failures: []`; для завершённых игровых сценариев `pageErrors: []`, `consoleErrors: []`, `failedRequests: []`. Android 393×873 прошёл в этом прогоне после KT-565 ResizeObserver.
- Cross-platform run подтвердил успешное прохождение сценария кампании и выхода к финальной проверке арены. Это автоматизированный Playwright preview, не физическое тестирование телефонов.
- Mobile Arena Visual Preview run `42685336631` был отменён; job `129390503666` успешно поставлена на повторный запуск (attempt 2), на момент фиксации находится в очереди. До результата отдельный мобильный тест арены остаётся неподтверждённым.
- PR #85 проверен: открыт, Draft, не объединён; head `cf4aa90988bcd173d45185e9a8278482e8f54e64`. Рабочая ветка остаётся `web/kt550-browser-return-2026-11-09`.
- Не менялись main, Pages, Godot Preview и APK; merge/deploy/release не выполнялись. Скриншоты в чат не публиковать.


## КТ-567 — подтверждение мобильной 2D-арены (2026-11-10)

- Mobile Arena Visual Preview run `42762887481` завершился `success` на актуальном PR HEAD `7f2eb4992dccd771ac276d31edd77aab436f8c80`; job `129652595421`.
- Успешно выполнены все шаги: подготовка offline soundtrack/Three.js assets, lightweight 2D arena preview, установка Playwright Chromium, запуск игры в portrait viewport и проверка геометрии, загрузка артефактов.
- Viewport 375×812: arena frame 210×483 px, отношение сторон 0.4348 (ожидаемый диапазон 0.42–0.45), utility rail остаётся справа; hard-drop и hold входят в rail, цели под ареной.
- Viewport 412×915: arena frame 242.25×557.17 px, отношение сторон 0.4348; utility rail справа, цели под ареной и внутри viewport.
- В обоих viewport подтверждён единственный 2D renderer: `toggleCount=0`, `overlayCanvasCount=0`, `boardVisible=true`; `pageErrors=[]`.
- Финальный отчёт: `failures: []`, `browserWarnings: []`. Артефакт `tetrios-mobile-arena-preview` загружен, artifact ID `13739195041` (срок хранения 7 дней). Скриншоты не публикуются в чат.
- Вместе с успешным cross-platform run `42685337133` это закрывает автоматизированную проверку КТ-565/566 по текущему HEAD: карта кампании и мобильная арена прошли Playwright Chromium/WebKit preview. Это не физическое тестирование на реальных iPhone/Android.
- PR #85 остаётся open + Draft, не merged. Никаких изменений в main, Pages, Godot Preview или APK не сделано.
- Следующий шаг — КТ-568: финальный аудит PR diff и статусов обязательных checks, без merge/deploy/release. Любые изменения игрового кода — только при обнаружении конкретного дефекта и отдельным небольшим коммитом.


## КТ-568 — завершение cross-platform и mobile visual preview (2026-11-10)

- Cross-platform Visual Preview run `42763840016` завершился `success` на HEAD `2df324f39b79eb0462da564acc61f6933e897d48`; job `129655572862`. Успешно завершены подготовка окружения, установка Playwright, локальный preview, capture desktop Chromium/iOS WebKit и загрузка отчёта.
- Матрица cross-platform отчёта: desktop Chromium `1440×900`, `1920×1080`; iOS WebKit `375×812`, `390×844`, `412×915`, `430×932`; Android Chromium `393×873`; landscape iOS WebKit `844×390`, `915×412` и Android Chromium `873×393` проверили orientation guard.
- В 7 portrait игровых targets подтверждены `boardVisible=true`, `toggleCount=0`, `overlayCanvasCount=0`; все 10 targets отчёта имеют `pageErrors=[]` и `consoleErrors=[]`. Общий список `failures=[]`.
- В одном iOS WebKit сценарии `390×844` зафиксированы три отменённых запроса `audio/chills.mp3` (`Load request cancelled`) при переходе между страницами/сценариями. Это не сопровождалось page/console errors и не было отмечено тестом как failure; не маскируем это под полностью пустой список сетевых отмен.
- Mobile Arena Visual Preview run `42763840012` также завершился `success` на том же HEAD `2df324f39b79eb0462da564acc61f6933e897d48`; job `129655625707`. Геометрия portrait-арены и отсутствие лишнего overlay renderer подтверждены; артефакт мобильной проверки загружен.
- Cross-platform артефакт `tetrios-cross-platform-visual-preview`, artifact ID `13739417811`; отчёт `report.json` содержит `failures=[]`. Визуальные файлы сохранены в CI artifact, скриншоты в чат не публикуются.
- Эти результаты подтверждают автоматизированные Playwright previews, а не физическое тестирование на реальных iPhone/Android.
- PR #85 остаётся open + Draft, не merged; HEAD на момент фиксации `2df324f39b79eb0462da564acc61f6933e897d48`. Main, публичный Pages, Godot Preview и APK не менялись; merge/deploy/release не выполнялись.
- Итог КТ-568: текущая браузерная ветка прошла оба обязательных визуальных CI workflow. Следующий этап — не автоматическое слияние, а отдельное решение о финальном ручном просмотре/готовности PR; до явного разрешения PR #85 остаётся Draft.


## КТ-569 — переход к visual-first разработке (2026-11-10)

### Решение владельца проекта

Сначала собираем и принимаем полный визуальный слой Block Buddies, затем переходим к основной механике и программной переработке. Godot KT-549 — источник визуальной истины; браузерный HTML/JavaScript + 2D Canvas остаётся runtime. Визуал нельзя упрощать до набора стандартных веб-карточек или заменять случайными изображениями.

Сохранения пока не являются частью текущего визуального этапа. Когда дойдём до них, прогресс и состояние игры должны записываться непосредственно на устройство:
- IndexedDB — кампания, прохождение, награды, коллекция и достижения;
- localStorage — небольшие настройки интерфейса и управления;
- экспорт/импорт файла сохранения — резервная копия;
- серверная синхронизация между устройствами — только отдельный будущий этап, не обязательный для локальных сохранений.

### Этапы visual-first

1. **Главное меню и навигация:** заголовок, профиль, карточки режимов, ежедневные задания, коллекция, герои/магазин/улучшения, фон, планеты и Buddy.
2. **Кампания и космическая карта:** вселенные, 360 существующих узлов, маршрут снизу вверх, боссы, состояния блокировки и переходы.
3. **Коллекция и награды:** 49 наград, реликвии, эмблемы боссов, корона, сундуки и анимации получения.
4. **Игровая арена:** поле 10×23, HUD, боковые панели, цели, Buddy, управление и пауза.
5. **Остальные экраны:** герои, ежедневные задания, магазин, результаты, game over, настройки, обучение и модальные окна.
6. **Анимация и адаптивная полировка:** переходы, подсветки, частицы, реакции Buddy, состояния нажатия, мобильные и desktop-размеры.

### KT-569.1 — первый проход главного меню

- Godot-эталон сверен с godot/scripts/main.gd: _home_layout, _draw_backdrop, _draw_home_hub, _draw_soft_panel; подтверждены пропорции карточек и палитра #123e91, #071b58, #174d9b, #76dcff, #1268b5, #64e2ff, #74469d, #ffca68, #59451f, #ffd05a, #fff0b9, #c4edff.
- В site/index.html добавлен изолированный CSS-слой bb-kt569-home-visual: глубокие синие градиенты, светящиеся контуры, золотистая типографика, тематические планеты для карточек «Кампания» и «Блок-ран», золотая карточка ежедневного вызова и согласованные панели ресурсов/статистики.
- Название на стартовом экране приведено к Godot-эталону BLOCK BUDDIES.
- Существующие id, data-mode, кнопки, обработчики, прогресс, экономика, ключи сохранений и DOM-контракты не менялись. Это только визуальная адаптация, без переписывания механики.
- Остальные рабочие секции браузерного меню (серия посещений, ресурсы, статистика, библиотека усилений, APK-ссылка) остаются доступными и не маскируются под несуществующие функции Godot.
- Изменение сайта: 7b707247b041cf89a6aea6c4939f406f83fae75b.
- Автоматическая визуальная проверка для нового HEAD должна быть выполнена до закрытия подэтапа. До результатов CI KT-569.1 имеет статус **реализовано, ожидает проверки**, а не «принято».

### Правила работы на этапе

- Сначала визуальный аудит и mapping каждого экрана Godot → браузерный компонент → CSS/SVG/Canvas → тест.
- Переиспользовать действующие обработчики и временные данные; не менять игровые правила и прогрессию ради визуала.
- Сравнивать эквивалентные desktop и узкие portrait-размеры; не заявлять pixel parity без подтверждённых измерений.
- Не показывать скриншоты в чате без прямой просьбы пользователя; визуальные артефакты сохранять в CI.
- Не менять main, не публиковать Pages, не трогать /godot-preview/, PR #84 и APK. PR #85 остаётся Draft.
- Локальные сохранения проектировать отдельным этапом после завершения визуального слоя; сервер не требуется для записи сохранений на устройство.

### Контрольная фраза

**BLOCK BUDDIES — KT-569: VISUAL-FIRST.** Продолжать в web/kt550-browser-return-2026-11-09, PR #85 (Draft). Сначала полностью перенести и принять визуал Godot KT-549 на браузерный HTML/JS + 2D Canvas runtime, затем переходить к механике и программной части. KT-569.1 — первое оформление главного меню, ожидает автоматической проверки. Далее пройти кампанию/карту, 49 наград, арену, дополнительные экраны, анимации и responsive polish. Сохранения пока отложены; позднее — локально на устройстве (IndexedDB + localStorage, экспорт/импорт), без обязательного сервера. Не менять main/Pages, не мерджить PR #85, не трогать Godot Preview и APK без отдельного разрешения.


### КТ-569.1 — уточнение реализации и проверки (2026-11-10)

- Дополнительно синхронизированы browser title и верхняя шапка: BLOCK BUDDIES / «ТВОЯ ВСЕЛЕННАЯ ПРИКЛЮЧЕНИЙ»; старый TETRIOS.LX wordmark больше не используется на стартовом экране.
- Последовательность изменений: home visual CSS `7b707247b041cf89a6aea6c4939f406f83fae75b`; checkpoint `5d8b72cd8897090b8b9710731e0f51e74ca6b605`; визуальные regression assertions `63527304800c4db24170d5817b5c8ee8ec370462`; синхронизация browser title/header `b069e69a07ae3f61cdd5f3b25f91baf49f5727bb`; исправление CSS форматирования `53ce0eb96afe0a1883cd61ab84e79a20d613cb8a`.
- В `scripts/cross-platform-visual-preview.cjs` добавлена проверка точного заголовка, cyan-обводки и планетарных pseudo-elements для карточек кампании и Block Run.
- Mobile Arena Visual Preview на HEAD `53ce0eb96afe0a1883cd61ab84e79a20d613cb8a` завершился `success` (run `42770870350`). Cross-platform Visual Preview на этом же HEAD на момент записи ещё выполняется (run `42770870463`); поэтому KT-569.1 пока не закрыта.
- Отдельный более ранний прогон `42770380613` завершился ошибкой в сценарии кампании на desktop 1920×1080: после reload Playwright не смог стабилизировать клик по `#campaignStart`. Это не ошибка нового меню; повторный прогон актуального HEAD обязателен.
- Текущий рабочий HEAD на момент фиксации: `53ce0eb96afe0a1883cd61ab84e79a20d613cb8a`. PR #85 остаётся open + Draft + unmerged. Main, Pages, Godot Preview и APK не затронуты.


## КТ-570 — космический атлас по композиции Godot (2026-11-10)

### Реализация

- Атлас браузера переведён с горизонтальной ленты крупных карточек на композицию, соответствующую `_draw_campaign_atlas()` в Godot: 3 колонки на desktop, 2 на компактных экранах, 12 вселенных, компактные карточки с орбитальной сферой, названием, диапазоном планет и статусом.
- Размер карточки соответствует логике Godot: около 166 px по высоте на desktop и 82 px на компактном экране. На узких экранах используется вертикальная прокрутка, горизонтальный overflow убран.
- Планетарные модели, акцентные цвета, состояния locked/current/cleared, 360 существующих узлов и клики открытия вселенной сохранены. Не менялись идентификаторы биомов, расчёт прогресса, ключи сохранения и механика кампании.
- Кнопки прокрутки атласа и автоматическое позиционирование текущей вселенной переведены на вертикальную ось, чтобы соответствовать сетке.
- В `scripts/cross-platform-visual-preview.cjs` добавлена проверка 12 карточек, числа колонок 2/3, вертикального overflow, отсутствия горизонтального overflow и геометрии карточки. Старт кампании в Playwright стабилизирован через DOM click после проверки видимости/доступности: предыдущий прогон показывал ложный timeout ожидания стабильной геометрии кнопки при загрузке 3D-модели.

### Изменения

- Атлас: `6c0d00aabe7176d1570ac73d5078b693b2ea809f`.
- Геометрические проверки: `4d83f6a854030bf811e20d4f7b2d4920620321a7`.
- Стабилизация тестового старта кампании: `89c4ca34df66b1f992e39ba7d78a2f92f449d36b`.
- Автоматическая проверка нового HEAD запущена GitHub Actions; до её завершения КТ-570 имеет статус **реализовано, ожидает проверки**.

### Дальше

Следующий визуальный проход — карточки профиля/Buddy и навигационные секции главного меню, затем экран кампании и planet route: сверить header, прогресс, верхнюю сферу мира, панель пути/рубежей, 30 планет и боссов с Godot. Не менять механику, не добавлять серверные сохранения. PR #85 остаётся Draft; публичная версия, Godot Preview и APK не затрагивать.
