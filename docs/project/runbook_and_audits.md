# Enterprise Runbooks & Audits

**Last Updated:** March 19, 2026  
**Version:** 5.3.6

This document is a collection of operational runbooks, performance budgets, and historical codebase audits that serve as a baseline for the project's commercial readiness and architectural health.

---

## 1. Enterprise Reliability & Performance Runbook

**Scope**: CI-enforced performance budgets and stress gates, aligned to Enterprise SLO targets.

### Budget Gates

#### Bundle Gate
- **Command**: `npm run budget:bundle`
- **Enforced Thresholds**:
  - Total JS bytes <= 4,500,000
  - Total gzip bytes <= 750,000
  - Largest chunk <= 2,000,000

#### Runtime Gate
- **Command**: `npm run test:e2e:budgets` and `npm run budget:runtime`
- **Enforced Thresholds**:
  - Rapid navigation p95 <= 1500ms
  - Rapid navigation long tasks <= 15
  - Bulk upload latency <= 90,000ms
  - Long simulation distinct active scenes >= 2
  - Long simulation long tasks <= 30

### SLO Alignment

| Metric | Threshold | Current Baseline | Status |
|---|---|---|---|
| Scene Switching p95 | < 1.5s | 125ms (cache) | ✅ Meets |
| Frontend Long Tasks (avg) | < 10 | 2 (rapid nav) | ✅ Meets |
| Memory Trend Stability | Growth Ratio <= 2.5 | 1.0 (gated suites) | ✅ Meets |
| Project Load (50 scenes) | < 5s | ~4s | ✅ Meets |
| Image Processing (4K) | < 1s | ~500ms | ✅ Meets |
| Bundle Size (Gzipped) | < 300KB | ~280KB | ✅ Meets |
| Test Coverage | >= 90% | ~95% | ✅ Meets |

---

## 2. Commercial Readiness Audit (v5.3.6)

**Verdict:** Commercially Ready with Advanced Features (Score: 8.5/10)

### Exceptional Strengths

1. **World-Class Type Safety**: Zero `unwrap()` in Rust, zero `console.log` in ReScript. Explicit error handling with `Result`/`Option` types
2. **Sophisticated Robustness Patterns**: Circuit Breaker, Retry with Backoff, Optimistic Updates, Rate Limiting, Interaction Queues, OperationLifecycle tracking
3. **Self-Governing Dev System**: `_dev-system` analyzer automatically enforces complexity constraints and limits architectural drift
4. **Clean Architecture**: Unidirectional data flow, modular decomposition, and local-first IndexedDB persistence
5. **Portal System**: Multi-tenant customer gallery with admin dashboard, access codes, and branded tour viewing
6. **Structured Concurrency**: NavigationSupervisor with AbortSignal for cancellation and race condition prevention
7. **Advanced Visualization**: Interactive graph-based Visual Pipeline with floor grouping and edge paths

### Identified Risks

1. **IndexedDB Quota**: Missing quota monitoring causing silent data loss risk for large projects (>500 scenes)
2. **E2E Coverage**: Expand Portal system coverage (admin dashboard, customer gallery, access code flows)
3. **Performance Monitoring**: No real-time performance telemetry in production
4. **Backup Strategy**: No automated backup system for user projects stored in IndexedDB
5. **Mobile Testing**: Limited mobile device testing for Portal customer gallery

### Recommended Actions

| Priority | Action | Owner | Timeline |
|---|---|---|---|
| High | Add IndexedDB quota monitoring | Backend | Q2 2026 |
| High | Implement Portal E2E test suite | QA | Q2 2026 |
| Medium | Integrate production performance monitoring | Platform | Q3 2026 |
| Medium | Implement automated project backups | Backend | Q3 2026 |
| Low | Expand mobile device testing matrix | QA | Q4 2026 |

---

## 3. Principal Code Quality Report (Feb 19, 2026)

**Focus Areas**: Export pipeline, Sidebar orchestration, E2E architecture.
**Rating**: B+

