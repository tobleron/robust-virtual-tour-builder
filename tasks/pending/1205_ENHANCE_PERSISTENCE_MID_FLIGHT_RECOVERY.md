# TASK: Enhance Persistence Layer with Mid-Flight Operation Recovery

**Priority**: 🟡 Medium
**Estimated Effort**: Medium (2-3 hours)
**Dependencies**: 1200 (Barrier Actions), 1202 (Optimistic Rollback)
**Related Tasks**: 1200, 1202

---

## 1. Problem Statement

The current `PersistenceLayer.res` recovers state but lacks context about interrupted operations:

- **Lost Operations**: If the app crashes during SaveProject, the user has no recovery path.
- **Orphaned Uploads**: Partially uploaded images are not tracked for resume.
- **No Operation Journal**: Users can't see what was happening when the crash occurred.

---

## 2. Technical Requirements

### A. Create Operation Journal

**File**: `src/utils/OperationJournal.res` (new)

```rescript
type operationStatus =
  | Pending
  | InProgress
  | Completed
  | Failed(string)
  | Interrupted

type journalEntry = {
  id: string,
  operation: string,           // "SaveProject", "UploadImage", etc.
  status: operationStatus,
  startTime: float,
  endTime: option<float>,
  context: JSON.t,             // Operation-specific data
  retryable: bool,
}

type t = {
  entries: array<journalEntry>,
  version: int,
}

let make: unit => t
let startOperation: (t, ~operation: string, ~context: JSON.t, ~retryable: bool) => (t, string)
let completeOperation: (t, string) => t
let failOperation: (t, string, string) => t
let getInterrupted: t => array<journalEntry>
let getPending: t => array<journalEntry>
```

### B. Persist Journal to IndexedDB

**File**: `src/utils/OperationJournal.res`

```rescript
let journalKey = "operation_journal"

let save = (journal: t) => {
  let encoder = // Use rescript-json-combinators
  IdbBindings.set(journalKey, encoder(journal))
}

let load = () => {
  IdbBindings.get(journalKey)
  ->Promise.then(raw => {
    switch Nullable.toOption(raw) {
    | Some(data) => 
      let decoder = // Use rescript-json-combinators
      JsonCombinators.Json.decode(data, decoder)
      ->Result.mapError(_ => "Decode failed")
    | None => Ok(make())
    }
  })
}
```

### C. Integrate with Key Operations

**SaveProject** (`src/systems/ProjectManager.res`):

```rescript
let saveProject = (state, ~onProgress=?) => {
  let journalId = OperationJournal.startOperation(
    ~operation="SaveProject",
    ~context=Logger.castToJson({
      "sceneCount": Array.length(state.scenes),
      "tourName": state.tourName,
    }),
    ~retryable=true,
  )
  
  Logic.createSavePackage(state, ~onProgress?)
  ->Promise.then(result => {
    switch result {
    | Ok(_) => OperationJournal.completeOperation(journalId)
    | Error(msg) => OperationJournal.failOperation(journalId, msg)
    }
    Promise.resolve(result)
  })
  ->Promise.catch(err => {
    OperationJournal.failOperation(journalId, getErrorMessage(err))
    Promise.reject(err)
  })
}
```

### D. Recovery Prompt on App Start

**File**: `src/Main.res`

```rescript
let checkRecovery = () => {
  OperationJournal.load()
  ->Promise.then(journal => {
    let interrupted = OperationJournal.getInterrupted(journal)
    
    if Array.length(interrupted) > 0 {
      EventBus.dispatch(ShowModal({
        title: "Interrupted Operations Detected",
        description: Some("The app closed unexpectedly. Would you like to retry?"),
        content: Some(<RecoveryPrompt entries={interrupted} />),
        buttons: [
          {label: "Retry All", class_: "btn-primary", onClick: () => retryAll(interrupted)},
          {label: "Dismiss", class_: "btn-secondary", onClick: () => clearInterrupted()},
        ],
        icon: Some("alert-triangle"),
        allowClose: Some(true),
        onClose: None,
        className: None,
      }))
    }
    Promise.resolve()
  })
}
```

---

## 3. JSON Encoding Standard

All journal entries MUST use `rescript-json-combinators`:

```rescript
let journalEntryEncoder = JsonCombinators.Json.Encode.object([
  ("id", string(entry.id)),
  ("operation", string(entry.operation)),
  ("status", statusEncoder(entry.status)),
  ("startTime", float(entry.startTime)),
  ("endTime", nullable(float, entry.endTime)),
  ("context", id(entry.context)),
  ("retryable", bool(entry.retryable)),
])

let journalEntryDecoder = JsonCombinators.Json.Decode.object(field => {
  id: field.required("id", string),
  operation: field.required("operation", string),
  status: field.required("status", statusDecoder),
  startTime: field.required("startTime", float),
  endTime: field.optional("endTime", float),
  context: field.required("context", id),
  retryable: field.required("retryable", bool),
})
```

---

## 4. Verification Criteria

- [ ] Interrupted SaveProject operation shows recovery prompt on next launch.
- [ ] Completed operations are cleared from journal.
- [ ] Journal is persisted to IndexedDB on every state change.
- [ ] Recovery prompt allows retry or dismiss.
- [ ] Journal entries include meaningful context for debugging.
- [ ] All JSON encoding uses `rescript-json-combinators`.
- [ ] `npm run build` completes with zero warnings.

---

## 5. File Checklist

- [ ] `src/utils/OperationJournal.res` - New module
- [ ] `src/utils/OperationJournal.resi` - Interface file
- [ ] `src/utils/PersistenceLayer.res` - Integrate journal
- [ ] `src/systems/ProjectManager.res` - Log SaveProject
- [ ] `src/systems/UploadProcessor.res` - Log UploadImage
- [ ] `src/Main.res` - Check recovery on startup
- [ ] `src/components/RecoveryPrompt.res` - New UI component
- [ ] `tests/unit/OperationJournal_v.test.res` - Unit tests
- [ ] `MAP.md` - Add new module entries

---

## 6. References

- `src/utils/PersistenceLayer.res`
- `src/systems/ProjectManager.res`
- `src/bindings/IdbBindings.res`
- `src/core/JsonParsers.res` (encoder patterns)
