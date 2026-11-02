# Checkpoint 323 — desktop layout correction v3

- Replaced the tall, loosely stacked desktop home layout with a compact three-column dashboard. Explicit grid areas now place every direct menu module: hero, APK download, section label, all three mode cards, visit streak, hero selector, RPG panel, currency panel, reset action, daily quests, shop and statistics.
- Reworked desktop gameplay layout so the 10×23 board frame uses a viewport-bounded height (54dvh, capped at 520px; shorter screens use 48dvh, capped at 390px) and remains centered beside the information rail. Reduced side-card sizing to prevent the arena from being pushed below the visible screen.
- All changes are scoped to desktop widths at 901px and above. No gameplay logic, canvas backing dimensions, controls logic or mobile CSS was edited.
- Source commits: `44234d393ccdd807eedd63a05df8a140210897bc` (layout correction) and `015d9b426120a65d89ff7de815e947e56e261790` (CSS nesting correction).
- CSS brace-balance check passed after the correction. The deployment for the final commit is queued/in progress; browser visual verification is still pending.

Control phrase: TETRIOS LX — CHECKPOINT 323. DESKTOP HOME: VERIFY ALL MODULES ARE VISIBLE IN THE 3-COLUMN DASHBOARD. DESKTOP GAME: VERIFY THE 10×23 PLAYFIELD IS CENTERED AND FULLY ABOVE THE VIEWPORT BOTTOM, WITH THE RIGHT INFORMATION RAIL BESIDE IT. TEST NORMAL AND SHORT WINDOWS AND 901–1100PX WIDTH. DO NOT CHANGE MOBILE LAYOUT OR GAMEPLAY LOGIC.
