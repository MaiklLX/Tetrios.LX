# KT-538 — Campaign-only Cargo Hook live integration

- Date: 2026-11-09.
- Branch: `godot/kt493-gallery-validated-2026-11-08`; PR #81 remains Draft/open/unmerged.
- Connected the approved five-cell Cargo Hook to the real campaign launch path through `BlockBuddiesCampaignPieceRuntime`; Planet 031 (Universe 02, «Караван звёзд») is the explicitly authored entry point.
- Ordinary campaign planets launch with a standard four-cell piece in the same isolated campaign runtime. Planet 031 launches with the Cargo Hook as its first active piece; after it locks, the runtime returns to the standard seven-piece bag. Hold, rotation, movement, soft drop, hard drop, gravity, line clearing, ghost and previews route through campaign runtime state.
- Added the special-piece label to Planet 031 detail before launch. The live Cargo Hook uses the same cyan body and gold fastener treatment as the approved standalone preview.
- Campaign launch and retry no longer reset the shared Classic model. The live board, counters, input routing and preview rendering switch to the campaign runtime only while `campaign_run_active`; non-campaign input continues to use the shared standard model.
- Added `campaign_live_integration_test.gd`: exercises the real Planet 001 launch, campaign retry, authored Planet 031 launch, special rotation/drop, standard-piece continuation, shared-model immutability, and standard-mode input routing.
- Updated visual capture regression to use campaign runtime counters and capture `28-campaign-cargo-hook-planet-detail.png` and `29-campaign-cargo-hook-live-arena.png`.
- Validation: **PASS** — Godot Native Project Check run [#42524193502](https://github.com/MaiklLX/Tetrios.LX/actions/runs/42524193502) on commit `13ac1126f9c38f22d0c854ff40381ad57fd22d2b`; all 23 workflow stages passed, including main parse, the new live integration test, all Classic/Web migration/Campaign/Block Run suites, screenshot capture/upload and scene smoke test.
- Visual artifact: `block-buddies-visual-checks`, uploaded by run #42524193502. The two new campaign captures show the Planet 031 preview and live arena.
- Scope boundary: the Cargo Hook is used only in Campaign. It is not added to Classic, Sprint/Marathon, Block Run, the shared seven-bag, or standard save schema. No main merge, public deployment, APK build/release, or physical-device claim.
- Next: KT-539 should address campaign Hold/preview polish and campaign-only persistence/recovery contracts before broader authored special-piece rollout. Keep the feature gated to Campaign and retain mode-isolation tests.
