# T1909 Troubleshoot Export Packaging Logo Progress Stall

- [ ] **Hypothesis (Ordered Expected Solutions)**
  - [ ] The export progress mapper pins the UI at `3%` for the entire branding/logo packaging phase while later toast copy advances independently, so the progress bar is stale rather than the export actually being stuck.
  - [ ] Backend export packaging is doing additional asset scanning or logo normalization work during the `packaging_logo` phase, but the frontend still treats it as a fixed early-stage bucket.
  - [ ] ETA / connection-verification toast updates come from a different lifecycle channel than the export progress bar, so the two signals have drifted out of sync.
  - [ ] Recent export-stage additions changed the phase ordering or names, and the frontend no longer maps the backend phase updates correctly.

- [ ] **Activity Log**
  - [x] Read export orchestration and progress-reporting code paths in frontend and backend.
  - [x] Identify the source of `packaging logo @ 3%` and the toast messages shown during export.
  - [x] Reproduce with the narrowest relevant build/runtime checks.
  - [x] Patch the progress mapping or phase reporting so the progress bar reflects actual export work.
  - [x] Verify export progress behavior and run `npm run build`.

- [ ] **Code Change Ledger**
  - [x] [src/systems/Exporter.res](src/systems/Exporter.res) — replaced the frozen `3%` logo bucket with bounded logo sub-progress reporting across the `3%`→`7%` range. Revert by removing `reportLogoPhaseProgress` and restoring the single fixed `progress(3.0, ...)` call.
  - [x] [src/systems/Exporter/ExporterPackaging.res](src/systems/Exporter/ExporterPackaging.res) — threaded logo-phase progress callback into the packaging facade. Revert by removing the `~reportProgress` parameter pass-through.
  - [x] [src/systems/Exporter/ExporterPackagingAssets.res](src/systems/Exporter/ExporterPackagingAssets.res) — added progress checkpoints for preparing, downloading, optimizing, attaching, and default-logo fallback stages. Revert by removing those `reportProgress` calls and the extra parameter.
  - [x] [tests/unit/Exporter_v.test.res](tests/unit/Exporter_v.test.res) — updated direct `appendLogo` test call site to satisfy the new callback parameter. Revert by removing the no-op callback if the signature is rolled back.

- [ ] **Rollback Check**
  - [x] Confirmed CLEAN or REVERTED non-working changes.

- [ ] **Context Handoff**
  - [ ] Export progress appears visually stalled at `3%` during `packaging logo`, while toast copy advances to later operational messages like connection verification and ETA calculation.
  - [ ] Investigation must compare frontend progress mapping against backend export phase emission to determine whether this is a UI mapping bug or a genuinely slower backend phase.
  - [ ] If the context window fills, continue by checking `src/systems/Exporter.res`, export progress helpers, and backend packaging/reporting files under `backend/src/services/project/`.
