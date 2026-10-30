# Tetrios.LX — third-party asset source ledger

This file tracks candidate sources and the checks required before an asset is shipped. A source being listed here does **not** mean its assets have already been downloaded or integrated.

## Candidate sources

### Kenney — UI Pack
- Source: https://kenney.nl/assets/ui-pack
- Candidate use: buttons, panels, sliders, menu/UI sprites.
- License reported by source: Creative Commons CC0.
- Attribution: not required according to Kenney; optional credit is appreciated.
- Status: official Kenney page checked on 2026-10-30; it lists 430 assets and CC0. Individual files are not yet imported, so no Kenney artwork is currently represented as bundled in the app.
- Reference: the official support page also confirms Kenney asset packs are CC0 and attribution is optional.
- Before shipping: keep the pack's license/readme with the downloaded source and record the exact local filenames used.

### Kenney — asset library
- Source: https://kenney.nl/assets
- Candidate use: matching icon, object, and effect packs where the visual style fits.
- License: verify on the specific asset page; Kenney states its asset-page packs are generally CC0.
- Status: discovery source only; no specific pack imported.

### OpenGameArt
- Source: https://opengameart.org/
- Candidate use: backgrounds, textures, sprites, and sound effects when the exact asset fills a gap.
- License: varies by upload; verify every item individually and avoid assets whose terms are incompatible with project distribution.
- Attribution: depends on the selected license.
- Status: discovery source only; no specific asset imported.

## Import checklist

For each imported asset:
1. Record the exact creator and source page.
2. Record the exact license and any attribution text.
3. Copy required license/attribution material into this repository.
4. Optimize dimensions and file size for mobile screens.
5. Confirm the asset is loaded locally and does not require a third-party host at runtime.
6. Test at narrow phone widths, tablet widths, and with reduced motion enabled.

## Current project-authored assets

The following SVGs were created specifically for Tetrios.LX and are not copied from a third-party pack:
- `site/assets/backgrounds/nebula-space.svg` — background artwork.
- `site/assets/blocks/neon-block.svg` — block surface texture.
- `site/assets/ui/neon-button-frame.svg` — decorative frame for prominent controls.

These files are locally bundled; they do not introduce runtime requests to an external asset host.

### Project-authored UI icon sprite
- Local file: `site/assets/icons/tetrios-ui-icons.svg`
- Creator: Tetrios.LX project (original vector artwork).
- License: project-authored; no third-party artwork copied.
- Contents: pause, play, trophy, coin, settings, home, sound, refresh.
- Status: added to the asset branch; not yet wired into gameplay controls.
