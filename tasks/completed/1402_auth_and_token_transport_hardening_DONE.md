# 1402: Security - Auth Surface and Token Transport Hardening

## Objective
Close high-risk authentication and token transport gaps across frontend and backend.

## Context
Current implementation exposes multiple risky paths:
- `backend/src/api/mod.rs` exposes `/api/admin/shutdown` without auth middleware.
- `backend/src/api/utils.rs` executes shutdown directly in `trigger_shutdown`.
- `backend/src/auth.rs` accepts `token` in query string and supports `dev-token` bypass when `BYPASS_AUTH=true`.
- `src/systems/ProjectSystem.res` and `src/systems/ProjectManagerUrl.res` append `?token=...` to project file URLs.
- `src/systems/Api/AuthenticatedClient.res` injects `dev-token` fallback automatically when token is absent.

## Suggested Action Plan
- [ ] Protect `/api/admin/shutdown` with strong auth + explicit authorization (admin role or signed one-time secret).
- [ ] Remove query-string token authentication from `backend/src/auth.rs` (Authorization header/cookie only).
- [ ] Remove frontend URL token propagation (`tokenQuery`) from project file URL rebuilding.
- [ ] Replace unconditional `dev-token` fallback with explicit dev-only behavior guarded by environment checks.
- [ ] Fail fast on unsafe auth config in production (e.g., `BYPASS_AUTH=true` should abort startup).
- [ ] Add audit logging for privileged endpoints (who requested, request id, outcome).

## Verification
- [ ] `rg -n "\?token=|token param|dev-token|BYPASS_AUTH" src backend/src` returns only approved dev/test references.
- [ ] Unauthorized call to `POST /api/admin/shutdown` returns `401/403` in production profile.
- [ ] Project media loads successfully without token-in-URL pattern.
- [ ] `cd backend && cargo test` passes auth and middleware tests.
- [ ] `npm run res:build` and `npm run build` pass.
