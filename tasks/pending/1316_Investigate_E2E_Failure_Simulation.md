---
title: "Investigate E2E Failure: Simulation & Teaser Workflows"
status: pending
priority: medium
tags:
  - testing
  - e2e
  - investigation
  - simulation
  - teaser
---

# 🕵️ Investigator: E2E Failure - Simulation & Teaser

## 🚨 Incident Report
- **Test File**: `tests/e2e/simulation-teaser.spec.ts`
- **Impacted Cases**:
  - `should run autopilot simulation` (Chromium)
  - `should run auto teaser and download` (Chromium)
- **Observations**:
  - The autopilot mode is either failing to start or failing to navigate between scenes as configured.
  - Potential `EXCEPTION: Error: Target index 1 not found in sceneOrder` observed in logs may be related to how simulation logic fetches the next waypoint.

## 🎯 Objective
Fix the autopilot simulation and teaser recording systems to ensure automated tour playback works as expected.

## 🔬 Proposal for Analysis & Troubleshooting
1.  **Waypoint Logic**: Investigate `SimulationMainLogic.res` to see if it's using zero-based or one-based indexing incorrectly when querying `sceneOrder`.
2.  **Navigation Sync**: Check if `Actions.SetNavigationStatus` is being dispatched correctly by the simulation runner.
3.  **Teaser Recording**: Ensure the `TeaserRecorder.res` logic can correctly capture frames when the `TransitionLock` is active.
4.  **Download Event**: Verify that the browser's download event is being detected correctly by Playwright for the generated video file.

## ✅ Acceptance Criteria
- [ ] `simulation-teaser.spec.ts` passes consistently.
- [ ] Simulation correctly advances through at least 3 scenes without manual intervention.
---
