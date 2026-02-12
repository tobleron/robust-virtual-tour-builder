# [1349] Baseline SLO + Observability Foundation

## Objective
Establish measurable reliability/performance baselines before refactors, and define SLO/SLI targets for enterprise operations.

## Scope
1. Define SLIs/SLOs for core flows:
   - Scene switch latency (p50/p95/p99)
   - Upload success/failure rate
   - Save/load latency + error rate
   - Frontend long tasks and memory trend
2. Standardize correlation identifiers across frontend and backend (`requestId`, `operationId`, `sessionId`).
3. Create baseline report and threshold contract to be enforced by later tasks.

## Target Files
- `src/utils/Logger.res`
- `src/utils/LoggerTelemetry.res`
- `src/systems/Api/AuthenticatedClient.res`
- `backend/src/metrics.rs`
- `backend/src/api/telemetry.rs`
- `docs/_pending_integration/enterprise_slo_baseline.md`

## Deliverables
1. SLO table with target and error budget.
2. Baseline measurements from current mainline behavior.
3. Correlation contract (fields + propagation rules).

## Verification
- `npm run build`
- `npm test`
- validate correlation IDs appear in frontend telemetry and backend request logs.

## Acceptance Criteria
- Baseline report exists and is reproducible.
- SLO thresholds are explicit and approved for CI gating tasks.
- No ReScript warnings.
