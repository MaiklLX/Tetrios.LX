# KT-411 — Keep the mobile control deck inside short WebKit viewports

- Date: 2026-11-05
- Base: `0047948ae2d8591e5de503efd258832ad4a133e2`
- Branch: `fix/kt411-ios-control-deck-viewport-guard-2026-11-05`
- Scope: mobile board vertical sizing only; no gameplay logic, desktop CSS, or APK workflow changes.

## Evidence

- KT-410 Mobile Arena Visual Preview passed (run `42058431345`).
- KT-410 Cross-platform Visual Preview failed only on the iOS-WebKit short portrait checks:
  - 375×812: control deck bottom at 816px (4px beyond viewport).
  - 390×844: control deck bottom at 859.98px (about 16px beyond viewport).
- The 2D board retained its 10:23 aspect ratio and page errors were empty.
- The failure was caused by the board consuming too much vertical space for the control deck and hint at shorter viewport heights.

## Change

- Tighten the mobile cabinet cap from `calc(100dvh - 325px)` to `calc(100dvh - 350px)`.
- Keep the existing 63dvh cap, 10:23 board ratio, control sizes, and touch layout.
- No APK build, signing, or release is part of this task.

## Acceptance

- Cross-platform Visual Preview must pass at 375×812 and 390×844 WebKit, plus the existing desktop Chromium and wider mobile WebKit captures.
- Mobile Arena Visual Preview must remain green.
- Review screenshots and geometry before merging. No production deployment until the user-approved merge.
- A Playwright WebKit pass is not a substitute for a physical iPhone Safari check.

## Recovery phrase

`TETRIOS — КТ-411. Продолжаем fix/kt411-ios-control-deck-viewport-guard-2026-11-05 от a58497b3cfbd95e8c18e61f719dbab76f2827204. Проверить Cross-platform Visual Preview 375×812 и 390×844, Mobile Arena Visual Preview и скриншоты. APK не собирать/не выпускать. Не сливать и не публиковать до проверки.`


## Regression diagnosis and correction — 2026-11-05

- Cross-platform run `42060911718` completed with two failures: WebKit 375×812 control deck bottom at 816px; 390×844 at 859.98px.
- Screenshot and geometry review identified the actual cause: legacy mobile CSS applied vertical transforms to `#game>.playlayout>.gameleftcol`, `#game>.controls`, and `#game>.hint` (+16px on narrow phones, +6px and +28px in overlapping viewport rules). These offsets overrode the intended compact layout and displaced the lower HUD/control deck.
- Corrected by adding a final portrait-only KT-411 override setting those three elements to `transform:none`. Board ratio, gameplay, touch target sizing, and desktop layout remain unchanged.
- Fix commit: `92b6388798077f1edd9a922fb1d95e4df2ac5ee7`.
- Re-run both visual workflows and review all viewport screenshots before merge. No production deployment and no APK build/release.


## Follow-up diagnosis — 2026-11-05

- Cross-platform run `42062164773` completed with the same two short-WebKit failures (375×812 bottom 816px; 390×844 bottom 859.98px). Wider iOS captures and desktop geometry remained within bounds; page errors, console errors, and failed requests were empty.
- The previous transform diagnosis was incomplete. The final KT-409 mobile rules later in the stylesheet override the earlier cabinet-height change. In WebKit, the board width remained the sizing constraint, so `max-height` alone did not reduce the board's intrinsic grid contribution.
- Added a final, narrowly scoped short-portrait rule (max-height 860px) that caps board width to 51vw while preserving the 10:23 ratio; also removed the 20px relative top offset from the goal rail on those short screens.
- Follow-up code commit: `469d1b9c28abb52eba61b33419359900411ff4be`.
- This is a new candidate fix, not yet validated. Re-run both visual workflows and inspect 375×812, 390×844, 412×915, and 430×932 before considering merge or main publication.


## Short control-row correction — 2026-11-05

- Cross-platform run `42062164773` completed; capture step failed on the two short iOS WebKit sizes. Report confirms the 375×812 control row bottom at 816px and 390×844 at 859.98px. Wider iOS sizes (412×915 and 430×932) and desktop Chromium fit; no page errors, console errors, or failed requests.
- Desktop daily-challenge screenshot confirms the active objective is visible in the arena header (example: `12 линий`).
- Added a narrowly scoped `translateY(-20px)` to the mobile control row only, for portrait viewports up to 860px high. This does not alter desktop controls, board geometry, or gameplay.
- Code commit: `433f7686b0d83a829c1dc4925017cce42bf1aac9`.
- This is an unvalidated candidate. Wait for the next cross-platform and mobile preview workflows, then inspect the two short viewport measurements and screenshots before further changes. Keep PR #59 Draft; no merge, public deployment, or APK build/release.
