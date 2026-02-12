# Runtime budget presets and expectations

## Purpose
`check-runtime-budgets.mjs` and `tests/e2e/perf-budgets.spec.ts` now share a single source of truth to determine thresholds. The goal is to keep *strict* thresholds for production-like runs while automatically relaxing budgets for sandbox or heavy CI environments, plus allowing direct overrides when needed.

## Presets
- **baseline** – applied when `NODE_ENV=production` or when `BUDGET_PRESET=baseline`. This mirrors the production SLA targeting lower long-task counts (15 for rapid navigation) and tighter memory growth ratios.
- **sandbox** – the default for local development or CI (`NODE_ENV` not `production` and no preset override). It raises headroom where noisy instrumentation could otherwise trip the budget (e.g., rapid navigation long-task ceiling of 25, bulk upload latency of 120 s, simulation long-task cap of 40).

| Metric | Baseline | Sandbox/CI | Env override variable |
| --- | --- | --- | --- |
| Rapid navigation p95 (ms) | 1 500 | 1 600 | `BUDGET_MAX_RAPID_NAV_P95_MS` |
| Rapid navigation long tasks | 15 | 25 | `BUDGET_MAX_RAPID_NAV_LONG_TASKS` |
| Rapid navigation memory growth ratio | 2.2 | 2.8 | `BUDGET_MAX_RAPID_NAV_MEMORY_RATIO` |
| Bulk upload latency (ms) | 90 000 | 120 000 | `BUDGET_MAX_BULK_UPLOAD_MS` |
| Simulation distinct scenes | ≥2 | ≥2 | `BUDGET_MIN_SIMULATION_DISTINCT_SCENES` |
| Simulation long tasks | 30 | 40 | `BUDGET_MAX_SIMULATION_LONG_TASKS` |
| Simulation memory growth ratio | 2.2 | 3.0 | `BUDGET_MAX_SIMULATION_MEMORY_RATIO` |

## Overrides & detection
1. `BUDGET_PRESET` can be set to `baseline` or `sandbox` to forcibly choose a preset regardless of `NODE_ENV`.
2. Each metric also accepts an override environment variable (listed above) if finer control is required.
3. When running `npm run budget:ci` from the pipeline, the default is `sandbox` (since `NODE_ENV` is typically `development`/`test` there); production can be simulated by exporting `NODE_ENV=production` or explicitly setting `BUDGET_PRESET=baseline` before running the budget script.

## Verification
- Running `npm run budget:ci` in a CI-like environment should succeed thanks to the sandbox preset. The script log will print which preset is active and the thresholds being applied.
- When validating a release on production hardware, set `NODE_ENV=production` (or `BUDGET_PRESET=baseline`) and re-run `npm run budget:runtime` to ensure the strict baseline still passes.
