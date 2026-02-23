# T1533 - Troubleshoot production build label showing Development Build

- [ ] **Hypothesis (Ordered Expected Solutions)**
  - [ ] Startup flow does not regenerate `src/utils/Version.res` after auto-switch to `main`, leaving stale build label from previous branch.
  - [ ] Runtime `MODE/DEV` resolution in preview incorrectly reports development mode for `npm run start`.
  - [ ] Browser/service-worker cache serves stale bundle after code updates.

- [ ] **Activity Log**
  - [ ] Inspect version generation (`scripts/update-version.js`) and runtime usage (`src/utils/Version.res`).
  - [ ] Patch startup to force version sync on start.
  - [ ] Patch build-label source to use generated branch label for sidebar stability.
  - [ ] Verify with `npm run build` and production start health checks.

- [ ] **Code Change Ledger**
  - [ ] `scripts/start-prod.sh` - ensure version file is regenerated in start flow after branch switch and before build. (revert: restore previous start flow)
  - [ ] `scripts/update-version.js` - emit stable `buildInfo` from generated branch label to avoid preview env ambiguity. (revert: restore runtime mode resolver)
  - [ ] `src/utils/Version.res` - regenerated output from script changes. (revert: regenerate with old script)

- [ ] **Rollback Check**
  - [ ] Confirmed CLEAN or REVERTED non-working changes.

- [ ] **Context Handoff**
  - [ ] Issue reproduced as persistent `[Development Build]` on sidebar under `npm run start`. Planned fix ensures `start` refreshes version metadata after auto branch switch and removes runtime-mode ambiguity for this label. Validation includes production build and API-through-preview runtime health. If stale label persists after patch, remaining cause is service-worker/browser cache and should be cleared once.
