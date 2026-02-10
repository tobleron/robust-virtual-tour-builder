---
title: "Investigate E2E Failure: Core UI & Visual Pipeline"
status: pending
priority: medium
tags:
  - testing
  - e2e
  - investigation
  - browser-compat
  - firefox
---

# 🕵️ Investigator: E2E Failure - Core UI (Firefox Focus)

## 🚨 Incident Report
- **Test File**: `tests/e2e/editor.spec.ts`
- **Impacted Cases**:
  - `should show and verify visual pipeline` (Firefox)
  - `should sync tour name property` (Firefox)
- **Observations**:
  - Failures are localized to Firefox, suggesting CSS Grid/Flexbox issues or Firefox-specific event handling (e.g. `onBlur` vs `onChange`).
  - `VisualPipeline` component might be failing to mount or its styles are being stripped/misinterpreted by Firefox.

## 🎯 Objective
Resolve Firefox-specific UI synchronization and rendering issues.

## 🔬 Proposal for Analysis & Troubleshooting
1.  **UI Inspect**: Run `npx playwright test --project=firefox --headed` and manually interact with the Visual Pipeline to see if it's visually present but non-interactive.
2.  **Property Sync**: Investigate `SidebarProjectInfo.res` to check if the `SetTourName` action is being triggered correctly on keyboard events in Firefox.
3.  **Styles Audit**: Verify `VisualPipelineStyles.res` for any `-webkit-` only bits or non-standard CSS properties.
4.  **Event Capture**: Use `setupAIObservability` to catch any Firefox-specific exceptions during the initialization of the Pannellum viewer driver.

## ✅ Acceptance Criteria
- [ ] `editor.spec.ts` passes consistently in Firefox.
- [ ] Tour name input remains synced with the global state in all major browsers.
---
