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

## 2026-11-08 — preview interaction verification

- Verified branch HEAD: `d6cbd7814b72f4192c1baf6abb205b4c8fc9111c` (PR #76 remains open and draft).
- Mobile Arena Visual Preview run [42479122052](https://github.com/MaiklLX/Tetrios.LX/actions/runs/42479122052): **SUCCESS**. Artifact [tetrios-mobile-arena-preview](https://github.com/MaiklLX/Tetrios.LX/actions/runs/42479122052/artifacts/13616667808) was downloaded and inspected; the 375×812 and 412×915 captures and geometry JSON are present.
- Cross-platform Visual Preview run [42479122170](https://github.com/MaiklLX/Tetrios.LX/actions/runs/42479122170): **SUCCESS**. Artifact [tetrios-cross-platform-visual-preview](https://github.com/MaiklLX/Tetrios.LX/actions/runs/42479122170/artifacts/13616644338) was downloaded and inspected. The report contains no failed assertions across 10 desktop/iOS-WebKit/Android-Chromium viewport targets and no page or console errors.
- The cross-platform script explicitly exercises visible Hold, Pause, Resume and Drop actions, including Hold swap, pause/resume state, and hard-drop lock; it also checks full-screen mobile swipe movement, repeated movement/rotation, soft drop, and immediate movement/rotation after a touch hard drop. All assertions passed on this HEAD.
- The 375×812 geometry report shows the board frame and utility rail aligned to within 0.01px vertically; 412×915 retains the designed inset utility rail. Both reports preserve the 10:23 board ratio and stay inside the viewport.
- iOS WebKit reported a cancelled local soundtrack request during page teardown; this did not produce a page/console error or fail any preview assertion.
- These are browser-engine previews only. They do not confirm physical iPhone/Android touch behavior or orientation handling on a real device. No deployment, merge, APK build or release.
