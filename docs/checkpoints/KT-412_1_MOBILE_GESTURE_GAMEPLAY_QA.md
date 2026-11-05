# KT-412.1 — Mobile gesture game-feel QA

- Date: 2026-11-05
- Parent: PR #60 `feat/kt412-mobile-gesture-arena-rework-2026-11-05`
- Follow-up: PR #61 `fix/kt412-mobile-gesture-polish-2026-11-05`
- Scope: mobile browser gameplay only. No APK build, signing, or release.

## User acceptance

- Remove the complete bottom movement/rotation control deck on mobile.
- Keep the arena composition and side-panel actions.
- Improve responsiveness across the board, including near edges.
- Horizontal swipes must preserve accumulated distance and avoid dropped cells.
- Upward swipe / short tap rotates; downward movement soft-drops; deliberate downward flick hard-drops.
- A gesture is bound to the piece active at touchstart. It must never affect the newly spawned piece after lock/drop.
- Desktop keyboard/control behavior remains unchanged.

## Implementation candidate

- CSS hides `#game .controls` at mobile widths, independent of wrapper depth.
- Touch thresholds are derived from board cell dimensions rather than fixed device-independent pixels.
- Horizontal sub-cell movement accumulates between touch events; multiple cells are processed in one move event.
- Vertical soft-drop uses a per-cell accumulator.
- Axis detection starts at 8 CSS pixels with a reduced directional ratio.
- The post-drop lock and piece identity guard remain in place.
- QA-only piece-state hook is available only with `?qaVisual=1`.

## Automated gameplay checks

The cross-platform preview now dispatches touchstart/touchmove/touchend events against the actual board in Chromium/WebKit and checks:
- horizontal movement right and left;
- upward swipe rotation;
- downward soft-drop;
- complete mobile bottom-control-deck removal;
- existing board geometry, campaign/daily/Block Run smoke checks, console errors and failed requests.

Synthetic browser touch events are useful regression coverage but do not replace hands-on testing on physical Android/iOS devices.

## Release gate

Do not merge or publish until:
1. Cross-platform preview passes on Chromium and WebKit with gesture interaction checks.
2. Mobile portrait and landscape captures are reviewed.
3. Desktop controls are confirmed unchanged.
4. No page, console, or network errors appear.
5. Physical-phone testing confirms no dead zones, dropped movement, accidental rotation, or double hard-drop.

## Recovery phrase

`TETRIOS — KT-412.1. Continue fix/kt412-mobile-gesture-polish-2026-11-05 from PR #61. Verify mobile deck is fully removed, touch accumulator gestures work on Chromium/WebKit, test portrait/landscape and all modes, retain piece identity/post-drop guard, and do not deploy or build APK until QA passes.`

## KT-412.2 — wide landscape follow-up (2026-11-05)

- Visual Preview run #469 completed with failure on the latest KT-412.1 candidate.
- Confirmed passing across all tested targets: mobile bottom deck hidden with zero layout footprint; gesture checks (left/right, rotate, soft drop); 10:23 board cabinet ratio; no console/page/request errors; Block Run and Void/Prism invariants.
- Remaining failures were isolated to wide landscape touch layouts (iOS 844x390, iOS 915x412, Android 873x393): desktop grid rules leaked into landscape touch viewports wider than 600px, causing the side rail and goals to overflow and the Hard Drop action to become clipped.
- Added a dedicated landscape-touch override after the existing layout rules. It explicitly restores a compact full-width game grid, keeps the bottom deck hidden, compresses the side rail, and reserves a goals row beneath the board.
- New commit: `72727f3fd9dd392553cd182538052f1398839ec0`.
- This is a fix candidate only; it is not yet verified by a new CI run. Do not merge or publish until the rerun passes.

## Recovery phrase — KT-412.2

`TETRIOS — KT-412.2. Continue PR #61 from HEAD 72727f3fd9dd392553cd182538052f1398839ec0. Fix wide mobile landscape layout: force compact game grid for coarse landscape touch devices wider than 600px, keep bottom controls absent, fit 10:23 board, goals and side rail including Hold/Hard Drop. Re-run Cross-platform Visual Preview; do not merge or deploy until all landscape and portrait tests pass.`
