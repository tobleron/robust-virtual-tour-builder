# Task 1456: UploadRecovery UX Improvements

**Masterplan**: Task 1448 (Network Stability Audit) — Issue 3.2  
**Phase**: 3 (Persistence & Recovery)  
**Depends on**: None  
**Blocks**: None

---

## Objective
Improve the upload recovery modal to provide clearer context about what happened and what the user needs to do.

## Problem
**Location**: `src/systems/Upload/UploadRecovery.res`

Current behavior:
1. Modal says "Upload was interrupted. X files were processed. Please select the files again to continue."
2. The "Finish Upload" button dispatches `TriggerUpload` which has no file context
3. User must manually re-select files — the modal doesn't explain this clearly
4. No information about which files were completed vs which need re-uploading

## Implementation

### 1. Enhance journal context during upload

In `src/systems/UploadProcessor.res` and `src/systems/UploadProcessorLogic.res`, enrich the journal context with file metadata:

```rescript
// When starting the operation journal entry:
OperationJournal.startOperation(
  ~operation="UploadImages",
  ~context=castToJson({
    "fileCount": Belt.Array.length(files),
    "fileNames": files->Belt.Array.map(f => f.name)->Belt.Array.slice(~offset=0, ~len=20),
    "totalSizeBytes": files->Belt.Array.reduce(0.0, (acc, f) => acc +. f.size),
  }),
  ~retryable=true,
)
```

### 2. Improve recovery modal content

```rescript
let recoverUpload = (entry: OperationJournal.journalEntry) => {
  let decoded = JsonCombinators.Json.decode(
    entry.context,
    JsonCombinators.Json.Decode.object(field => {
      (
        field.optional("processedCount", JsonCombinators.Json.Decode.int),
        field.optional("fileCount", JsonCombinators.Json.Decode.int),
      )
    }),
  )
  
  let (processedCount, totalCount) = switch decoded {
  | Ok((p, t)) => (Option.getOr(p, 0), Option.getOr(t, 0))
  | _ => (0, 0)
  }

  let description = if processedCount > 0 && totalCount > 0 {
    Belt.Int.toString(processedCount) ++ " of " ++ Belt.Int.toString(totalCount) ++
    " files were successfully processed before the interruption. " ++
    "To complete the upload, please select the remaining files."
  } else if totalCount > 0 {
    "An upload of " ++ Belt.Int.toString(totalCount) ++
    " files was interrupted before any could be processed. " ++
    "Please select the files again to restart the upload."
  } else {
    "An upload was interrupted. Please select the files again to continue."
  }

  EventBus.dispatch(
    ShowModal({
      title: "Upload Interrupted",
      description: Some(description),
      content: None,
      buttons: [
        {
          label: "Select Files",
          class_: "btn-primary",
          onClick: () => EventBus.dispatch(TriggerUpload),
          autoClose: Some(true),
        },
        {
          label: "Dismiss",
          class_: "btn-secondary",
          onClick: () => EventBus.dispatch(CloseModal),
          autoClose: Some(true),
        },
      ],
      icon: Some("upload-cloud"),
      allowClose: Some(true),
      onClose: None,
      className: None,
    }),
  )
  Promise.resolve(true)
}
```

## Files to Modify

| File | Change |
|------|--------|
| `src/systems/Upload/UploadRecovery.res` | Improve modal copy, decode richer context |
| `src/systems/UploadProcessor.res` | Enrich journal context with file metadata |

## Acceptance Criteria

- [ ] Journal context includes `fileNames` and `totalSizeBytes` when available
- [ ] Recovery modal shows X of Y files processed (when data available)
- [ ] Distinct messaging for "some processed" vs "none processed" vs "unknown"
- [ ] "Dismiss" button added alongside "Select Files"
- [ ] Icon changed from `alert-circle` to `upload-cloud` for clarity
- [ ] Zero compiler warnings
