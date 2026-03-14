# T1872 Troubleshoot Local Builder Dev Login 504

- [x] Hypothesis (Ordered Expected Solutions)
  - [x] The local dev backend is not exposing `/api/auth/dev-login` under the builder runtime after the recent portal/backend split, so the frontend proxy waits and returns `504`.
  - [x] The local frontend dev proxy is still targeting a stale backend port or route shape, causing the builder sign-in page to time out before the request reaches Actix.
  - [x] A recent auth-flow change introduced a blocking DB or step-up branch in builder dev-login that now hangs locally.
  - [x] Local environment variables for dev auth bootstrap changed during VPS work and now disable the builder dev-login path in `npm run dev`.

- [ ] Activity Log
  - [x] Read repo task/debug context and inspect builder/portal auth route wiring.
  - [x] Reproduce the `504` locally against the builder dev route and inspect backend/frontend logs.
  - [x] Patch the responsible auth or dev-proxy path.
  - [x] Verify with the narrowest relevant build and local backend launch-path checks.
  - [x] Trace the empty dashboard to legacy local project storage being ignored by the new snapshot-only dashboard scan.
  - [x] Patch the dashboard/snapshot loader to accept legacy `project.json` files and verify the backend compiles.
  - [x] Trace the remaining dashboard failure to builder/portal surface auto-selection plus overly expensive dashboard project scanning on the local dataset.
  - [x] Patch local builder surface selection to default to builder mode and optimize dashboard listing by using `summary.txt` metadata.

- [ ] Code Change Ledger
  - [x] `backend/Cargo.toml` — added `default-run = "backend"` so local `cargo run` and `cargo watch -x run` resolve to the builder binary after introducing the `portal` binary. Revert by removing the `default-run` line if the repo later adopts explicit `--bin` selection everywhere.
  - [x] `backend/src/api/project_snapshot.rs` — added `resolve_snapshot_path` with fallback from `project_snapshot.json` to legacy `project.json`, and updated `read_snapshot` to use it. Revert by removing the fallback helper if legacy builder data support is intentionally dropped.
  - [x] `backend/src/api/project_dashboard.rs` — changed dashboard listing to use the shared snapshot-path resolver so legacy projects are not skipped. Revert by restoring the direct `project_snapshot.json` existence check if only new-format projects should be listed.
  - [x] `backend/src/main.rs` — removed implicit local portal auto-selection from the builder binary so local `cargo run` defaults to builder APIs unless `APP_SURFACE=portal` is explicitly set. Revert by restoring the old auto-detect behavior if the builder binary must keep artifact-driven surface switching.
  - [x] `backend/src/api/project_dashboard.rs` — optimized dashboard project listing to read lightweight `summary.txt` metadata when present, avoiding multi-megabyte JSON parsing across the full local dataset on every dashboard open. Revert by restoring unconditional JSON parsing if the summary file stops being trustworthy.

- [x] Rollback Check
  - [x] Confirmed CLEAN or REVERTED non-working changes.

- [x] Context Handoff
  - [x] Local builder `npm run dev` initially returned `504` because the frontend proxy had no backend on `127.0.0.1:8080` once `backend` gained a second binary and bare `cargo run` no longer knew which binary to launch.
  - [x] The follow-up empty/failed dashboard state had two causes: the builder binary was auto-selecting the portal surface when `dist-portal` existed, and the dashboard listing path was parsing every large legacy project JSON instead of using cheap metadata.
  - [x] The final local fix set the builder binary as the default run target, forced local builder mode unless `APP_SURFACE` is explicitly set, restored legacy `project.json` compatibility, and made dashboard listing fast again by using `summary.txt` when available.
