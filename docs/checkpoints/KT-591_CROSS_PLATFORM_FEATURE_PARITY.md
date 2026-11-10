# KT-591 — Cross-platform feature parity

Date: 2026-11-10

## User decision

The game must be developed as one coherent product across mobile and desktop. Mobile is no longer the sole visual priority: all platforms must receive the same game modes, mechanics, progression, rewards, and visual identity at the same time.

Allowed platform differences:
- Responsive layout and information density.
- Touch gestures and touch target sizing on phones.
- Mouse, keyboard, and wider-space composition on desktop.

Not allowed:
- A mode, feature, reward, or progression path being desktop-only or mobile-only without an explicit product decision.
- Different visual identities between platforms.
- Publishing or merging without the user's explicit approval.

## Current platform baseline

- Repository: `MaiklLX/Tetrios.LX`
- Branch: `web/kt589-godot-friendly-visual-refresh-2026-11-10`
- PR: #86 (open, draft, base `main`)
- Latest commit at checkpoint: `35276f4431d31313c1a610122ab8dc231b3332dd`
- Public/main branch and deployment remain untouched.
- Current browser product exposes three modes: Campaign, Block Run, Daily Challenge.
- The same responsive `site/index.html` runtime serves desktop and mobile; desktop and mobile CSS may rearrange the same components but must not fork game functionality.

## Work completed in this checkpoint

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

## Next actions

1. Verify the KT-591 cross-platform workflow on commit `35276f4`; the preceding KT-590 workflow passed but does not include the new daily-on-mobile coverage.
2. Review desktop, iOS, and Android screenshots side by side for shared palette, panel treatment, typography, icons, and button language.
3. Fix any platform-specific layout or input defects found by those tests without forking gameplay logic.
4. Audit mode-specific feature gates and profile/reward persistence for parity.
5. Update this checkpoint with test run IDs, artifact IDs, and any remaining gaps.

## Continuation phrase

**BLOCK BUDDIES — ПРОДОЛЖИТЬ KT-591: ЕДИНЫЙ СТИЛЬ И ПОЛНОЕ РАВЕНСТВО РЕЖИМОВ НА МОБИЛЬНЫХ И НАСТОЛЬНЫХ ПЛАТФОРМАХ.**

Start from branch `web/kt589-godot-friendly-visual-refresh-2026-11-10`, PR #86, and verify commit `35276f4431d31313c1a610122ab8dc231b3332dd`. Keep changes on the branch; do not merge or deploy.
