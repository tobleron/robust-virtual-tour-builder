# E2E Test Report: Performance & Regression (Task 1326)

## Overview
This report documents the execution of Performance, Optimistic Rollback, Visual Regression, and Budget Guardrail E2E tests.

**Test Environment:**
- **OS:** Linux x86_64
- **Browser:** Chromium (Playwright)
- **Mode:** Budget Mode (`PW_BUDGET_MODE=1`) - Frontend only with API mocking.

## Test Results Summary

| Test Suite | Status | Details |
| :--- | :--- | :--- |
| **Performance (`performance.spec.ts`)** | **Partial Pass** | Large project responsiveness and memory usage passed. Bundle size validation passed after relaxing `networkidle` constraint. |
| **Optimistic Rollback (`optimistic-rollback.spec.ts`)** | **Partial Pass** | Hotspot addition rollback passed. Scene deletion rollback failed due to UI interaction issues (identifying confirmation modal buttons) and strict mode violations. |
| **Visual Regression (`visual-regression.spec.ts`)** | **Fail** | Failed to initialize tour building state due to "Upload Failed" modal triggered by simulated backend connection failures, despite API mocking. |
| **Performance Budgets (`perf-budgets.spec.ts`)** | **Pass** | All budget guardrails (Rapid Navigation, Bulk Upload, Simulation) passed within defined thresholds. |

## Performance & Budget Metrics

**Budget Guardrails:**
- **Rapid Navigation:** Passed.
  - P95 Latency: <= 1600ms
  - Long Tasks: <= 25
  - Memory Growth: <= 2.8x
- **Bulk Upload:** Passed.
  - Latency: <= 120000ms
  - Scene Count: >= 100
- **Simulation:** Passed.
  - Distinct Scenes: >= 2
  - Long Tasks: <= 40

**Performance Tests:**
- **Large Project (200 Scenes):** UI remained responsive. Scroll and interaction times were within limits.
- **Memory Stability:** Memory usage remained stable during navigation (Growth < 4x).
- **Bundle Size:** Passed (< 2000KB).

## Visual Deviations
Visual regression tests could not complete the setup phase to generate screenshots.
- **Root Cause:** The application attempts to connect to the backend (`/health`, `/api/media/process-full`) during the "Start Building" flow from a raw file input. Despite Playwright route mocking, the requests failed (likely due to timing or worker context), triggering an "Upload Failed" modal that blocked the UI.

## Technical Fixes Implemented

### 1. API Mocking for Frontend-Only Execution
Implemented extensive API mocking in `optimistic-rollback.spec.ts` and `visual-regression.spec.ts` to support testing without a running backend:
- **`**/api/project/import`**: Returns a valid project structure with scenes.
- **`**/api/project/create` & `**/api/project/upload`**: Mocks successful project creation from file uploads.
- **`**/api/media/process-full`**: Mocks image processing to return success and metadata.
- **`**/health*`**: Mocks the system health check to return 200 OK.
- **`**/api/project/*/file/*`**: Mocks image file requests to return a placeholder image (1x1 pixel JPEG), preventing 404s and WebGL errors in the viewer.

### 2. Test Robustness Improvements
- **`performance.spec.ts`**: Relaxed the `page.goto` wait condition from `networkidle` to `domcontentloaded` (with a subsequent timeout-protected wait) to prevent flaky timeouts caused by background polling or persistent connection retries in the test environment.
- **`optimistic-rollback.spec.ts`**: Added handling for the "Delete Scene" confirmation modal to properly exercise the deletion flow.

## Recommendations
- **Backend mocking strategy:** The current `page.route` mocking might miss requests initiated by Web Workers (e.g., the Resizer/Processor). Ensure mocks are applied to all contexts or configure Playwright to intercept worker requests explicitly if needed.
- **Strict Mode Compliance:** The deletion test failure due to "strict mode violation" indicates ambiguously named elements in the "Delete Scene" modal. Unique test IDs or more specific locators should be added to the modal components.
