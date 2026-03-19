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

---

## 5. Viewer Snapshot Stability (Issue 1774)

### Overview

Investigation of the `"Rendering...please wait"` notification emitted during scene transitions. This notification can appear persistently during rapid scene switching, simulation runs, and teaser playback.

**Source:** `src/components/ViewerSnapshot.res` line 78  
**Trigger:** `Error(_)` arm from `InteractionGuard.attempt()` with `SlidingWindow(10, 60000, 2000)`

### Current Configuration

| Condition | Current Config | Where Applied | User Effect |
|---|---|---|---|
| Min-interval throttle | `minIntervalMs=2000` | `ViewerSnapshot -> InteractionGuard.SlidingWindow` | Frequent "please wait" under rapid switching |
| Sliding-window quota | `maxCalls=10`, `windowMs=60000` | Same | At >10 captures/min, subsequent blocks |
| Fan-out trigger path | Snapshot on every swap | `SceneTransition.completeSwapTransition` | Message from many workflows |
| Notification dedupe refresh | Refresh by context+message | `NotificationManager.dispatch` | Can produce near-permanent toast |

### Stress Scenario Findings

| Scenario | Expected UX | Current Behavior | Root Cause |
|---|---|---|---|
| Fast scene switching (sidebar) | Smooth switching, minimal blocking | Snapshot request after each swap; toast persists | Swap-trigger fan-out + strict limiter + refresh reset |
| Hotspot rapid navigation | Navigation feedback | Same as above; separate "Switching too fast..." flow | Multiple independent throttles |
| Simulation run on dense graph | Stable autonomous traversal | Simulation steps trigger scene swaps; limiter hits | Snapshot flow not mode-aware |
| Teaser playback/render | Deterministic run with progress UI | Scene changes still route through swap lifecycle | Snapshot flow not teaser-aware |

### Optimization Proposals

#### Proposal A - Conservative (Lowest Risk)
**Goal:** Keep capture mechanics unchanged, reduce UX noise safely.

**Changes:**
1. Keep `SlidingWindow(10, 60000, 2000)` unchanged
2. Suppress toast for `"Throttled"` events (min-interval hits)
3. Show toast only on true sustained quota pressure (cooldown: 10-15s)

**Expected Impact:** Eliminates persistent low-value toast churn  
**Regression Risk:** Low

#### Proposal B - Balanced (Recommended)
**Goal:** Improve user-perceived stability while preserving safety constraints.

**Changes:**
1. Externalize snapshot policy into constants
2. Tune defaults:
   - `maxCalls`: `10 → 18`
   - `windowMs`: `60000` (unchanged)
   - `minIntervalMs`: `2000 → 1200`
3. Keep Proposal A notification cooldown behavior

**Why These Values:** Current profile hard-caps at 10/minute; new profile permits more realistic editing cadence  
**Expected Impact:** Fewer limiter hits during real editing  
**Regression Risk:** Low-Medium

#### Proposal C - Aggressive (Optional)
**Goal:** Maximum UX clarity during non-editing automated flows.

**Changes:**
1. Skip snapshot requests when `simulation.status == Running` or `isTeasing == true`
2. Keep snapshot capture best-effort only for manual stage interactions

**Expected Impact:** Removes non-essential snapshot work/noise during autonomous modes  
**Regression Risk:** Medium

### Test Coverage Gaps

1. ❌ No E2E test validating viewer snapshot notification behavior under rapid scene switching
2. ❌ No explicit unit test for **min-interval** branch mapped to this exact message
3. ❌ No test asserting toast persistence behavior when repeated refresh events occur
4. ❌ No test ensuring simulation/teaser modes avoid non-essential stage toasts

### Recommended Implementation

**Use Proposal B as default rollout:**
1. `SlidingWindow(18, 60000, 1200)`
2. Toast cooldown for snapshot-limit message (10-15s)
3. Min-interval branch does not emit user toast

**Files to Modify:**
- `src/components/ViewerSnapshot.res` - Notification logic
- `src/core/InteractionGuard.res` - SlidingWindow configuration
- `src/core/NotificationManager.res` - Cooldown behavior

**Verification Plan:**
1. Unit tests for differentiated behavior (interval-throttle vs quota-limit)
2. E2E rapid scene-switch stress test with toast assertions
3. Manual stage checklist (30-50 scene switches within ~60s)

---

## 6. Related Documents

- [Simulation Architecture](./simulation.md) - Simulation redesign
- [System Robustness](./robustness.md) - Circuit breakers, retry patterns
- [Runbook & Audits](../project/runbook_and_audits.md) - Performance budgets
