# KT-540 — Campaign run lifecycle decision

## Final behavior (supersedes the earlier resume proposal)
- A campaign level is a single-session attempt. Leaving the level or closing/restarting the app does not resume its board, active piece, Hold state, or objective timer.
- A new app launch clears any legacy campaign-run checkpoint and opens the normal home screen. The player explicitly launches the current planet again; the run starts from its authored opening state.
- Manual pause remains an in-session pause. If the app is backgrounded and the process survives, the OS pause notification pauses the live in-memory run; returning to the still-running app requires Resume.
- If the process is terminated while backgrounded, the next launch starts the level from the beginning.
- Retry, return to route, planet completion, and switching to a standard mode clear any campaign-run checkpoint file.
- Campaign progression, completed planets, campaign marks, and reward receipts remain persistent in the separate campaign progression store. Only the transient level attempt restarts.

## Implementation and validation boundary
- The validated campaign-only checkpoint envelope/store remains available as an isolated utility and regression-tested format, but the live game no longer writes or restores it.
- Startup explicitly removes a checkpoint left by an earlier build, preventing an obsolete resume from being applied.
- OS-level background/foreground behavior still requires physical Android/iOS testing. CI can validate code paths and scene startup, not mobile process termination semantics.
- No public deployment, main merge or APK release.
