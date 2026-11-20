# KT-753 — Goal explanations and mode-scoped monster panel

**Date:** 2026-11-20  
**Branch:** `restore/kt752-godot-arena-heroes-2026-11-20`  
**Base:** `main`  
**Status:** implementation committed; visual and cross-platform verification pending.

## Changes

- Goal emblems in the arena are now real buttons with accessible labels and descriptions.
- Selecting an emblem pauses the active run and opens an explanation modal with the goal icon, title, plain-language instructions, and current progress.
- The resume action closes the modal and resumes the same run without resetting the board or progress.
- The Block Run encounter header is removed whenever the active mode is not `rogue`. This prevents a stale monster panel from carrying into Daily Challenge.
- Portrait objective ribbon and its inner pocket now use the full available width, removing the inherited inset that caused the panel to appear narrower than the lower HUD rail.

## Verification

- Re-run Mobile Arena Visual Preview for portrait geometry and controls.
- Re-run Cross-platform Visual Preview for desktop Chromium, iOS WebKit and Android Chromium.
- Confirm goal emblems pause/resume correctly.
- Confirm `#bbRogueEncounterTop` is present only in Block Run and absent in Daily Challenge.
- Do not merge until visual checks pass. No APK release is included.
