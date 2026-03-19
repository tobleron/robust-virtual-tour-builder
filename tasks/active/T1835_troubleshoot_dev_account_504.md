# T1835 Troubleshoot Dev Account 504

## Objective
Determine why the `Use Dev Account` action is returning a `504` in the current development environment and identify whether the cause is frontend wiring, proxy timeout, backend route availability, or backend startup/runtime failure.

## Hypothesis (Ordered Expected Solutions)
- [ ] The frontend `Use Dev Account` button still posts to `/api/auth/dev-login`, but the backend is not currently running, so the dev proxy returns `504`.
- [ ] The backend dev server fails to boot in this checkout because of an unrelated compile/runtime issue, leaving the dev-login route unreachable.
- [ ] The frontend proxy target or auth transport is misconfigured, so requests to `/api/auth/dev-login` are timing out before reaching Actix.
- [ ] The dev-login route is conditionally registered and current environment flags disable it.
- [ ] The route responds, but a downstream auth/session/database operation is hanging long enough for the proxy to emit `504`.

## Activity Log
- [x] Re-read project docs/process and debug guidance.
- [x] Inspect frontend button wiring and backend route references for dev login.
- [x] Check recent backend logs for `/api/auth/dev-login` traffic.
- [x] Check current backend reachability and proxy path behavior.
- [x] Summarize root cause and smallest fix path.
- [x] Fix the backend compile blocker that prevented the local server from starting.
- [x] Verify backend boot plus direct `/health` and `/api/auth/dev-login` responses on March 11, 2026.

## Code Change Ledger
- [x] [backend/src/pathfinder/timeline.rs](backend/src/pathfinder/timeline.rs): fixed the `Option<&str>` vs `Option<&String>` comparison so the backend compiles and the dev server can boot again.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
The dev-login button still exists in the frontend site auth flow and the backend route `/api/auth/dev-login` is still registered in the development checkout. The `504` was caused by the frontend proxy targeting `127.0.0.1:8080` while no backend was listening there; the server was down because `backend/src/pathfinder/timeline.rs` failed to compile. That compile error is now fixed, `cargo check` passes, and direct requests to `GET /health` and `POST /api/auth/dev-login` both returned `200 OK` on March 11, 2026.
