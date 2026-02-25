# 1550 — Implement Summary Modal Multi-Upload-Only Logic

## Priority: P2 — UX Improvement

## Objective
Change the Upload Summary modal to only appear for multi-image uploads (2+ files). Single-image uploads should auto-continue without showing the modal.

## Context
Currently, the Summary modal (with "Start Building" button) appears after every upload, including single-image uploads. The product owner's preference is:
- **Single image upload**: Auto-continue without modal. Directly transition to Interactive mode.
- **Multi-image upload (2+ files)**: Show Summary modal with success/skip report.

## Current Flow
1. Upload triggers `UploadComplete(report, qualityResults)` in `SidebarLogicHandler.res` line 326
2. `UploadReport.show()` is called (line 327) which displays the Summary modal
3. User clicks "Start Building" to continue

## Target Flow
1. Upload triggers `UploadComplete(report, qualityResults)`
2. If single image (`report.success.length + report.skipped.length <= 1`):
   - Skip modal
   - Directly dispatch `DispatchAppFsmEvent(ProjectLoadComplete)` or equivalent to enter Interactive mode
3. If multi-image (2+):
   - Show Summary modal as before

## Acceptance Criteria
- [ ] Single-image upload bypasses Summary modal entirely
- [ ] Multi-image upload (2+) shows Summary modal with report
- [ ] App transitions correctly to Interactive mode in both cases
- [ ] Scene list becomes visible after single-image upload without extra clicks
- [ ] Builds cleanly

## Files to Investigate/Modify
- `src/components/Sidebar/SidebarLogicHandler.res` — upload flow
- `src/components/UploadReport.res` — Summary modal display logic
- `src/core/AppFSM.res` — FSM transitions after upload
