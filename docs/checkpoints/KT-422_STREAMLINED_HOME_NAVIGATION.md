# KT-422 — Streamlined home navigation

Date: 2026-11-07  
Branch: `design/kt422-streamlined-home-navigation-2026-11-07`  
Base: KT-421 draft branch  
Status: first navigation prototype prepared; visual verification pending

## Findings
The current home screen presents three primary game modes, followed by full-height daily quests, visit streak, hero progression, resources, statistics, card library, APK download, shop, and reset controls. The result is a long vertical dashboard where play destinations compete with secondary progression.

## Prototype changes
- Kept Campaign, Block Run, and Daily Challenge as the first three primary destinations.
- Grouped daily quests and visit streak into a collapsed, accessible drawer: “ЗАДАНИЯ И СЕРИЯ”.
- Kept the Heroes destination visible as a direct action.
- Grouped hero RPG details, currency, and run statistics into a collapsed drawer: “ПРОГРЕСС И РЕСУРСЫ”.
- Kept the card library, APK download, shop, and reset entry points available; no feature was deleted.
- Existing elements are moved, not recreated; IDs and their existing event handlers are preserved.
- No gameplay rules, save keys, rewards, or mode logic changed.

## Verification required
- Confirm all three mode buttons remain visible and work.
- Confirm daily quests render/update while inside the closed drawer and display correctly when opened.
- Confirm hero progression, currency, and statistics remain intact when the progress drawer opens.
- Confirm library, shop, APK download, and reset controls remain reachable.
- Capture desktop and phone menu screenshots; inspect vertical length, spacing, clipping, and focus behavior.
- Do not merge, deploy, or produce an APK without explicit approval.
