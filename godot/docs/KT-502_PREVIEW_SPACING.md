# KT-502 — Preview label and piece separation

## Problem
On narrow portrait layouts, HOLD/NEXT labels and tetromino cells were drawn through the same vertical centerline. At 360px viewport width, the preview cells could visually collide with the label.

## Change
- Labels now occupy a dedicated upper-left lane.
- Tetromino previews are centered in a lower-right lane.
- Empty HOLD state indicator is moved to the lower lane as well.
- Piece size remains responsive to available card width.

## Validation targets
Inspect Classic and Block Run preview cards at 360x800 and 412x915, including wide and tall tetromino shapes. Verify labels remain readable and all cells stay inside the rounded card.

## Safety
No gameplay rules, touch gestures, board dimensions, campaign progression, wallet, or save behavior changed. Draft-only; no merge, deploy, or APK.
