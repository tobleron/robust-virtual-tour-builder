# Project Testing Strategy

This document consolidates standard operating procedures for verifying system resilience, optimistic updates, race reliability, and automated feature validations.

---

## 1. Safety Nets & Three-Tier Strategy

Our testing system is built on three pillars to ensure long-term maintainability:
1. **Unit Tests (Logic Guards)**: Verify mathematical and logical correctness of isolated functions. (e.g., `ColorPalette_v.test.res`)
2. **Smoke Tests (Boot Guards)**: Ensure major UI components boot and render without crashing. (e.g., `ViewerUI_v.test.res`)
3. **Smart Regression Tests (Bug Guards)**: Codify past bugs into permanent tests.

**Implementation**:
- Frontend tests run in JSDOM, using setup files (e.g., `tests/unit/*.setup.jsx`) and tiered mocking (global/partial/component).
- Backend tests use `cargo test`.
- All automated frontend suites run via: `npm run test:frontend`.

---

## 2. Optimistic Updates & Recovery Validation

### Rollback Testing
- **Scene Deletion Rollback**: Delete a scene while offline. Verify scene reappears and a warning notification is shown.
- **Hotspot Rollback**: Add a hotspot while offline. Verify hotspot is removed and warning is shown.

### Interruption Recovery Testing
- **Interrupted Save**: Start save, close tab, reopen app. Verify recovery prompt. Click "Retry All" and verify save completes.
- **Interrupted Upload**: Start image upload, force close browser, reopen app. Verify recovery prompt shows upload.

---

## 3. Race Reliability Certification (Task 1504)

We target strict race reliability against arbitrary user interaction speed or CPU throttling.

| Success Criterion | Verification Method | Expected Evidence |
| :--- | :--- | :--- |
| **No navigation/simulation desync under CPU throttle** | 100-run interaction loop (manual/e2e) + 6x CPU throttle | Trace logs showing FSM state transitions and simulation move rejection during active nav. |
| **Deterministic sequence** | Automated e2e stress suite executing 100x | Pass/Fail report (100% pass required) |
| **No stale async callback mutation** | Targeted unit tests + run-token instrumentation | `REJECTED_STALE_CALLBACK` logs |
| **Backend operations preserve identity** | Trace log audit for Load/Upload/Export | Consistent Operation ID from request to final update |
| **No LONG_TASK bursts** | Perf trace analysis during Navigation + Thumbnail Gen | Long task count <= 2 during transition window |

### Critical Module Run-Token Status
- `Simulation.res`: FSM-gated (`NavigationFSM` state check + `sceneId` match).
- `NavigationSupervisor.res`: Structured Concurrency (`AbortSignal` + `runId` validation).
- `SceneLoader.res`: Token-based loading (`loadId` checks in callbacks).
- `ThumbnailProjectSystem.res`: Interaction lock-gating via `Capability.Policy`.
- `AuthenticatedClient.res`: Correlation-ID header injection + response metadata alignment.

---

## 4. Feature Rollout Validation: Teaser CDP (Task 1515)

The CDP screencast is the primary capture transport for generating Video Teasers, replacing the 60Hz polling screenshot loop.

### Verification Flow (Fast Manual Test)
1. Run app `npm run dev` and load a test project (`x445.zip`).
2. Trigger teaser MP4 generation.
3. Observe progress and UI states (sidebar and builder overlays should be hidden, logo remains visible).
4. Inspect visual output:
   - Smooth continuous motion.
   - Proper crossfades.
   - No stuttery screenshot effect.
5. Check backend logs for `TEASER_CAPTURE_STATS` (capture mode should be `cdp`).

### Quality Targets
- `captured_fps`: > 45 on standard hardware.
- `duplicate_ratio`: < 0.20.
- `duration_drift_s`: Within ~5% of simulation timeline.

### Post-Migration Resilience
- **First-frame grace**: CDP capture waits for first frame readiness before interpreting autopilot.
- **Resilient Fallback**: Runtime failures degrade from `cdp` to `polling` capture when time budget remains.
- **MP4 Encoder Safety**: Capture viewport is normalized to even dimensions via FFmpeg filters.
