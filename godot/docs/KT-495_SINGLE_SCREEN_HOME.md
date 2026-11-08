# KT-495 — One-screen mobile command center

Date: 2026-11-08
Branch: `godot/kt493-gallery-validated-2026-11-08`
Status: Draft-only visual implementation.

## Layout intent
The home screen is a single viewport, not a scrolling dashboard. It prioritizes:
1. Brand / Buddy identity and compact resource glance.
2. Three primary modes: Campaign, Block Run, Daily Challenge.
3. Three daily mission progress rows.
4. Visit streak.
5. Three compact destinations: Heroes, Shop, Upgrades.
6. Wallet and lifetime statistics.
7. Persistent bottom navigation.

## Responsive treatment
- 720x1280: roomier portrait composition.
- 360x800 and similarly narrow/short portrait sizes: dedicated compact composition with smaller cards, shorter labels, thin progress bars and icon tiles. The compact variant is designed around the available height and leaves the bottom navigation visible.
- No scrolling container is used in the home concept.

## Interaction and system boundaries
This is still a visual gallery, not a connected production menu. Labels, balances, mission progress and streak are illustrative. The campaign map, daily calendar, shop inventory, currency wallet, profile statistics and save data are not wired here.

## Gameplay regression guard
The dedicated DROP gutter remains separate from the board gesture area. Board tap continues to rotate; swipe down remains the gesture for hard drop. The dedicated DROP hit target is tested independently. Restarting Block Run also resets the shared mode lifecycle so the new run accepts input.
