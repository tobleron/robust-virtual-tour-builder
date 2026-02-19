# Task 1484: Polish Recovery/Crash Notification UX

## Priority: Medium
## Category: UX Polish

## Problem
When the app detects interrupted operations from a previous session, it shows a raw, developer-oriented notification that exposes JSON data directly to the user (e.g., `{"fileCount":1,"fileNames":["IMG_..."],"totalSizeBytes":36781403}`). This is confusing and unprofessional for end users.

## Current Behavior
- The "Interrupted Operations Detected" modal shows raw JSON metadata.
- The status text uses developer terminology ("Status: Interrupted", "Recovery: available").
- The file size is shown in raw bytes instead of a human-readable format.
- The overall presentation feels like a debug screen, not a user-facing notification.

## Desired Behavior
1. **Human-readable summary**: Instead of raw JSON, show a clean summary like:
   - "1 image upload was interrupted (IMG_20251223_160634.jpg, 35MB)"
2. **Friendly language**: Replace "Status: Interrupted" / "Recovery: available" with user-friendly messaging:
   - "Your upload didn't complete. Would you like to try again?"
3. **Clean visual design**: Match the app's premium design language — no code blocks, no raw data.
4. **Action clarity**: Make it clear what "Retry" and "Dismiss" will do:
   - "Resume Upload" instead of "RETRY AVAILABLE"
   - "Discard" instead of "DISMISS ALL"
5. **File formatting**: Show file sizes in KB/MB, not raw bytes.

## Files to Investigate
- `src/core/RecoveryCheck.res` or similar recovery UI component
- `src/core/RecoveryManager.res` — recovery data structure
- `src/systems/Upload/UploadProcessorLogic.res` — recovery handler registration

## Acceptance Criteria
- [ ] No raw JSON shown to the user
- [ ] File sizes formatted as KB/MB
- [ ] User-friendly action button labels
- [ ] Consistent with app's visual design system
- [ ] Recovery still functions correctly after UI changes
