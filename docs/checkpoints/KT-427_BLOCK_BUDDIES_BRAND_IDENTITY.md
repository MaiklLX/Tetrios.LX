# KT-427 — BLOCK BUDDIES brand identity

## Decision
Restore the original game name **BLOCK BUDDIES** as the visible title-screen brand. Keep TETRIOS.LX as the repository/technical project name only.

## Identity
- Mascot: original friendly pixel Buddy — rounded square head, dark face screen, cyan pixel eyes, small antenna/ear blocks.
- Primary color: saturated electric blue (#168CFF / #0750C9), supported by cyan (#39DFFF), ice white and restrained orange block accents.
- Lettering: chunky uppercase pixel-inspired wordmark; two-line lockup for title screens.
- App mark: Buddy face in a rounded-square blue app tile, designed to remain readable at small sizes.

## Files
- `site/assets/ui/block-buddies-logo.svg` — title-screen lockup.
- `site/assets/ui/block-buddies-icon.svg` — app/avatar icon master.
- `site/block-buddies-brand.css` — title-screen and topbar brand styles.
- `site/favicon.svg` — browser tab icon aligned to Buddy identity.

## Integration scope
The menu title and compact topbar brand now display BLOCK BUDDIES. Existing gameplay markup, modes, save data, controls and mechanics are unchanged. Android launcher/manifest icon wiring is intentionally left for a separate device-validation step; do not claim the installed APK icon has changed yet.

## Validation
Visual review on narrow portrait screens and desktop is still required. This is a draft branch and must not be merged or published without approval.
