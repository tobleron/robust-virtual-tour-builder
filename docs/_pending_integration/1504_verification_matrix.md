# Verification Matrix: Race Reliability Certification (Task 1504)

This matrix maps T1495 success criteria to specific verification steps and expected evidence.

| T1495 Success Criterion | Verification Method | Expected Evidence | Status |
| :--- | :--- | :--- | :--- |
| No reproducible race-induced navigation/simulation desync under CPU throttle | 100-run rapid interaction loop (manual/e2e) + 6x CPU throttle | Trace logs showing FSM state transitions and simulation move rejection during active nav. | [ ] |
| 100-run stress loop shows deterministic scene/highlight/pan sequencing | Automated e2e stress suite executing same sequence 100x | Pass/Fail report (100% pass required) | [ ] |
| No stale async callback mutates state after ownership change | Targeted unit tests + run-token instrumentation logs | "REJECTED_STALE_CALLBACK" logs in console/telemetry | [ ] |
| Backend-bound operations preserve operation identity and do not emit premature completion | End-to-end trace log audit for Project Load/Upload/Export | Logs showing consistent Operation ID from request to final lifecycle update | [ ] |
| No LONG_TASK_DETECTED bursts during active navigation caused by ambient jobs | Performance trace analysis during Navigation + Thumbnail Generation | Perf metrics showing long task count <= 2 during transition window | [ ] |

## Critical Module Ownership & Run-Token Status

| Module | Determinism Strategy | Stale Guard Implementation |
| :--- | :--- | :--- |
| `Simulation.res` | FSM-gated (IdleFsm) | `NavigationFSM` state check + `sceneId` match |
| `NavigationSupervisor.res` | Structured Concurrency (AbortSignal) | `AbortSignal` + `runId` validation |
| `SceneLoader.res` | Token-based loading | `loadId` checks in callbacks |
| `ViewerManagerIntro.res` | Effect-scoped guard | `sceneId` equality check in `useEffect` |
| `ThumbnailProjectSystem.res` | Ambient/Background policy | Interaction lock-gating via `Capability.Policy` |
| `AuthenticatedClient.res` | Correlation-ID propagation | Header injection + response metadata alignment |

## Stress Environment Profile
- **CPU**: 6x Throttle (Chrome DevTools / Playwright)
- **Network**: "Slow 3G" or 2000ms fixed latency
- **Ambient Load**: Constant background thumbnail generation (simulated)
