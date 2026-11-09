# KT-499 — Twelve galaxy cards and thirty-planet route

Date: 2026-11-08
Branch: `godot/kt493-gallery-validated-2026-11-08`
Status: Draft-only visual gallery.

## Atlas overview
- Reworked the 12 universe cards into a two-column grid for larger, more legible names and planet ranges.
- Restored exact original campaign names and ranges from the original `bbBiomes` data.
- Each universe spans 30 nodes; all 12 cover the full 001–360 campaign.
- Each card has a distinct palette and stylized model silhouette.

## Universe route
- Added a dedicated 30-node route screen for the selected universe.
- Nodes are arranged in a serpentine path with connecting lines.
- Every tenth node is marked as a special milestone/boss node.
- Current/locked states are visually distinct.
- The selected-world detail screen remains a separate destination.

## Brand
- Home header no longer contains TETRIOS.LX.
- The home top bar is profile/utility chrome.
- BLOCK BUDDIES is the single prominent wordmark in the home hero panel.

## Visual capture
The gallery capture suite now includes:
- 12-universe atlas
- 30-node universe route
- selected planet detail
- daily challenge calendar with per-date rule marker and short label
- compact home at 360x800

## Scope
All gallery screens are visual concepts. The existing production campaign contains the authoritative 12 biome/360 node progression and 3D model data; this work does not replace or modify that runtime, save data, unlock logic, daily rule assignment, calendar history, rewards, or wallet. No merge, deployment, or APK release.
