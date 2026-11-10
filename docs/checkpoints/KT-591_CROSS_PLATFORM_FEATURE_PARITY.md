# KT-591 — Cross-platform feature parity

Date: 2026-11-10

## User decision and priority order

The user clarified the order of work: first bring the visual design on all platforms to a convincing shared style; only after visual approval begin the full mode/feature parity pass.

The game remains one coherent product across mobile, tablet, and desktop. Mobile and desktop are both first-class targets; neither should be visually neglected.

Allowed platform differences:
- Responsive layout and information density.
- Touch gestures and touch target sizing on phones/tablets.
- Mouse, keyboard, and wider-space composition on desktop.

Not allowed:
- Different visual identities between platforms.
- Platform-specific visual compromises that make one build feel like a different game.
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

6. KT-592 added a shared grid-light texture to the home hero across desktop and mobile, tightened the same rounded card treatment, and improved desktop mode-card proportions (icon scale, typography, padding). This is presentation-only; gameplay logic and mode behavior were not changed.
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
- Shared blue/Godot-inspired visual language is recognizable on all platforms; only layout and input affordances adapt.
- No page errors, clipped controls, hidden objectives, or horizontal overflow at supported phone/tablet/desktop viewports.
- Desktop keyboard/mouse and mobile touch/gesture inputs both remain functional.
- Any unsupported orientation behavior is explicit and tested.
- No merge, public deployment, or APK release until the user approves.

## Next actions — visual first

1. Review desktop, iOS, and Android screenshots side by side for shared palette, panel treatment, typography, icons, button language, depth, and spacing.
2. Fix the most visible visual mismatches across home screen and arena, keeping the same design tokens and visual components wherever possible.
3. Extend the same visual treatment to mode selection, pause/results, rewards, and settings.
4. Run screenshot/geometry QA at phone, tablet, and desktop breakpoints after each visual batch.
5. Ask the user to approve the shared visual direction before beginning Phase B feature-parity work.
6. Once approved, run the retained KT-591 all-platform Daily Challenge test and the wider feature-parity audit.

## Continuation phrase

**BLOCK BUDDIES — ПРОДОЛЖИТЬ KT-591: ЕДИНЫЙ СТИЛЬ И ПОЛНОЕ РАВЕНСТВО РЕЖИМОВ НА МОБИЛЬНЫХ И НАСТОЛЬНЫХ ПЛАТФОРМАХ.**

Start from branch `web/kt589-godot-friendly-visual-refresh-2026-11-10`, PR #86, and verify commit `35276f4431d31313c1a610122ab8dc231b3332dd`. Keep changes on the branch; do not merge or deploy.
