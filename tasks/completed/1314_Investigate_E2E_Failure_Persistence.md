---
title: "Investigate E2E Failure: Project Persistence (Save/Load Cycle)"
status: Completed
priority: critical
tags:
  - testing
  - e2e
  - investigation
  - persistence
  - data-integrity
findings:
  - The core persistence logic (decoders/encoders) is sound and correctly handles the transition to `inventory` Map.
  - Found and fixed a bug in `ProjectManager.res` where only scenes in `sceneOrder` were having their URLs rebuilt on load; improved it to rebuild ALL scenes in `inventory`.
  - Identified a regression in `save-load-recovery.spec.ts` where it was selecting the placeholder in the link modal, preventing hotspot verification. Fixed the test.
  - Verified migration from legacy `scenes` array to `inventory` via new unit tests in `JsonParsers_v.test.res`.
fixes:
  - `src/systems/ProjectManager.res`: Robust URL rebuilding for entire inventory.
  - `tests/e2e/save-load-recovery.spec.ts`: Fixed link target selection.
  - `tests/unit/JsonParsers_v.test.res`: Added modern schema tests.
---

# 🕵️ Investigator: E2E Failure - Project Persistence

## 🚨 Incident Report
- **Test File**: `tests/e2e/save-load-recovery.spec.ts`
- **Impacted Case**: `should persist project data through save/load cycle` (Chromium)
- **Observations**:
  - The core "Save then Load" workflow failed, potentially indicating data corruption or schema mismatch.
  - Recent transition to `inventory` (Belt.Map.String) in `State.res` may not be fully synchronized with `ProjectManager.res` or the backend JSON expectations.

## 🎯 Objective
Ensure that project data is correctly serialized, saved to backend (ZIP), and restored faithfully upon load.

## 🔬 Proposal for Analysis & Troubleshooting
- [x] Analyze `ProjectManager.res` logic for saving and loading `inventory`.
- [x] Verify `JsonParsersEncoders.res` and `JsonParsersDecoders.res` for modern data structures.
- [x] debug save/load cycle in `save-load-recovery.spec.ts`.
- [x] Ensure data integrity for all project fields during restoration.
- [x] investigate and fix any found issues in the persistence layer.

## ✅ Acceptance Criteria
- [ ] `save-load-recovery.spec.ts` passes consistently.
- [ ] Tour metadata (labels, categories, hotspots) remains identical after a full cycle.
---
