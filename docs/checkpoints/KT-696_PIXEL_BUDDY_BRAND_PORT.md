# KT-696 — BLOCK BUDDIES pixel brand port

## Scope
- Port the already-approved original pixel Buddy icon and wordmark from the stale KT-427 branch onto the current mainline without importing that branch's old application snapshot.
- Replace only the current topbar emoji mark and home hero lockup; retain the current menu, gameplay, modes, controls, campaign, economy, save paths and layout behavior.
- Add the four original Buddy expression SVG references for future event/animation wiring.
- Use hand-authored SVG/CSS only; no generated images, external agents or third-party art.

## Validation
- Initial branch base: `main@c5b4ddc152ce5774635d84689233842625348738`.
- Browser preview checks are pending on this branch. Do not mark the port accepted until Mobile Arena Visual Preview and Cross-platform Visual Preview complete and their screenshots are inspected.
- No gameplay or persistence code is changed. No deployment, merge, APK build/export or release.

## Safety
- This is an isolated Draft PR from current main. The old KT-427 branch remains untouched and is not rebased.
