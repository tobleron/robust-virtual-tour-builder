# [1348] Enterprise Architecture Hardening Program (Reliability + Performance)

## Priority
P0 (Critical)

## Objective
Upgrade the web app architecture to enterprise-grade reliability and performance standards by hardening concurrency control, state boundaries, API resilience, persistence safety, observability, and performance budgets across frontend (ReScript) and backend (Rust).

This task is implementation-focused and should be executed as a phased architecture program, not a single patch.

## Context (Why This Task Exists)
Current architecture is strong but still has high-risk scaling/reliability gaps for enterprise workloads:

1. Async lifecycle ownership is split across multiple timers/callback chains (`SceneLoader`, `SceneTransition`, `Simulation`, `NavigationController`) with stale-callback risk under rapid user interaction.
2. Global bridge coupling remains broad (`AppStateBridge` access from many systems/components), which weakens domain isolation and deterministic behavior under concurrency.
3. Retry/notification behavior in API client can still create noisy operator/user signals during network degradation.
4. Telemetry/metrics are present but not yet structured as SLO-grade golden signals (latency/error/saturation by endpoint + flow correlation).
5. Backend resilience/security posture needs production hardening alignment (headers/session/cors/rate-limits/env handling and middleware guarantees under abnormal load).
6. Performance governance (bundle/runtime/memory/long-task budgets) is not fully enforced as a CI gate.

## Enterprise Target State
1. Deterministic async orchestration: stale work cannot mutate active state.
2. Domain-sliced state boundaries: systems stop depending on ad-hoc global reads.
3. Unified reliability contracts for API calls: idempotent retries, bounded backoff, cancellation-safe semantics.
4. Full observability: correlated frontend-backend traces + actionable SLIs/SLOs.
5. Production-safe backend defaults with strict, environment-aware controls.
6. Enforced performance budgets and regression gates in CI.

## Implementation Tracks

### Track A: Concurrency & Async Lifecycle Unification
#### Scope
- Replace timer-fragmented completion paths with lifecycle-owned run tokens (epoch/runId).
- Make navigation/scene/simulation completion idempotent and stale-safe.

#### Required Changes
- `src/systems/Navigation/NavigationSupervisor.res`
- `src/systems/Scene/SceneLoader.res`
- `src/systems/Scene/SceneTransition.res`
- `src/systems/Simulation.res`
- `src/systems/Navigation/NavigationController.res`

#### Acceptance Criteria
- No stale callback can dispatch completion/error for superseded runs.
- Rapid scene-switching + active simulation cannot produce double-complete/stuck states.
- Navigation completion has exactly one authoritative owner.

---

### Track B: State Architecture Boundary Hardening
#### Scope
- Reduce direct `AppStateBridge.getState/dispatch` dependence in non-bootstrap paths.
- Route domain mutations through explicit reducer actions + narrow service interfaces.

#### Required Changes
- `src/core/AppStateBridge.res`
- `src/core/GlobalStateBridge.res` (deprecation cleanup)
- `src/core/AppContext.res`
- `src/systems/TeaserLogic.res`
- `src/components/VisualPipeline.res`
- `src/components/UploadReport.res`

#### Acceptance Criteria
- Critical runtime flows (navigation/upload/simulation/teaser) use explicit injected state access patterns.
- `GlobalStateBridge` is removed from runtime-critical call paths or fully decommissioned.

---

### Track C: API Reliability Contracts & Failure Semantics
#### Scope
- Standardize request policies: retry classes, backoff caps, timeout classes, cancellation classes, idempotency rules.
- Replace noisy per-attempt user notifications with deduped incident-level lifecycle feedback.

#### Required Changes
- `src/systems/Api/AuthenticatedClient.res`
- `src/utils/Retry.res`
- `src/utils/RequestQueue.res`
- `src/core/NotificationManager.res`
- `src/core/NotificationTypes.res`
- `src/systems/Resizer/ResizerUtils.res`

