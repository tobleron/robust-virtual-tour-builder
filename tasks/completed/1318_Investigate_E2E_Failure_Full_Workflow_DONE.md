---
title: "Investigate E2E Failure: Full Tour Creation Workflow"
status: pending
priority: high
tags:
  - testing
  - e2e
  - investigation
  - user-journey
  - integration
---

# 🕵️ Investigator: E2E Failure - Full Tour Creation Workflow

## 🚨 Incident Report
- **Test File**: `tests/e2e/upload-link-export-workflow.spec.ts`
- **Impacted Case**: `should complete full tour creation workflow` (Chromium)
- **Observations**:
  - The test follows the entire "Upload -> Link -> Export" journey. A failure here is a regression in the primary user value proposition.
  - Test times out or fails at a specific step (likely Export).

## 🎯 Objective
Ensure the end-to-end integration of all systems (Upload, Hotspots, Exporter) is functioning correctly.

## 🔬 Proposal for Analysis & Troubleshooting
1.  **Step-by-Step Debug**: Run the test with `await page.pause()` at each major step to identify exactly where it diverges from expected behavior.
2.  **Export Binary Check**: Verify that the `Exporter.res` logic is correctly receiving the image blobs and project JSON from the state.
3.  **Backend Zip Logic**: Audit `backend/src/api/project.rs` for any issues when creating the final export ZIP if `inventory` Map is used.
4.  **UI Interruption**: Check if any auto-disappearing notifications (like "Processing complete") are being missed by the test runner because they disappear too fast.

## ✅ Acceptance Criteria
- [ ] `upload-link-export-workflow.spec.ts` passes consistently.
- [ ] Final exported tour ZIP contains valid `project.json` and `images/` directory.
---
