# T1897 Troubleshoot Dev Login Regression

## Objective
Restore working development login access in the current dev stack so the user can sign in locally again.

## Hypothesis (Ordered Expected Solutions)
- [x] The dev login route still exists, but its environment gate now evaluates to false in local development.
- [x] The dev login route is wired, but the dev account bootstrap/session issuance path is failing at runtime.
- [x] The frontend login flow no longer points at the dev login endpoint or no longer exposes the dev-login entry.
- [x] Recent auth refactoring removed or bypassed the expected local dev account/session behavior.
- [x] The trusted-device schema uses a global `device_token_hash` uniqueness rule that conflicts with the auth code's user-scoped trusted-device upsert.

## Activity Log
- [x] Read repo/debug context and inspect existing auth evidence.
- [x] Reproduce the dev-login failure against the local backend.
- [x] Inspect backend auth route wiring, env gating, and session creation path.
- [x] Inspect frontend login flow after confirming the backend route still existed.
- [x] Apply the minimal fix and verify local login works again.
- [x] Inspect backend auth logs after the new failure and confirm the trusted-device insert was hitting a database uniqueness constraint.
- [x] Compare the trusted-device Rust logic against the SQLite schema and confirm the code expected user-scoped uniqueness while the schema enforced global uniqueness.
- [x] Patch trusted-device persistence to use a real SQL upsert and add a migration to make trusted-device uniqueness user-scoped.
- [x] Re-run the backend so the migration applies and verify `POST /api/auth/dev-login` returns `200 OK` again.

## Code Change Ledger
- [x] [backend/.env](backend/.env): re-enabled local dev auth bootstrap with `ALLOW_DEV_AUTH_BOOTSTRAP=true`.
- [x] [src/site/PageFrameworkContent.js](src/site/PageFrameworkContent.js): restored a local-only `Use Dev Account` shortcut on the sign-in page.
- [x] [src/site/PageFrameworkAuth.js](src/site/PageFrameworkAuth.js): wired the restored shortcut to `POST /api/auth/dev-login`, store the returned token, and redirect to the dashboard.
- [x] [backend/src/api/auth_step_up_devices.rs](backend/src/api/auth_step_up_devices.rs): replaced the two-step trusted-device lookup/insert with an atomic `ON CONFLICT(user_id, device_token_hash)` upsert.
- [x] [backend/migrations/20260320152254_trusted_devices_user_scoped.sql](backend/migrations/20260320152254_trusted_devices_user_scoped.sql): rebuilt `trusted_devices` so uniqueness is enforced per user/device pair instead of globally by `device_token_hash`.

## Rollback Check
- [x] Confirmed CLEAN. The final changes are intentional and verified; temporary standalone backend probing can be stopped after verification.

## Context Handoff
- [x] Root cause was threefold: the backend dev-login gate was disabled because `ALLOW_DEV_AUTH_BOOTSTRAP` was missing from `backend/.env`, the sign-in UI no longer exposed the direct dev-login shortcut even though the backend route still existed, and the trusted-device schema enforced a global `device_token_hash` uniqueness rule that contradicted the auth code's per-user trusted-device logic. After re-enabling the env flag and restoring the local-only `Use Dev Account` button, the remaining failure reproduced as `UNIQUE constraint failed: trusted_devices.device_token_hash`, which was resolved by making `trusted_devices` unique on `(user_id, device_token_hash)` and using an atomic SQL upsert. Verification passed with `cargo build`, a fresh backend start that applied the migration, and a direct `POST /api/auth/dev-login` returning `200 OK`; `npm run build` remained blocked only by an already-running ReScript watcher.
