# Checkpoint #349 — desktop hero logo proportions v2

Date: 2026-11-02

## Root cause
The hero lockup in `visual-overhaul.css` retained legacy important declarations:
- `.hero-brand-lockup` was absolutely positioned, centered, and forced into a vertical column.
- `.hero-app-mark` was enlarged to a 94–146px square with `!important`.
- The tagline remained absolutely pinned to the bottom of the hero.

The desktop shell had introduced a horizontal lockup and a smaller emblem, but its declarations did not reset those higher-priority legacy declarations. This made the desktop logo look oversized, vertically stacked, or visually distorted.

## Changes
- Reset the legacy absolute positioning and transform on the desktop hero lockup.
- Explicitly restore a horizontal emblem + wordmark row.
- Keep the emblem square with a responsive 58–74px size and fixed flex basis.
- Restore eyebrow and tagline to normal document flow.
- Keep the original emblem artwork, individual colored wordmark letters, cosmic background, and hero copy.
- Bumped the desktop stylesheet cache key from v5 to v6.

## Scope / safety
- Desktop only: `@media (min-width: 901px)`.
- No HTML structure, JavaScript, game logic, canvas, saves, progression, or mobile styles changed.
- Game field layout intentionally untouched.

## Verification
- Static source inspection confirms legacy absolute/column declarations are explicitly reset by the later desktop stylesheet.
- GitHub Pages deployment and user-side browser visual confirmation are pending.