#### Acceptance Criteria
- One user-visible notification chain per network incident.
- Retries never continue after explicit abort.
- Request queue has bounded behavior under burst load.

---

### Track D: Persistence & Recovery Durability
#### Scope
- Guarantee crash-safe, resumable operations for upload/export/project operations.
- Enforce schema versioning and migration guarantees for IndexedDB/session payloads.

#### Required Changes
- `src/utils/OperationJournal.res`
- `src/utils/RecoveryManager.res`
- `src/utils/PersistenceLayer.res`
- `src/core/JsonParsersDecoders.res`
- `src/core/JsonParsersEncoders.res`

#### Acceptance Criteria
- Interrupted operations replay deterministically with no duplicate side effects.
- Persistence migration path is versioned and verified.
- Recovery prompt reflects true resumability state.

---

### Track E: Backend Production Hardening
#### Scope
- Enforce production-safe defaults for CORS, session handling, headers, timeouts, rate limits, and path/temp handling.
- Strengthen middleware behavior for quota tracking, request tracking, and graceful shutdown under load.

#### Required Changes
- `backend/src/main.rs`
- `backend/src/startup.rs`
- `backend/src/middleware.rs`
- `backend/src/services/upload_quota.rs`
- `backend/src/services/shutdown.rs`
- `backend/src/api/utils.rs`

#### Acceptance Criteria
- Environment-sensitive configuration is explicit and safe-by-default.
- No permissive production fallback for auth/session/security headers.
- Graceful shutdown completes active request drain within configured SLO.

---

### Track F: Observability, SLOs, and Diagnostics
#### Scope
- Define golden signals and SLOs for critical user journeys.
- Add request/operation correlation from frontend logs to backend traces/metrics.

#### Required Changes
- `src/utils/Logger.res`
- `src/utils/LoggerTelemetry.res`
- `src/systems/Api/AuthenticatedClient.res`
- `backend/src/metrics.rs`
- `backend/src/api/telemetry.rs`

#### Acceptance Criteria
- SLIs available for: scene-switch latency, upload pipeline success rate, project save/load latency, error rate, saturation.
- Request IDs and operation IDs are end-to-end correlated.
- Alerting thresholds are defined for SLO burn.

---

### Track G: Performance Governance & Budget Gates
#### Scope
- Establish hard budgets for bundle size, TTI, interaction latency, memory, and long tasks.
- Add automated regression gates for performance-sensitive flows.

#### Required Changes
- `rsbuild.config.mjs`
- `playwright.config.ts`
- `tests/e2e/*` (performance + stress specs)
- `scripts/*` (budget verification scripts)

#### Acceptance Criteria
- CI fails on budget regressions beyond agreed thresholds.
- Load/perf runs include rapid navigation, bulk upload, prolonged simulation.
- Performance report is generated per release candidate.

## Verification Matrix
1. Build integrity:
   - `npm run build`
   - `cd backend && cargo build --release`
2. Correctness:
   - `npm test`
   - `npm run test:e2e`
3. Reliability stress:
   - rapid scene switching, cancel/retry storms, backend temporary failures, offline/online churn.
4. Performance:
   - bundle budget checks
   - runtime memory and long-task thresholds
5. Observability:
   - validate correlated request IDs in frontend logs, backend traces, and metrics.

## Deliverables
1. Architecture hardening implementation across Tracks A-G.
2. Updated architecture docs:
   - `MAP.md`
   - `DATA_FLOW.md`
3. Operational runbook + SLO dashboard specification in:
   - `docs/_pending_integration/enterprise_reliability_performance_runbook.md`

## Completion Criteria
This task is complete only when:
1. All acceptance criteria in Tracks A-G are met.
2. Build/tests/perf gates pass with zero ReScript warnings.
3. Documentation and operational runbook are updated and usable by engineering + operations teams.