### Key Findings & Recommendations
1. **Export UX Drift**: Shortcut text output (`L to toggle`) does not match the actual supported key handlers (`L/M/1-3`). Needs strict alignment. 
2. **E2E Flakiness**: Direct `waitForTimeout` usage causes CI drift. Migrate fully to event/state-driven waits (`setupAIObservability`).
3. **E2E Setup Duplication**: Repeated reset/bootstrap logic across test suites. Consolidate to shared fixtures.
4. **Sidebar Logic Monolith**: `SidebarLogic.res` (>370 LOC) mixes Upload, Project IO, Export, and Notification logic. Needs splitting into sub-modules (`SidebarUploadLogic`, `SidebarProjectIoLogic`, etc.).

---

## 4. Code Quality Issues (v5.2.0 - March 2026)

**Scope:** Critical technical debt and known issues requiring attention.

### 4.1 EXIF Local Fallback Hang (T1785)

**Problem:** `ExifReportGeneratorLogicExtraction.res` contains a local extraction fallback if metadata is missing. For 40MB+ images, this re-reads the file from disk, causing the "Wrapping Up" hang.

**Solution:** Implement "Strict Extraction Mode" where files missing backend metadata are simply skipped for reporting/titling rather than re-read locally.

**Task:** `tasks/pending/T1785_fix_exif_fallback_hang.md`  
**Priority:** High (user-facing hang)  
**Risk:** Low (behavioral change, no refactor)

### 4.2 Concurrent Title Discovery Race Condition (T1786)

**Problem:** If multiple upload batches finish in rapid succession, `triggerBackgroundTitleDiscovery` fires multiple times. The `isDiscoveringTitle` global flag is cleared by the first finisher even if others are still working.

**Solution:** Switch `isDiscoveringTitle` to a reference counter or use a serial queue for title discovery tasks.

**Task:** `tasks/pending/T1786_fix_title_discovery_race.md`  
**Priority:** High (data corruption risk)  
**Risk:** Medium (state management change)

### 4.3 OffscreenCanvas Browser Support (T1787)

**Problem:** `ImageOptimizer.res` relies on the `WorkerPool` using `OffscreenCanvas`. Older browsers (Safari < 16.4, old Chrome) will fail compression with no main-thread fallback.

**Solution:** Implement a graceful main-thread `Canvas` fallback in `ImageOptimizer.res` if the `WorkerPool` returns an error or is unsupported.

**Task:** `tasks/pending/T1787_add_image_optimization_fallback.md`  
**Priority:** Medium (edge case browser support)  
**Risk:** Low (additive fallback)

### 4.4 Hotspot Index Stability (T1788)

**Problem:** `retargetHotspot` state uses `sceneIndex` and `hotspotIndex`. While `LinkModal` is modal-blocked, any background state updates could invalidate these indices.

**Solution:** Switch `linkInfo` to use `sceneId` and a unique `hotspotId` (uuid) instead of array indices for absolute targeting.

**Task:** `tasks/pending/T1788_refactor_hotspot_targeting_to_ids.md`  
**Priority:** Medium (potential bug under concurrent edits)  
**Risk:** Medium (refactor across multiple modules)

### 4.5 Worker Memory Spike (T1789)

**Problem:** `WorkerPool` spawns up to 8 workers. With 12K panoramas, each worker might consume 300MB+ RAM during processing. Total spike could exceed 2GB, potentially crashing low-end devices.

**Solution:** Dynamically adjust `createPoolSize` based on `navigator.deviceMemory` (if available) and the detected folder "heaviness".

**Task:** `tasks/pending/T1789_optimize_worker_pool_memory.md`  
**Priority:** Medium (low-end device crash risk)  
**Risk:** Low (adaptive configuration)

---

## 5. Operational Handoff Summary

The **Robust Virtual Tour Builder** exhibits enterprise-level engineering discipline, predominantly due to the tight integration of ReScript and Rust. The primary continuous focus must remain on:
1. Expanding event-driven E2E tests instead of time-based waits.
2. Monitoring performance budgets in CI to prevent bundle sprawl.
3. Adhering to the `_dev-system` Drag thresholds (Limit < 1.8) explicitly for all newly minted UI Orchestrator modules.
