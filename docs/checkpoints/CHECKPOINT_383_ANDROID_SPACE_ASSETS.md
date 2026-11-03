# TETRIOS LX — контрольная точка #383
## Android APK: восстановление космических ресурсов и 3D-атласа

**Дата:** 2026-11-03  
**Ветка:** `mobile/golden-arena-adaptation-2026-11-03`  
**База:** PR #48, контрольная точка #382  
**Статус:** исправление внесено; ожидает CI-сборки и повторной установки APK на реальное Android-устройство.

### Что обнаружено
Сайт содержит отдельные ресурсы, которые не попадали в Android WebView assets при сборке APK:
- `site/assets/deep_space_no_sun_2k.webp` — основной глубокий космический фон;
- `site/assets/space-nebula-01.png` — дополнительная туманность;
- `site/universes-3d.js` — модуль 3D-планет и галактического атласа;
- `site/universes/manifest.json` и каталог `site/universes/`.

Сборочный workflow переносил HTML, часть CSS/JS, персонажей и Three.js, но не эти ресурсы. Поэтому web-версия и APK могли визуально различаться.

### Исправления
- В `.github/workflows/build-apk.yml` добавлено копирование `universes-3d.js`, `assets/` и `universes/` в Android assets.
- Добавлены обязательные проверки наличия космических текстур, модуля и manifest до сборки.
- Workflow теперь запускается и на `pull_request` в `main`; ветка PR не проходит шаги публикации, которые ограничены `refs/heads/main`.
- APK остаётся тестовым артефактом; публикация и production deploy не выполняются.

### Приёмка
- Проверить CI build APK и содержимое архива: обе текстуры, `universes-3d.js`, `universes/manifest.json`, Three.js и модели персонажей должны быть внутри APK.
- Установить новый APK и проверить фон главного экрана/атласа и 3D-планеты.
- Не менять Golden Desktop Baseline #372 и не сливать PR #48.
