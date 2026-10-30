# Tetrios.LX — game asset pipeline

This folder is the home for production-ready visual assets used by the web/PWA build and Android package.

## Asset rules

- Prefer local files over runtime downloads. The game must remain visually complete offline after the app is installed.
- Keep assets grouped by purpose: `backgrounds/`, `ui/`, `blocks/`, `effects/`, `icons/`, and `models/`.
- Prefer WebP/AVIF for large raster backgrounds when supported; use PNG for alpha transparency and crisp UI sprites. Keep original source files separately when redistribution permits.
- Avoid shipping giant sprite sheets if only a small number of sprites are used; document sprite coordinates when sheets are necessary.
- Every third-party asset must have its own entry in `ASSET_SOURCES.md` with creator, source URL, exact license, local filename, and any required attribution.
- Never assume that “free download” means unrestricted use. Verify the license for each item before adding it.
- Preserve the existing canvas gameplay as the reliable fallback. New art must be progressively enhanced and must not break touch input, reduced-motion settings, or low-memory devices.

## Target visual direction

Tetrios.LX should use a cohesive premium sci-fi / neon arcade style: deep-space backgrounds with restrained detail, high-contrast readable blocks, clear touch targets, and consistent panel/button geometry. Gameplay readability comes first; background detail and bloom must never compete with falling pieces.

## Planned asset groups

| Group | Purpose | Preferred formats |
|---|---|---|
| `backgrounds/` | Main menu and gameplay backgrounds | WebP, AVIF |
| `ui/` | Buttons, panels, badges, toggles | PNG, SVG |
| `blocks/` | Block faces, highlights, materials | PNG, WebP |
| `effects/` | Line-clear bursts, particles, glows | PNG, WebP, sprite sheets |
| `icons/` | Menu, settings, inventory, controls | SVG, PNG |
| `models/` | Optional 3D hero/arena models and textures | GLB, KTX2, WebP |

Do not add empty placeholder images or remote image URLs as if they were production assets. Add assets with their source/license record and wire them into the UI in a separate, reviewable change.

## Local icon sprite

`icons/tetrios-ui-icons.svg` is a project-authored SVG symbol set. It currently contains pause, play, trophy, coin, settings, home, sound, and refresh glyphs. Symbols inherit `currentColor` so the same artwork can adapt to the existing neon theme and accessible contrast states. The sprite is kept local; when wiring symbols into HTML, use `<svg><use href="./assets/icons/tetrios-ui-icons.svg#icon-pause"></use></svg>` and provide an accessible label on the containing control. Keep touch target sizing on the button itself, not on the glyph.
