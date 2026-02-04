---
title: Implement Tactical Upload Batch Recovery
status: pending
priority: medium
tags: [upload, recovery, ux]
---

# Task: Implement Tactical Upload Batch Recovery

## Context
Batch uploads are prone to network interruptions. Recovery is complex because `File` handles are lost on restart. We need a tactical approach that balances stability and convenience.

## Objectives
- [ ] Implement `UploadImages` handler in `RecoveryManager`.
- [ ] **State Tracking**: Update `OperationJournal` context with fingerprints of successfully processed files in real-time.
- [ ] **UI Integration**:
    - If interrupted, show a "Partial Upload Detected" toast.
    - Provide a "Finish Upload" button in the sidebar or recovery modal.
    - The "Finish Upload" action should prompt the user to re-select files, then use fingerprints to skip already-uploaded ones.
- [ ] **Toast Notifications**: Inform user of "Skipped [N] already uploaded files" and "Completed [N] remaining files".

## Stability Guards
- Never silently retry uploads; always require user confirmation to avoid state desync.
- Protect against duplicate scene creation using `FingerprintService`.
