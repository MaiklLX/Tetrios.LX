# KT-427.13 — touchscreen preview rerun

- Parent Draft PR: [#76](https://github.com/MaiklLX/Tetrios.LX/pull/76)
- Parent code/checkpoint SHA: `a33174ec979217644d0f05d04c6086dfc3e73500`
- Prior run [43592769174](https://github.com/MaiklLX/Tetrios.LX/actions/runs/43592769174) exposed a WebKit `locator.tap()` timeout on Pause at 375×812. The parent now uses `page.touchscreen.tap()` at a verified element center, with an explicit hit-test before dispatch and state assertions after each action.
- This branch adds only a validation note so the Cross-platform Visual Preview workflow runs against the updated parent snapshot. Review the resulting artifact and logs before accepting the change.

Acceptance: touchscreen input must complete Hold → Pause → Resume → Drop on iOS WebKit and Android Chromium mobile targets; no hit-test failures, page errors or state-transition failures. This remains browser automation, not physical-device validation. No gameplay runtime, save data, main, deployment or APK changes.
