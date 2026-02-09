---
title: Investigate E2E Failure: Performance & Memory Leak
status: pending
priority: medium
tags:
  - testing
  - e2e
  - performance
  - investigation
---

# 🕵️ Investigator: E2E Failure - Performance & Memory

## 🚨 Incident Report
- **Test File**: `tests/e2e/performance.spec.ts`
- **Test Case**: `5.1: Large project (200 scenes) responsiveness`, `5.2: Memory usage should remain stable`
- **Failure**: Performance thresholds exceeded or instability detected.
- **Log**:
  ```
  2 failed
    [chromium] › tests/e2e/performance.spec.ts:23:5 › Performance & Load Testing › 5.1: Large project (200 scenes) responsiveness 
    [chromium] › tests/e2e/performance.spec.ts:69:5 › Performance & Load Testing › 5.2: Memory usage should remain stable 
  ```
- **Context**: The test generates a large project and checks UI latency and memory usage. Failures likely indicate:
  - Rendering bottlenecks in `SceneList` or `Sidebar`.
  - Memory leaks in `ViewerSystem` or `ImageOptimizer` not cleaning up blobs/textures.
  - Virtualization issues.

## 🎯 Objective
Investigate performance bottlenecks and memory leaks in large project scenarios.

## 🛠️ Investigation Steps
1.  **Reproduce Locally**: Run `npx playwright test tests/e2e/performance.spec.ts --project=chromium --debug`.
2.  **Profile**: use React Profiler or Chrome DevTools Memory tab.
3.  **Check Virtualization**: Ensure `SceneList` is virtualized properly.
4.  **Check Cleanup**: Verify `ViewerSystem` and `Worker` cleanup using `TransitionLock` logs.
5.  **Fix**:
    - Optimize re-renders.
    - Implement aggressive garbage collection hints or manual cleanup.

## ✅ Acceptance Criteria
- [ ] Test `performance.spec.ts` passes consistently.
- [ ] UI remains responsive (<100ms lag) with 200 scenes.
- [ ] Memory usage stabilizes after scene switching loops.
