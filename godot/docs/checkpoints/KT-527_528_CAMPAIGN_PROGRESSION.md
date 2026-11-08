# KT-527 / KT-528 — Campaign Progression, Rewards and Persistence

Status: implemented on the Godot development branch. Draft PR #81 remains the review boundary.

## KT-527 — Campaign progression model
- Defines the complete 12-universe / 360-planet catalog.
- Each planet has a stable global ID, universe and local index, target-line objective, boss milestone flag and campaign-mark reward.
- Planet 010 / 020 / 030 in each universe are milestone nodes; planet 360 is the final campaign milestone.
- Only the current unlocked node can be completed. Objectives gate progression.
- Completion receipts prevent duplicate reward claims.
- Universe summaries report locked/current/completed state and completion count.
- Save snapshots validate contiguous progression, receipts and completion state before applying any changes.
- Legacy Web profile mapping imports `campaign.unlocked_node` and `campaign.marks` without re-awarding earlier nodes.

## KT-528 — Live gameplay and persistence
- Campaign map state is now driven by the progression model: completed planets, current planet and locked planets have distinct states.
- Planet detail shows the target-line objective and campaign-mark reward.
- Starting the current planet launches a dedicated Campaign session directly, without sending the player through the general mode selector.
- Clearing the planet target grants marks once, saves the campaign profile, and unlocks the next planet.
- The completion panel displays the reward and returns to the updated route.
- Campaign progress persists through Godot `ConfigFile` storage in `user://block_buddies_campaign_v1.cfg`.
- Campaign mode remains internal and does not appear as a fourth general game mode.

## Validation
- Godot Native Project Check **#356 passed** on commit `b38890f460230f20efd942eaba08ea595a444273`.
- Passed: Godot import and parse, main model tests, Web migration tests, campaign progression/persistence tests, all Block Run suites, live gameplay integration, visual capture and scene smoke test.
- Workflow artifact `block-buddies-visual-checks` (ID `13629297299`) includes:
  - `24-live-campaign-level.png`
  - `25-live-campaign-level-complete.png`
  - `26-live-campaign-progress.png`

## KT-529 — Varied missions and bounded difficulty
- Replaced the unbounded per-planet score grind with a capped chapter curve: small universe-level steps and gentle within-universe variation.
- Ordinary planets rotate between focused line-clear missions and score-only missions (for example, planets 005, 015 and 025). Score-only planets do not secretly require line clears or a timer.
- Every tenth planet is a boss with a combined line + score objective. Guardian, Champion and Final boss milestones have stronger quotas, but no artificial speed deadline.
- Difficulty values are bounded across all 360 planets; automated tests verify ceilings, soft universe transitions, mission variety, score-only completion and timer-free bosses.
- Planet detail, live HUD, progress bars and results now display the relevant objective type instead of assuming every mission is line-based.

## Staged limitations
- Fresh profiles begin at Planet 001; the rest of the 360-node route unlocks sequentially.
- The objective curve is now continuous, but individual non-boss planets do not yet have unique mechanics or authored modifiers.
- Bosses currently use stronger objective gates and time pressure; dedicated boss intro, HUD treatment, victory/failure presentation and visual capture coverage remain the next presentation pass.
- Legacy profile mapping is implemented at the campaign-store boundary; automatic Web localStorage-to-Godot profile migration remains a separate integration step.
- Physical-device verification remains required before release.

## Scope / safety
- Branch: `godot/kt493-gallery-validated-2026-11-08`.
- PR #81 remains Draft and unmerged.
- No changes to `main`, public deployment, backup/archive branch, or APK release.
