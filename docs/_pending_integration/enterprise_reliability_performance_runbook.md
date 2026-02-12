# Enterprise Reliability + Performance Runbook

## Scope
Task `1358` operational closeout for CI-enforced performance budgets and stress gates, aligned to SLO targets defined in `docs/_pending_integration/enterprise_slo_baseline.md` (Task `1349`).

Date: 2026-02-12

## Budget Gates

### 1) Bundle Gate
- Command: `npm run budget:bundle`
- Source: `scripts/check-bundle-budgets.mjs`
- Enforced thresholds:
  - Total JS bytes <= 4,500,000
  - Total gzip bytes <= 750,000
  - Largest chunk <= 2,000,000

Latest validated result:
- total_js_bytes: 4,178,567
- total_gzip_bytes: 663,818
- largest_chunk: `dist/static/js/index.js`
- largest_chunk_bytes: 1,756,480
- Status: PASS

### 2) Runtime Gate
- Commands:
  - `npm run test:e2e:budgets`
  - `npm run budget:runtime`
- Sources:
  - `tests/e2e/perf-budgets.spec.ts`
  - `scripts/check-runtime-budgets.mjs`
  - `artifacts/perf-budget-metrics.json`
- Enforced thresholds:
  - rapid navigation p95 <= 1500ms
  - rapid navigation long tasks <= 15
  - rapid navigation memory growth ratio <= 2.5
  - bulk upload latency <= 90,000ms
  - long simulation distinct active scenes >= 2
  - long simulation long tasks <= 30
  - long simulation memory growth ratio <= 2.2

Latest validated result (`artifacts/perf-budget-metrics.json`):
- rapidNavigation.p95Ms: 125
- rapidNavigation.longTaskCount: 2
- rapidNavigation.memoryGrowthRatio: 1
- bulkUpload.importedScenes: 120
- bulkUpload.latencyMs: 293
- longSimulation.distinctActiveScenes: 12
- longSimulation.longTaskCount: 0
- longSimulation.memoryGrowthRatio: 1
- Status: PASS

## SLO Alignment (Task 1349)

| SLO from 1349 | Baseline (1349) | Current Budgeted Result | Status |
|---|---:|---:|---|
| Scene Switching p95 < 1.5s | 850ms-1.2s (network), 120ms (cache) | 125ms | Meets |
| Frontend long tasks/session (target < 10 avg) | Noted as governance target | 2 (rapid nav), 0 (long simulation) | Meets |
| Upload pipeline reliability/latency governance | baseline established | 120 scenes imported, 293ms import latency in budget harness | Meets (budget harness) |
| Memory trend stability | 250MB@50 scenes, 600MB@200 scenes baseline note | growth ratio 1.0 in gated suites | Meets |

Notes:
- Runtime suite is intentionally deterministic and CI-friendly. Bulk import uses mocked import endpoint to remove backend/service flakiness from budget gating.
- Telemetry post failures to `localhost:8080` in budget mode do not invalidate budget metrics; metrics are captured directly in browser context and written to local artifact.

## CI Integration
- Workflow: `.github/workflows/ci.yml`
- Added gates:
  - build
  - bundle budget gate
  - Playwright Chromium install
  - runtime budget suite
  - runtime budget gate
- Any threshold breach returns non-zero and fails CI.

## Operator Procedure
1. Run `npm run build`.
2. Run `npm run budget:bundle`.
3. Run `npm run test:e2e:budgets`.
4. Run `npm run budget:runtime`.
5. If any command fails:
   - inspect `artifacts/perf-budget-metrics.json`
   - inspect Playwright trace in `test-results/`
   - fix regression or intentionally update thresholds with justification in PR

## Program Closeout
- Task `1358` acceptance criteria satisfied:
  - CI budget regressions fail.
  - Before/after mapping documented to Task `1349` SLOs.
  - Stress gates added for rapid navigation, bulk upload, and long session behavior.
- This evidence unblocks marking reliability/performance hardening milestone (`1348`) as complete from a budget-governance standpoint.
