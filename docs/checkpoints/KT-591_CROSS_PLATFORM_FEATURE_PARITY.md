# KT-591 — Cross-platform feature parity

Date: 2026-11-10

## User decision and priority order

The user clarified the order of work: first bring the visual design on all platforms to a convincing shared style; only after visual approval begin the full mode/feature parity pass.

The game remains one coherent product, but the user has clarified that desktop is allowed (and expected) to use a different composition because it has more screen space. All mobile devices must share one consistent mobile layout and visual structure. Desktop is a separate responsive composition within the same design language.

Allowed platform differences:
- One unified layout and visual hierarchy across all mobile devices, including phones and tablets in mobile mode.
- Desktop may use a distinct composition and take advantage of wider screen space.
- Touch gestures and touch target sizing on mobile; mouse and keyboard affordances on desktop.

Not allowed:
- Inconsistent layouts between mobile devices.
- Different visual identities or unrelated design systems; desktop composition may differ, but must remain recognizably the same game.
- Publishing or merging without the user's explicit approval.

## Updated work phases

### Phase A — visual parity first (current priority)
1. Establish one visual reference language from the Godot-friendly direction: friendly blue palette, soft depth and lighting, rounded panels, consistent typography, iconography, button states, and block materials.
2. Bring the home screen into visual alignment across phone, tablet, and desktop.
3. Bring the arena into alignment: board/frame, side rails, goals, monster, HUD, pause affordance, and visual effects.
4. Align mode selection, pause/results overlays, rewards, and settings screens.
5. Capture comparable screenshots at matched responsive breakpoints and review them side by side. Differences should be layout-only, not stylistic.
6. Fix the visual defects and obtain user approval of the shared look.

### Phase B — feature parity (deferred until Phase A is approved)
1. Verify all modes on desktop, iOS WebKit, and Android Chromium.
2. Verify campaign missions, Block Run encounters/upgrades, and Daily Challenge objectives on every platform.
3. Verify shared profile, rewards, coins, hero progression, and saved progress.
4. Verify mouse/keyboard and touch/gesture input.

Do not let feature parity work displace the current visual-first priority. The KT-591 daily-on-all-platforms test harness change is retained for later use, but is not the current work focus.

## Current platform baseline

- Repository: `MaiklLX/Tetrios.LX`
- Branch: `web/kt589-godot-friendly-visual-refresh-2026-11-10`
- PR: #86 (open, draft, base `main`)
- Parity-test implementation commit: `35276f4431d31313c1a610122ab8dc231b3332dd`
- Checkpoint document commit: `3ce96c4fe57e2ffa605d910292092daa3710ef1e`
- Public/main branch and deployment remain untouched.
- Current browser product exposes three modes: Campaign, Block Run, Daily Challenge.
- The same responsive `site/index.html` runtime serves desktop and mobile; desktop and mobile CSS may rearrange the same components but must not fork game functionality.

## Work completed in this checkpoint

9. KT-593.1 follow-up: expanded the shared coarse-pointer mobile breakpoint through 1200 CSS px so tablet-sized touch screens are included. Preserved the established gesture-first mobile arena by keeping the legacy bottom control deck hidden; the first KT-593 draft had overridden this and has been corrected. Commit: `0190848fe79f719060465642fe70f7414441ab1e`. Fresh browser screenshots and geometry report are still pending.

## Work completed in this checkpoint

8. KT-593 unifies the mobile composition for coarse-pointer devices up to 900 CSS px, covering phones and tablets: same three-column HUD, board-plus-side-rail structure, four-button control row, responsive side rail, safe-area padding, and consistent home-mode card sizing. Desktop pointer/large-screen composition is not targeted by this override. Implementation commit: `e8fa7d2dbebbf7a232dc60fdc7401326a019841a`. Fresh visual QA is pending.

6. KT-592 added a shared grid-light texture to the home hero across desktop and mobile, tightened the same rounded card treatment, and improved desktop mode-card proportions (icon scale, typography, padding). Desktop may have its own wider composition; the mobile composition must remain consistent across all mobile devices. This is presentation-only; gameplay logic and mode behavior were not changed.
7. KT-592 implementation commit: `14c810967e42daa5427c042defe8374cb451eead`. Screenshot QA for this new commit is still pending; do not mark it visually verified until a fresh preview is captured.

1. KT-590 safe-area support is in the branch for iPhone notches and home-indicator spacing.
2. Mobile arena preview passed on 375×812 and 412×915. No page errors or horizontal document overflow were reported; arena, utility rail, and mission goals remain in their intended regions.
3. Cross-platform preview previously passed for desktop Chromium, iOS WebKit, and Android Chromium, including campaign and Block Run checks.
4. Found a coverage gap: Daily Challenge entry and in-arena objective were being tested only on desktop.
5. KT-591 updated `scripts/cross-platform-visual-preview.cjs` so the Daily Challenge check now runs for every non-landscape target (desktop Chromium, iOS WebKit, Android Chromium), rather than desktop alone.

## Acceptance criteria before merge/public release

- All three modes appear and can be entered on desktop, iOS WebKit, and Android Chromium.
- Campaign missions, Block Run encounter/upgrade flow, and Daily Challenge objective are present on every supported platform.
- Shared profile, rewards, coins, hero progression, and saved progress behave consistently across platforms.
- All mobile devices share the same mobile layout and visual hierarchy; desktop may use a distinct wide-screen composition while retaining the same design language.
- No page errors, clipped controls, hidden objectives, or horizontal overflow at supported phone/tablet/desktop viewports.
- Desktop keyboard/mouse and mobile touch/gesture inputs both remain functional.
- Any unsupported orientation behavior is explicit and tested.
- No merge, public deployment, or APK release until the user approves.

## Next actions — visual first

1. Review phone screenshots across iOS and Android sizes first, ensuring the mobile layout is consistent regardless of device.
2. Review desktop separately as a wide-screen composition; do not force desktop panel placement to mimic mobile.
3. Fix mobile inconsistencies and desktop-specific visual issues while retaining the same design language.
3. Extend the same visual treatment to mode selection, pause/results, rewards, and settings.
4. Run screenshot/geometry QA at phone, tablet, and desktop breakpoints after each visual batch.
5. Ask the user to approve the shared visual direction before beginning Phase B feature-parity work.
6. Once approved, run the retained KT-591 all-platform Daily Challenge test and the wider feature-parity audit.

## Continuation phrase

**BLOCK BUDDIES — ПРОДОЛЖИТЬ KT-591: ЕДИНЫЙ СТИЛЬ И ПОЛНОЕ РАВЕНСТВО РЕЖИМОВ НА МОБИЛЬНЫХ И НАСТОЛЬНЫХ ПЛАТФОРМАХ.**

Start from branch `web/kt589-godot-friendly-visual-refresh-2026-11-10`, PR #86, and verify commit `35276f4431d31313c1a610122ab8dc231b3332dd`. Keep changes on the branch; do not merge or deploy.
