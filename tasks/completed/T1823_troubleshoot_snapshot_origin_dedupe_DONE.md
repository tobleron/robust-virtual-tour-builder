# T1823 Troubleshoot Snapshot Origin Dedupe

## Hypothesis (Ordered Expected Solutions)
- [ ] Snapshot dedupe is reusing the latest identical `auto` history entry during manual saves instead of upgrading its origin to `manual`.
- [ ] The frontend manual save path is not sending `saveOrigin=Manual` consistently.
- [ ] Dashboard/builder history rendering is coercing or defaulting origin labels incorrectly.

## Activity Log
- [x] Traced dashboard/builder history rendering to `src/site/PageFrameworkDashboard.js` and `src/site/PageFrameworkBuilder.js`.
- [x] Verified manual save intent is sent from `src/components/Sidebar/SidebarSaveSupport.res`.
- [x] Verified autosave intent is sent from `src/AppAutosave.res`.
- [x] Patched backend snapshot dedupe to preserve manual intent for identical content.
- [x] Verified backend tests pass.

## Code Change Ledger
- [x] `backend/src/api/project_snapshot.rs` — changed identical-content dedupe so a manual save upgrades the latest matching `auto` snapshot origin to `manual` instead of returning the stale origin unchanged.
- [x] `backend/src/api/project_snapshot.rs` — added a regression unit test covering manual-save upgrade behavior for identical content.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
- History labels are intended to distinguish autosave vs manual save. The backend was deduping identical content by returning the latest existing snapshot entry unchanged, so a manual save after an autosave could still show `AUTO`. The fix now lives in backend snapshot persistence, where a manual save upgrades the latest identical `auto` snapshot to `manual` and is covered by backend tests.
