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

## 2026-11-17 — KT-697 diagnosis and regression coverage

- Mobile Arena Visual Preview [run 44074829515](https://github.com/MaiklLX/Tetrios.LX/actions/runs/44074829515) failed on the first current-mainline port commit. The job log isolated the failure to rail/frame geometry only: at 375×812 the frame was y=142.36..621.50 while the rail was y=112.01..651.86; at 412×915 the frame was y=131.84..719.34 while the rail was y=102..749.20. Page errors and browser warnings were empty.
- Root cause: the first KT-697 override used the same selector specificity as later inline mobile rules, so it lost the cascade. The corrected feature CSS uses a more-specific selector, centers the rail, and reduces its height by the measured 60px vertical excess without scaling or shrinking the Hold/Drop controls.
- Cross-platform Visual Preview [run 44074829401](https://github.com/MaiklLX/Tetrios.LX/actions/runs/44074829401) exposed stale home-hub assertions after the intentional H1-to-SVG wordmark replacement, plus outdated 50px/profile and desktop one-column width assumptions. Updated the preview assertions to recognize the accessible SVG wordmark, validate that the image loaded, and use the actual compact-portrait versus multi-column desktop/tablet layout thresholds.
- Added an explicit cross-platform regression assertion that the narrow portrait utility rail remains within 3px of the 10×23 frame's top and bottom edges.
- The same cross-platform run also exposed separate current-mainline campaign atlas failures: no visible procedural fallback/model in the campaign atlas and an art-width threshold miss. These are not hidden or waived by this brand patch; they remain open for a separate campaign-rendering investigation.
- Exact-head Mobile and Cross-platform reruns are pending for the commits above. Do not mark KT-697 accepted until both workflows pass and their screenshots/reports are inspected.
- No gameplay, campaign data, economy, save/persistence, main, deployment, APK, release or user data was changed.

- Second Mobile preview [run 44076865606](https://github.com/MaiklLX/Tetrios.LX/actions/runs/44076865606) confirmed that the first percentage-height correction aligned 412×915 but left a 5.64px inset error at 375×812: frame y=147.41..626.55, rail y=141.77..632.21. The parent grid row changes with the narrow-width board constraint, so a fixed `calc(100% - 60px)` is not a valid cross-width model.
- Replaced that percentage subtraction with the same width-derived 10:23 cabinet budget used by the narrow/wide mobile layout (separate 361–380px and 381–520px rules). The rail remains centered; no scale transform is used, so Hold/Drop hit areas are not shrunk. A fresh Mobile and Cross-platform run is pending.
