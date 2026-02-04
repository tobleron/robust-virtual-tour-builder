---
title: Implement Project Save Recovery Handler
status: pending
priority: high
tags: [persistence, recovery, stability]
---

# Task: Implement Project Save Recovery Handler

## Context
Following brainstorm session 1219, we identified "Project Save" as the highest priority recovery feature due to its high benefit-to-risk ratio. The app should allow users to recover interrupted save operations from the `OperationJournal`.

## Objectives
- [ ] Create `src/utils/RecoveryManager.res` to handle operation-to-handler registration.
- [ ] Implement the `SaveProject` handler:
    - Re-trigger `ProjectManager.saveProject` using the current application state.
    - If memory state is empty, prompt to restore from the last Auto-Save.
- [ ] Ensure **Toast Notifications** inform the user of the recovery start, success, or failure.
- [ ] Integration: Update `Main.res` to use `RecoveryManager.retry` instead of the placeholder log.

## Stability Guards
- Operation must be idempotent.
- Check state timestamp to prevent overwriting newer manual changes with older recovery data.
