# 1327: Refactor Notification Logic & Eliminate Redundancy

## Objective
Refactor the notification system to eliminate redundant feedback, consolidate overlapping network error messages, and ensure a unified, non-intrusive UX.

## Context
Analysis revealed that long-running operations (Upload, Export) trigger both toasts and persistent progress bars. Additionally, network failures can flood the queue with redundant retry and circuit breaker messages.

## Detailed Plan

### Core Notification Logic
#### [MODIFY] [NotificationTypes.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/NotificationTypes.res)
- Adjust `importancePriority` if needed to ensure "Started" (Info) notifications aren't buried by stale warnings.
- Add `id` constants for major system notifications to ensure consistent throttling/deduplication.

### Systems Layer
#### [MODIFY] [AuthenticatedClient.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/Api/AuthenticatedClient.res)
- Consolidate `throttledNotification`, circuit breaker, and retry notifications.
- Ensure only ONE clear notification is active for a failing network request chain.
- Use a single throttling mechanism for all persistent connection warnings.

#### [MODIFY] [UploadProcessorLogic.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/UploadProcessorLogic.res)
- Remove `Utils.notify` calls that duplicate feedback already provided by the Sidebar progress bar or final reports.
- Keep only critical process-level failures.

#### [MODIFY] [ProjectManager.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ProjectManager.res)
- Group multiple project validation warnings into a single "Validation Summary" notification instead of individual toasts per error.

### UI Components
#### [MODIFY] [SidebarLogic.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/Sidebar/SidebarLogic.res)
- Remove "Starting..." and "Complete" toasts for Upload/Export/Load if the persistent UI is already clearly showing status.
- Standardize Error notification messages.

#### [MODIFY] [UseInteraction.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/hooks/UseInteraction.res)
- Refine "Operation already in progress" message to be less redundant with system-level block messages.

## Verification
### Automated Tests
- Run existing E2E tests to ensure notifications still appear when critical errors occur:
  - `npx playwright test tests/e2e/error-recovery.spec.ts`
  - `npx playwright test tests/e2e/upload-link-export-workflow.spec.ts`
- Verify no "toast storm" occurs during multiple rapid-fire network failures.

### Manual Verification
- **Network Resilience**: Simulate offline mode or 401/500 errors and verify that only a single, helpful notification appears (not a stack of retries).
- **Upload Flow**: Start an upload and verify that the sidebar progress bar is the primary feedback, without an redundant "Upload Started" toast.
- **Project Load**: Load a malformed project and verify that validation errors are grouped or concisely reported.

## Report File
`docs/_pending_integration/notification_refactor_summary.md`
