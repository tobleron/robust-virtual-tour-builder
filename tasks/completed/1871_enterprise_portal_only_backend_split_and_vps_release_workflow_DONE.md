# 1871 Enterprise Portal-Only Backend Split And VPS Release Workflow

## Objective

Turn the current surface-only portal separation into a real backend/runtime separation so the VPS builds and runs a slim portal-only release binary without compiling builder/export subsystems such as `headless_chrome`.

## Success Criteria

- Local builder workflow remains the default.
- A dedicated portal-only Rust binary exists and compiles without `headless_chrome`.
- Portal runtime no longer exposes builder/project/dashboard/media routes.
- VPS deployment workflow builds the portal release target only.
- Remote cleanup removes disposable build/package caches without touching portal data.

## Constraints

- Keep public portal URLs stable.
- Keep builder/editor/export workflows local-only.
- Do not delete local caches as part of this task.
- Do not delete VPS database or portal storage data.

## Implementation Notes

- Use one Rust package with feature-gated runtime slices.
- Keep `cargo run` builder-first by default.
- Add a dedicated portal binary and release deployment workflow for the VPS.
- Replace compile-time static dist assumptions with an explicit runtime dist-root contract.

## Verification

- `npm run build`
- `npm run build:portal`
- `cd backend && cargo check`
- `cd backend && cargo check --no-default-features --features portal-runtime --bin portal`
- `cd backend && cargo tree --no-default-features --features portal-runtime --bin portal | rg headless_chrome`
- VPS portal release build, restart, health check, and disk-usage before/after cleanup

## Activity Log

- [x] Feature-gate backend runtime slices and heavy optional dependencies.
- [x] Add dedicated portal binary and shared bootstrap.
- [x] Remove builder/dashboard/project/media routes from portal runtime.
- [x] Update portal scripts and VPS deployment workflow.
- [x] Rebuild portal release target on VPS and restart service.
- [x] Cleanup remote disposable build/package caches.

## Code Change Ledger

- [x] `backend/Cargo.toml`: added `builder-runtime`, `portal-runtime`, and `video-export` features; made `headless_chrome` optional; added dedicated `portal` binary.
- [x] `backend/src/lib.rs`: gated `pathfinder` behind `builder-runtime`.
- [x] `backend/src/services/mod.rs`: gated builder-only service modules.
- [x] `backend/src/api/mod.rs`: gated builder-only API modules.
- [x] `backend/src/api/media/mod.rs`: gated video/export modules behind `video-export` and added no-video fallback for teaser route.
- [x] `backend/src/api/config_routes.rs`: split builder vs portal API route registration and removed builder dashboard routes from portal runtime.
- [x] `backend/src/services/shutdown.rs`: split builder shutdown cleanup from portal shutdown cleanup.
- [x] `backend/src/bin/portal.rs`: added portal-only Actix entrypoint with explicit dist-root support.
- [x] `backend/src/api/health.rs`: removed builder-only geocoding dependency from portal-only build path.
- [x] `backend/src/services/portal.rs`: replaced shared media WebP dependency with local portal cover encoder.
- [x] `scripts/run-portal.sh`: switched local portal launcher to the dedicated portal binary.
- [x] `scripts/deploy-portal-vps.sh`: added VPS deployment workflow for portal-only builds and remote cache cleanup.

## Verification Notes

- [x] `cd backend && cargo check`
- [x] `cd backend && cargo check --no-default-features --features portal-runtime --bin portal`
- [x] `cd backend && cargo tree --no-default-features --features portal-runtime | rg headless_chrome` returned no matches.
- [x] `npm run build:portal`
- [x] `npm run build`
- [x] VPS cleanup removed the old unified `backend/target` plus disposable `npm` and `apt` caches, recovering about `7 GB`.
- [x] VPS portal-only release build completed after remote source correction and metadata-file cleanup.
- [x] `systemd` now runs `/opt/robust-vtb/current/backend/target/release/portal`.
- [x] `curl http://127.0.0.1:8080/api/health` returns `200 OK` on the VPS.
- [x] `curl -I http://www.robust-vtb.com/` returns `200 OK` from the VPS.
- [x] `curl -I http://robust-vtb.com/` returns `301` to `http://www.robust-vtb.com/`.

## Deferred Test Alignment

- Reuse [tasks/pending/1862_deferred_portal_integration_and_unit_test_alignment.md](tasks/pending/1862_deferred_portal_integration_and_unit_test_alignment.md) for any affected portal/backend test follow-up instead of rewriting tests during the structural split.
