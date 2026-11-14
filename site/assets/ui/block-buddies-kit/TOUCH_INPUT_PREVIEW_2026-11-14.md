# KT-427.12 — touchscreen preview validation gate

- Date: 2026-11-14
- Parent Draft PR: [#76 — KT-427: restore BLOCK BUDDIES pixel brand identity](https://github.com/MaiklLX/Tetrios.LX/pull/76)
- Parent branch: `design/kt427-block-buddies-brand-identity-2026-11-07`
- Parent code/checkpoint HEAD: `f3fd6312cf6e51db5789234e592c99e6f96e7df0`
- This branch adds only this validation record. It intentionally inherits the parent PR's updated preview workflows and Playwright control tests.

## What the workflows must prove

- Mobile Arena Visual Preview: at 375×812 and 412×915, Hold, Pause and Drop remain visible, enabled, pointer-interactive and center-hit-testable; Resume is visible and hit-testable while paused.
- Hold, Drop, Pause and Resume are activated with Playwright touchscreen taps in the mobile context, not `HTMLElement.click()`.
- Pause → Resume returns to the active arena without page errors.
- Cross-platform Visual Preview: mobile targets use touchscreen taps; desktop uses mouse clicks. Existing mobile gesture, 2D arena, orientation guard, geometry and overflow assertions remain active.
- Inspect both fresh workflow artifacts before accepting the touch-input change.

## Acceptance boundary

This stacked Draft PR is a validation vehicle for the latest parent snapshot. A green browser run does not establish physical iPhone/Android behavior. No gameplay runtime, balance, persistence, user data, main branch, deployment or APK is changed.
