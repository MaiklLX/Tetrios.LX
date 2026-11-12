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


## 2026-11-09 — KT-427.6: browser-measured 375px rail alignment

- Code HEAD under validation: `53ea25fb7d379532e983c22832fa514d56d30be6`.
- The full-page WebKit preview exposed a remaining 375×812 mismatch: the side rail measured 483.32px against a 494.75px arena frame. A fixed `.976` correction then over-expanded the Chromium fixture to 506.53px and correctly failed Mobile Arena Visual Preview run [42610737073](https://github.com/MaiklLX/Tetrios.LX/actions/runs/42610737073).
- Replaced the fixed scale with a runtime measurement based on the untransformed side-rail `offsetHeight` and the live arena-frame height. Chromium and WebKit now receive their own measured scale without user-agent sniffing.
- Added a 375×812 regression assertion to both the cross-platform and mobile preview workflows; the rail top and bottom must each stay within 2px of the arena frame.
- Mobile Arena Visual Preview [run 42611289452](https://github.com/MaiklLX/Tetrios.LX/actions/runs/42611289452): **SUCCESS** on the code HEAD above. Artifact [13669359759](https://github.com/MaiklLX/Tetrios.LX/actions/runs/42611289452/artifacts/13669359759) downloaded and inspected. At 375×812, frame height is 494.75px and side-rail height is 494.7478px (top delta −0.007px, bottom delta −0.009px); Hold and Drop remain visible and usable. At 412×915 the intended inset rail remains unchanged.
- Cross-platform Visual Preview [run 42611289275](https://github.com/MaiklLX/Tetrios.LX/actions/runs/42611289275) was still **in progress** when this checkpoint was written. No pass is claimed for that run.
- Browser previews are not physical-device validation. No changes to `main`, no deployment, no APK build/release, and no user-data mutation.


## 2026-11-10 — KT-427.7: WebKit first-layout rail measurement

- Rechecked PR #76 at HEAD `b56552ba0a9604d9a1227a889c9a86f630c68cc7`. Mobile Arena Visual Preview run [42612052920](https://github.com/MaiklLX/Tetrios.LX/actions/runs/42612052920) passed, but Cross-platform Visual Preview run [42612052903](https://github.com/MaiklLX/Tetrios.LX/actions/runs/42612052903) failed only at iOS WebKit 375×812: frame height 494.75px, rail height 483.32px (11.43px delta). The other target checks, orientation guard, page errors and console errors produced no additional failures.
- The failure is consistent with the one-shot animation-frame measurement running before WebKit has its final non-zero layout; the CSS fallback `.9533` remains active. The Chromium-only mobile preview does not cover this engine-specific path.
- Added a `ResizeObserver` for the arena frame and utility rail so the measured scale is recalculated when the hidden game screen becomes measurable or its layout changes. The observer does not alter gameplay, persistence or user data.
- Extended the cross-platform geometry report to record the rail's untransformed height, explicit measured scale and computed transform. The 375×812 regression now also requires an explicit measured scale, in addition to the existing 2px alignment tolerance.
- Fresh Mobile Arena and Cross-platform runs on the new commit are required before this checkpoint can be marked passed. Browser previews remain distinct from physical-device validation; no merge, deployment, APK build/release or user-data mutation.


## 2026-11-11 — KT-427.8: correct nested arena-frame selector

- Rechecked PR #76 at code HEAD `67bf06715cf6566ec3f6360b257062d05163b1be`. Mobile Arena Visual Preview run [42812588276](https://github.com/MaiklLX/Tetrios.LX/actions/runs/42812588276) passed. Cross-platform Visual Preview run [42812588271](https://github.com/MaiklLX/Tetrios.LX/actions/runs/42812588271) failed only at iOS WebKit 375×812: arena frame 494.75px, side rail 483.32px, measured scale missing. The report had no page or console errors; phone landscape guard was visible.
- Downloaded and inspected artifact [13763762991](https://github.com/MaiklLX/Tetrios.LX/actions/runs/42812588271/artifacts/13763762991), including 375×812 and 412×915 arena screenshots, the geometry report, and the Android Chromium landscape guard. The 375px frame is nested inside an extra wrapper: `.playlayout > div > .boardframe`, while the measurement and ResizeObserver used the incorrect direct-child selector `.playlayout > .boardframe`. As a result, the frame lookup returned null and the measured-scale assignment never ran; the CSS fallback `.9533` remained active.
- Fixed both the live measurement and ResizeObserver target selectors to `.playlayout .boardframe` in `site/index.html`. This is a selector-only fix; it does not change gameplay, layout dimensions, controls, orientation behavior, persistence or user data.
- Code fix commit: `969439e69f4ef7f660ca5b4be484e680467ba8cf`.
- At checkpoint time, no workflow run or combined status was yet returned for the new code SHA. **Do not mark KT-427.8 passed until a fresh Mobile Arena and Cross-platform run for the exact SHA is green.**
- PR #76 remains Draft/open. Its base has advanced substantially: compare against current `main` reports 51 commits ahead and 73 behind, with mergeability false. Do not merge or mechanically rebase this branch; reconcile the stacked history and overlapping `site/index.html` work separately.
- Browser previews remain distinct from physical-device validation. No merge, deployment, APK build/release or user-data mutation.


## 2026-11-12 — KT-427.9: stacked WebKit regression validation

- The selector fix from code commit `969439e69f4ef7f660ca5b4be484e680467ba8cf` is now covered by test-only stacked Draft PR #89. The test branch is based on parent checkpoint `4f1275311d817d319a2200755ecdfd6cc9fced8e` and is three commits ahead; it does not alter gameplay or persistence.
- Cross-platform Visual Preview [run 43212247116](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43212247116) completed **SUCCESS** on test SHA `d98bdb58f009d9712b8a9c6113e319d4535e30bb`. All 13 workflow steps passed.
- Downloaded and inspected artifact [13942522741](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43212247116/artifacts/13942522741) (64 files). On iOS WebKit 375×812, `frameSelector.found=true` and `matchesArenaFrame=true`; the side rail uses measured scale `0.97584`; frame and rail heights both report 494.75px. The 10:23 frame ratio is approximately 0.43478. At 412×915 the intended inset rail remains present.
- The same successful script exercises mobile gestures and visible Hold → Pause → Resume → Drop controls on each playable viewport, plus a live iOS WebKit landscape pause/guard/portrait-resume cycle. Landscape guard captures are present for iOS WebKit and Android Chromium. No page errors or console errors were recorded.
- The WebKit report includes a cancelled `audio/chills.mp3` request during page teardown; this did not fail the run or produce a page/console error.
- **Scope of acceptance:** this validates the parent selector fix through the stacked Cross-platform workflow. It is not a fresh Mobile Arena run on the exact parent code SHA, and it is not physical-device validation. Trigger/inspect a Mobile Arena run for the updated parent PR HEAD before marking the complete KT-427 preview set green.
- PR #76 remains Draft and diverged from current `main`; do not merge or mechanically rebase. No main, deployment, APK, persistence or user-data changes.
