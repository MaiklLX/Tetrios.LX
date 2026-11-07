# Block Buddies original UI kit — KT-426

These are original project-authored, scalable SVG components. They are not extracted from EA Tetris or third-party packs.

## Files
- `drop-control.svg` — large thumb-first Drop visual; decorative/background layer only.
- `action-button.svg` — reusable graphite action button surface.
- `hud-panel.svg` — dark HUD panel with restrained turquoise/gold details.
- `roguelike-card-frame.svg` — vertical collectible/hero card frame.
- `block-tile.svg` — sample turquoise block face.

## Important integration rule
These SVGs are visual assets only. Do not replace live buttons with images that remove accessible labels, keyboard support, event handlers or touch targets. Use them as CSS backgrounds/masks or inline decorative layers; the real button remains a semantic HTML control. The Drop asset does not itself implement Drop.

## Design tokens
- Graphite/deep-space base: #07121a / #091720
- Turquoise action accent: #4ce2d0 / #13a99f
- Warm reward accent: #d4ad5b / #e7c36b
- Slate frame: #294c59 / #527c89

## Status
Prototype only. Not wired into the live UI. Compare against existing project theme and review on phone sizes before integration.
