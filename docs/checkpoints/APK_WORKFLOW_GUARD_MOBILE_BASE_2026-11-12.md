# APK workflow guard on mobile feature base — 12 November 2026

- Branch: `mobile/golden-arena-adaptation-2026-11-03`
- Existing dependent Draft PR: [#49](https://github.com/MaiklLX/Tetrios.LX/pull/49)
- Removed the `pull_request: branches: [main]` and `push: branches: [main]` triggers from `.github/workflows/build-apk.yml`.
- Removed the `push: branches: [main]` trigger from `.github/workflows/release-apk.yml`.
- Both workflows retain `workflow_dispatch` only. No manual dispatch was made.
- This feature-branch update does not change `main`, does not build or release an APK, and does not alter existing artifacts or user data.
- The dependent PR #49 head branch has also been aligned to manual-only APK workflows, so the stacked branch no longer reintroduces automatic push builds/releases.
