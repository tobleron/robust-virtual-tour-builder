# Performance & Metrics

## 1. Core Web Vitals Targets
To ensure a commercial-grade user experience, the Virtual Tour Builder targets the following performance thresholds:

| Metric | Target | Description |
| :--- | :--- | :--- |
| **LCP (Largest Contentful Paint)** | `< 2.5s` | Time until the main panorama viewer is visible. |
| **FID (First Input Delay)** | `< 100ms` | Responsiveness to the first user interaction (click/tap). |
| **CLS (Cumulative Layout Shift)** | `< 0.1` | Visual stability of the UI overlay during loading. |

**Telemetry & Logging**:
- **Trace Level**: `Info` (default), `Debug/Trace` (configurable via `RUST_LOG`).
- **Metrics**: Prometheus endpoint exposed at `/metrics` (Backend).

## 2. Optimization Strategies
1. **Lazy Loading**: Only the initial scene is fully loaded; neighbors are preloaded in the background.
2. **WebP Fallback**: Images are automatically converted to WebP for reduced bandwidth usage.
3. **Rust Backend**: Heavy image processing (resizing, encoding) is offloaded to the Rust thread pool.

---

## 3. Runtime Budget Presets & Environment Expectations

**Purpose**: Keep *strict* thresholds for production-like runs while relaxing budgets for sandbox/heavy CI environments.

### Presets
- **baseline** – Applied when `NODE_ENV=production` or `BUDGET_PRESET=baseline`. Mirrors production SLA targeting lower long-task counts.
- **sandbox** – Default for local development or CI. Raises headroom where noisy instrumentation could trip the budget.

| Metric | Baseline | Sandbox/CI | Env override variable |
| --- | --- | --- | --- |
| Rapid navigation p95 (ms) | 1 500 | 1 600 | `BUDGET_MAX_RAPID_NAV_P95_MS` |
| Rapid navigation long tasks | 15 | 25 | `BUDGET_MAX_RAPID_NAV_LONG_TASKS` |
| Rapid navigation memory growth ratio | 2.2 | 2.8 | `BUDGET_MAX_RAPID_NAV_MEMORY_RATIO` |
| Bulk upload latency (ms) | 90 000 | 120 000 | `BUDGET_MAX_BULK_UPLOAD_MS` |
| Simulation distinct scenes | ≥2 | ≥2 | `BUDGET_MIN_SIMULATION_DISTINCT_SCENES` |
| Simulation long tasks | 30 | 40 | `BUDGET_MAX_SIMULATION_LONG_TASKS` |
| Simulation memory growth ratio | 2.2 | 3.0 | `BUDGET_MAX_SIMULATION_MEMORY_RATIO` |

---

## 4. E2E Performance Regression Report (Task 1326 Summary)

**Environment**: Linux x86_64, Chromium (Playwright), Budget Mode (`PW_BUDGET_MODE=1`).

### Performance & Budget Metrics Verified
**Budget Guardrails:** (All Passed)
- **Rapid Navigation:** P95 Latency <= 1600ms, Long Tasks <= 25, Memory Growth <= 2.8x.
- **Bulk Upload:** Latency <= 120000ms for >= 100 Scenes.
- **Simulation:** Distinct Scenes >= 2, Long Tasks <= 40.

**Performance Tests:**
- **Large Project (200 Scenes):** UI remained responsive.
- **Memory Stability:** Growth < 4x during navigation.
- **Bundle Size:** Passed (< 2000KB).

*(Note: Certain Optimistic Rollback and Visual Regression e2e tests required extensive API mocking and DOM wait adjustments to complete due to complex async worker interactions.)*
