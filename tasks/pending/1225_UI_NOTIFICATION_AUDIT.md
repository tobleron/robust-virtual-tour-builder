---
title: UI Notification and Toast Audit
status: pending
priority: medium
tags: [ux, cleanup, standards]
---

# Task: UI Notification and Toast Audit

## Context
App feedback must be consistent. We need to ensure that every significant UI action (Success or Failure) is communicated to the user via a Toast notification.

## Objectives
- [ ] **Codebase Audit**: Scan all `src/systems/` and `src/components/` for missing event feedback.
- [ ] **Implementation**: Ensure all major actions have `EventBus.dispatch(ShowNotification(...))`:
    - Project Save (Success/Fail)
    - Project Load (Success/Fail)
    - Image Upload Start/Progress/End
    - Export Start/Finish/Fail
    - Delete Scene/Link (Confirmation/Success)
    - Settings changes.
- [ ] **Standardization**: Use a consistent messaging pattern:
    - Success: "Action successful"
    - Error: "Action failed: [Reason from logger/error]"
- [ ] **Documentation**: Update development standards to mandate notification dispatch for all new system actions.

## Verification
- Manual walkthrough of every primary feature with simulated network failures (offline mode) to verify error toasts.
