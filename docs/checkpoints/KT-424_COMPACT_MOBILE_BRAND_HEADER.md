# KT-424 — Compact mobile brand header

Date: 2026-11-07  
Branch: `design/kt424-compact-mobile-brand-hero-2026-11-07`  
Base: KT-423 draft branch

## Finding
KT-422 preview screenshots showed that the home brand hero still consumed too much vertical space. The compact rules existed but lost to earlier duplicated `#menu.home-dashboard.home-dashboard` selectors with higher specificity.

## Change
- Adds a narrowly scoped mobile override matching the earlier selector specificity.
- Converts the hero to a compact horizontal brand lockup with smaller mark and wordmark.
- Keeps slogan and eyebrow readable.
- Leaves desktop layout unchanged and does not alter navigation or game logic.

## Verification
Capture iOS WebKit at 375x812 and Android Chromium at 393x873; confirm the three mode cards move higher, no clipping/overlap, and all navigation remains accessible.
No merge, deploy, or APK release.
