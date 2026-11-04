# TETRIOS.LX — Visual Asset Kit (KT-402)

This folder contains original project-authored SVG UI assets for the 2026-11-04 visual refresh:
- `coin-emblem.svg` — premium gold reward token
- `gem-crystal.svg` — blue-violet crystal currency
- `level-insignia.svg` — progression badge
- `panel-frame.svg` — reusable ornamental frame

The new responsive skin lives in `site/visual-refresh-kt402.css`. It is loaded after the existing visual layers and intentionally does not replace gameplay markup, IDs, event handlers, saved data, or mechanics.

## Third-party asset reference
Kenney UI Pack is a separate optional source pack: https://kenney.nl/assets/ui-pack
The publisher lists it as CC0 and includes 430 UI elements. We have not copied third-party files into this commit; the SVGs above are original project assets. If/when individual Kenney files are imported, retain the source pack's license metadata in this folder.

## Scope
Targets: Android WebView APK, mobile web, desktop web. The CSS uses responsive rules and existing component selectors. Validate on actual devices before release.
