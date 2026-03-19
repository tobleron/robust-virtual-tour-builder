# T1886 Troubleshoot Dev Account Login 504

## Hypothesis
- [ ] The dev login route is timing out while waiting on an upstream portal/backend dependency.
- [ ] The dev login request is hitting a wrong or stale base URL in the dev portal frontend, causing a gateway timeout at the reverse proxy.
- [ ] A dev-only auth/bootstrap shortcut is disabled or misconfigured, so login falls through to a slow fallback path.
- [x] The backend was failing before bind because a SQLite migration used an unsupported `ALTER TABLE ... ADD COLUMN ... DEFAULT CURRENT_TIMESTAMP`.

## Activity Log
- [ ] Trace the dev-account login request path from frontend to backend.
- [ ] Inspect portal/auth route handlers and any proxy/reverse-proxy configuration involved in dev login.
- [ ] Check for local/server logs around the 504 response and identify the component timing out.
- [ ] Verify whether the issue reproduces with the backend running directly and with the portal dev account flow.
- [x] Reproduced the failure by running `cargo run` directly; startup aborted during SQLite migration `20260318000001_portal_assignment_updated_at`.
- [x] Patched the migration to use a nullable add-column plus backfill update.
- [x] Verified the backend now binds to `0.0.0.0:8080`, `/health` returns `200`, and `POST /api/auth/dev-login` returns `200`.

## Code Change Ledger
- [x] `backend/migrations/20260318000001_portal_assignment_updated_at.sql`: replaced unsupported `ADD COLUMN ... DEFAULT CURRENT_TIMESTAMP` with SQLite-compatible nullable column plus backfill update. Revert by restoring the prior single-line migration.

## Rollback Check
- [x] Confirmed CLEAN before the migration fix; rollback path is to restore the original migration statement if needed.

## Context Handoff
- Dev-account login was returning HTTP 504 because the backend never bound to `8080`.
- The blocker was a SQLite migration crash during startup, not the dev-login handler itself.
- The backend now starts successfully and the dev-login endpoint works; keep the task active until the user approves archiving.
