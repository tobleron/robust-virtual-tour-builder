# T1863 Troubleshoot Local Portal Launch And Routing

## Hypothesis (Ordered Expected Solutions)

- [ ] The backend is not actually running in `APP_SURFACE=portal` mode, so `/portal-admin/signin` falls back to the wrong frontend shell or a missing dist.
- [ ] The portal frontend build output exists, but the backend static routing is serving the wrong `index.html` or missing portal assets.
- [ ] The route works, but admin sign-in fails because portal admin access is gated by internal auth and no suitable admin/dev path is configured.
- [ ] The portal-only API scope is missing a required route or session behavior, causing the frontend to render incorrectly after load.

## Activity Log

- [x] Start local portal server in background with `APP_SURFACE=portal`
- [x] `curl` portal routes and inspect returned HTML / status codes
- [x] If needed, inspect backend logs and narrow failing handler/static route
- [x] Apply minimal fix and re-run `curl` checks

## Code Change Ledger

- [x] `portal.index.html`: added a portal-only Rsbuild HTML template without builder bootstrap or Pannellum asset tags so the portal surface stops loading irrelevant scripts.
- [x] `rsbuild.portal.config.mjs`: switched the portal build to the dedicated portal template instead of the main builder HTML shell.
- [x] Verification: rebuilt `dist-portal`, then confirmed `/portal-admin/signin` serves the clean portal HTML shell from the background `APP_SURFACE=portal` server.

## Rollback Check

- [x] Confirmed CLEAN or REVERTED non-working troubleshooting edits

## Context Handoff

The portal subsystem was implemented with a separate `dist-portal` build and `APP_SURFACE=portal` backend mode. The user reported that the local portal URL did not work, so this troubleshooting pass is reproducing the startup path with a real background server and direct `curl` requests. The likely fault domain is static routing or auth gating rather than schema/build generation, because both `cargo check` and `npm run build:portal` already passed.
