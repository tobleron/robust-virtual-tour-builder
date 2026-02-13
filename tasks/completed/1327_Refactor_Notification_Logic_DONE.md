# 1327: Refactor Notification Logic & Eliminate Redundancy (1306-Ready, Staged)

## Objective
Refactor notification behavior to eliminate redundant feedback, collapse duplicate network-error chains, and keep UX concise without blocking on task `1306` completion.

## Dependency Context
Task `1306` (Navigation Supervisor migration) is in progress. This task is split so work can start now with low merge risk:
- **Phase A (Do Now):** Notification refactors independent of final navigation architecture.
- **Phase B (Finalize After 1306):** Navigation-specific notification cleanup once Supervisor wiring is stable.

## Detailed Plan

### Phase A: Safe While 1306 Is In Progress

#### [MODIFY] `src/core/NotificationTypes.res`
- Add stable IDs for high-volume notifications (example keys):
  - `network_unstable`
  - `network_auth_expired`
  - `upload_summary`
  - `project_validation_summary`
  - `interaction_blocked`
- Reconfirm `importancePriority` ordering so stale warnings do not mask current critical errors.
- Keep default durations aligned with severity and dedupe behavior.

#### [MODIFY] `src/systems/Api/AuthenticatedClient.res`
- Consolidate `throttledNotification`, retry, and circuit-breaker signals into one keyed lifecycle.
- Emit one user-facing message per failing request chain, then update/dedupe by ID instead of queueing fresh toasts.
- Treat expected cancellation paths as non-user-visible where cancellation is internal.

#### [MODIFY] `src/systems/UploadProcessorLogic.res`
- Remove `Utils.notify` calls duplicated by persistent Sidebar status/reporting.
- Keep only critical failures and concise final summaries.

#### [MODIFY] `src/systems/ProjectManager.res`
- Collapse multiple validation warnings into one "Validation Summary" notification.
- Preserve granular details in logs/structured payloads, not toast-per-error UX.

#### [MODIFY] `src/components/Sidebar/SidebarLogic.res`
- Remove duplicated "Started"/"Completed" toasts where persistent UI already shows operation status.
- Keep actionable error and summary notifications only.

#### [MODIFY] `src/hooks/UseInteraction.res`
- Refine blocked-action copy to be concise and non-repetitive.
- Add cooldown/dedupe ID usage to prevent repeated blocked-action toast spam.

### Phase B: Finalize After 1306 Lands

#### [MODIFY] `src/systems/Scene/SceneSwitcher.res`
- Align navigation notifications with final post-1306 semantics:
  - Superseded navigation intent should not show warning/error toasts.
  - Only true navigation failures should notify.
- Remove any temporary compatibility messaging introduced during migration.

#### [REVIEW] `src/components/LockFeedback.res`
- Ensure persistent transition feedback remains the primary navigation-status surface.
- Remove any leftover transient toast behavior that duplicates this status UI.

## Verification

### Automated (Phase A)
- `npm run build`
- `npx playwright test tests/e2e/error-recovery.spec.ts`
- `npx playwright test tests/e2e/upload-link-export-workflow.spec.ts`

### Automated (Phase B, after 1306)
- `npm run build`
- `npx playwright test tests/e2e/rapid-scene-switching.spec.ts`
- Re-run targeted suites from Phase A

### Manual
- **Network resilience**: Simulate offline / 401 / 500 and verify one active network-notification chain.
- **Upload flow**: Sidebar progress remains primary feedback; no redundant "Upload Started" toast.
- **Project validation**: Malformed project emits one summary notification, not one per validation issue.
- **Navigation stress (Phase B)**: Rapid scene changes do not generate supersession warning floods.

## Acceptance Criteria
- One user-facing notification chain per network incident.
- No toast storm during repeated failures or blocked interactions.
- Upload/project lifecycle toasts reduced to actionable errors + concise summaries.
- Navigation-specific dedupe finalized only after 1306 settles.

## Report File
`docs/_pending_integration/notification_refactor_summary.md`
