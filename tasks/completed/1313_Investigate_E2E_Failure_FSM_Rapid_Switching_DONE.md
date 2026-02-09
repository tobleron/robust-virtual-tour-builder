---
title: "Investigate E2E Failure: FSM & Rapid Scene Switching Robustness"
status: active
priority: high
tags:
  - testing
  - e2e
  - investigation
  - fsm
  - concurrency
---

# 🕵️ Investigator: E2E Failure - FSM & Rapid Scene Switching

## 🚨 Incident Report
- **Test Files**: `tests/e2e/rapid-scene-switching.spec.ts`, `tests/e2e/robustness.spec.ts`
- **Impacted Cases**:
  - `rapid scene clicking should not hang` (Chromium)
  - `UI should not dim during scene preload` (Chromium)
  - `Concurrent Mode Transitions` (Chromium)
- **Observations**:
  - Tests indicate that rapid interaction with scene thumbnails can lead to state desynchronization or UI lockouts.
  - The `TransitionLock` may be failing to release under high-frequency trigger conditions, or the `NavigationFSM` is entering an unhandled state transition.

## 🎯 Objective
Identify the root cause of FSM instability during rapid switching and propose high-reliability fixes.

## 🔬 Proposal for Analysis & Troubleshooting
1.  **Trace Analysis**: Review Playwright traces for `LOCK_REJECTED` loops.
2.  **State Inspection**: Inject `__RE_STATE__` capture during the failure point to see if `NavigationFSM` is stuck in `Transitioning` or `Preloading`.
3.  **Timing Audit**: Check if the 50ms buffer in `SceneTransition.res` is sufficient for DOM/Viewport swaps under load.
4.  **Lock Lifecycle Audit**: Verify that every `TransitionLock.acquire` has a guaranteed `release` path, even if intermediate promises fail or are cancelled.

## ✅ Acceptance Criteria
- [ ] `rapid-scene-switching.spec.ts` passes consistently in Chromium.
- [ ] No deadlock logs observed in high-frequency interaction tests.
