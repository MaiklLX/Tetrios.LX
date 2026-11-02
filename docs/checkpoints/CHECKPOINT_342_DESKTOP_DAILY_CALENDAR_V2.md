# CHECKPOINT 342 — DESKTOP DAILY CHALLENGE + CALENDAR V2

Date: 2026-11-02
Branch: `desktop/daily-calendar-v2`
Base: `main` at `a8def6e29834f3e7618b4fab702b1ced13211602`

## Scope
- Desktop-only refinement of the Daily Challenge screen and its calendar.
- Modified only `site/desktop-shell.css`.
- No HTML, JavaScript, game rules, challenge schedule, reward values, history, localStorage, or event handlers changed.
- Mobile styles remain untouched; all new rules are inside `@media (min-width: 901px)`.

## Changes
- Daily Challenge becomes a wider, more open desktop screen with a clear heading, mission focus, separate rule presentation, and aligned primary/calendar actions.
- Mission and rule areas lose the nested heavy-card treatment and gain distinct cyan/violet visual hierarchy.
- Calendar desktop width is expanded to a 1280px maximum. Higher-specificity selectors deliberately override the calendar's later-injected legacy 620px inline-style cap.
- Calendar day cells become larger and more legible; date, status mark, symbol, and challenge title remain visible. Legend becomes a four-column desktop row.
- Existing mobile calendar sizing and all calendar interaction logic are preserved.

## Static verification
- CSS brace balance checked.
- New selectors verified to be inside the desktop-only media query.
- No files outside `site/desktop-shell.css` and this checkpoint are changed.
- Original `site/index.html` remains unchanged.
- No gameplay or persistence code changed.

## Next
Open PR, merge to main after checks, and verify the GitHub Pages deployment. Browser-level visual verification is still required after publication.
