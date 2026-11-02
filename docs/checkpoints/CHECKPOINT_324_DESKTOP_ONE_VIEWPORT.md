# TETRIOS LX — CHECKPOINT 324
## Desktop one-viewport layout and campaign visibility

Date: 2026-11-02
Branch: `main`
Implementation commit: `657f29b906e07ebb47cb959c8dd9f113d01a0c26`

### User requirement
The PC web version must fit the open browser window at full-monitor size without requiring vertical scrolling on the main menu or gameplay screen. Primary navigation actions must remain visible, especially Campaign.

### Diagnosis
- The Campaign mode button was present in the HTML as `button.mode[data-mode="campaign"]`; its existing click handler was also present.
- The previous desktop overrides widened some individual containers but did not make the application a viewport-bounded layout.
- The top bar retained the original 620px maximum width.
- The old desktop CSS used multiple overlapping overrides and did not consistently size the main menu against the remaining viewport height.

### Changes
Added final desktop-only stylesheet `bb-desktop-single-viewport-v1` to `site/index.html`:
- Desktop app is constrained to `100dvh`, with a full-width top bar and a main content area sized to the remaining viewport.
- Main menu uses an explicit seven-row dashboard grid. Campaign, Block Run, and Daily Challenge are explicitly kept visible as three primary mode cards.
- Streak, Heroes, RPG, currency, daily quests, reset, shop, and statistics are each assigned explicit grid areas.
- Daily quests are compacted into three side-by-side items on desktop.
- Gameplay screen is viewport-bounded; the 10x23 board and a three-column side panel share the available height.
- Short-window and 901–1100px rules reduce spacing and sizing.
- Non-menu screens retain their own internal vertical scrolling where needed.
- Changes are limited to CSS inside `@media (min-width: 901px)`; mobile layout and gameplay JavaScript were not changed.

### Validation
- Confirmed campaign button markup and existing `[data-mode]` click handler are still present.
- New stylesheet is present in the saved file.
- CSS brace balance: 0.
- Style tag balance: 0.
- File size after change: 439,285 characters.
- Browser visual inspection has not yet been performed; do not treat the layout as visually verified until checked at common desktop sizes (1920×1080, 1366×768, and a short 1280×650 window).

### Actions at checkpoint creation
For implementation commit `657f29b906e07ebb47cb959c8dd9f113d01a0c26`, web deploy, debug APK build, and release APK build were still running. Check their final conclusions before reporting publication. Prior release APK workflow failures are unrelated to this CSS-only change and remain unresolved until a successful run is confirmed.

### Next verification
1. Open the deployed site on a desktop browser at 1920×1080 and 1366×768.
2. Confirm all three primary mode cards are visible, especially Campaign.
3. Confirm no page-level vertical scrollbar on the main menu or gameplay screen.
4. Check the game board and side rail fit simultaneously.
5. Check 901–1100px width and short-height behavior.
6. If anything is still clipped, inspect the exact viewport and adjust only the desktop stylesheet.

### Continuation phrase
`TETRIOS LX — КОНТРОЛЬНАЯ ТОЧКА 324. DESKTOP ONE-VIEWPORT: ПРОВЕРИТЬ, ЧТО ГЛАВНОЕ МЕНЮ И ИГРОВОЕ ПОЛЕ ПОЛНОСТЬЮ УМЕЩАЮТСЯ В ОДНОМ ОКНЕ БРАУЗЕРА; КНОПКИ КАМПАНИЯ, БЛОК-РАН И ЕЖЕДНЕВНЫЙ ВЫЗОВ ЯВНО ВИДНЫ. ПРОВЕРИТЬ 1920×1080, 1366×768, 1280×650 И ШИРИНУ 901–1100 PX. МОБИЛЬНУЮ ВЁРСТКУ И ИГРОВУЮ ЛОГИКУ НЕ МЕНЯТЬ.`
