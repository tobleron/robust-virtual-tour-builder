# Task 1455: PersistenceLayer Multi-Entry Emergency Flush

**Masterplan**: Task 1448 (Network Stability Audit) — Issue 3.1  
**Phase**: 3 (Persistence & Recovery)  
**Depends on**: None  
**Blocks**: None

---

## Objective
Ensure all in-flight journal entries are flushed to the emergency queue when the tab closes, not just the last one.

## Problem
**Location**: `src/utils/PersistenceLayer.res` (beforeunload handler) and `src/utils/OperationJournal/JournalLogic.res` (`saveToEmergencyQueue`)

Current behavior:
1. `beforeunload` saves application state to IndexedDB but does NOT flush the OperationJournal
2. `JournalLogic.saveToEmergencyQueue` stores a **single** `emergencySnapshot` to localStorage (key: `emergencyQueueKey`)
3. If multiple operations are in-flight when the tab closes, only the last one to call `saveToEmergencyQueue` is preserved — the others are silently overwritten

## Implementation

### 1. Update `JournalLogic.saveToEmergencyQueue` to support array

Change the localStorage format from a single `emergencySnapshot` to an array:

```rescript
let saveToEmergencyQueue = (entry: journalEntry) => {
  try {
    let snapshot: emergencySnapshot = {
      id: entry.id,
      operation: entry.operation,
      startTime: entry.startTime,
      retryable: entry.retryable,
    }
    
    // Read existing queue
    let existingSnapshots = switch Dom.Storage2.localStorage->Dom.Storage2.getItem(emergencyQueueKey) {
    | Some(raw) =>
      switch JsonCombinators.Json.parse(raw) {
      | Ok(json) =>
        switch JsonCombinators.Json.decode(json, JsonCombinators.Json.Decode.array(emergencySnapshotDecoder)) {
        | Ok(arr) => arr
        | Error(_) => 
          // Backwards compat: try single snapshot format
          switch JsonCombinators.Json.decode(json, emergencySnapshotDecoder) {
          | Ok(single) => [single]
          | Error(_) => []
          }
        }
      | Error(_) => []
      }
    | None => []
    }

    // Append if not already present
    let alreadyExists = existingSnapshots->Belt.Array.some(s => s.id == snapshot.id)
    let updatedSnapshots = if alreadyExists {
      existingSnapshots
    } else {
      Belt.Array.concat(existingSnapshots, [snapshot])
    }

    let raw = JsonCombinators.Json.stringify(
      JsonCombinators.Json.Encode.array(emergencySnapshotEncoder)(updatedSnapshots)
    )
    Dom.Storage2.localStorage->Dom.Storage2.setItem(emergencyQueueKey, raw)
  } catch {
  | exn => // ... existing error handling ...
  }
}
```

### 2. Update `checkEmergencyQueue` to handle array format

```rescript
let checkEmergencyQueue = (journal: t): t => {
  // Try decoding as array first, fall back to single snapshot
  // For each snapshot in the array, create a synthetic entry if not already in journal
  // ... (similar to current logic but in a loop)
}
```

### 3. Update `clearEmergencyQueueForId` to remove by ID from array

```rescript
let clearEmergencyQueueForId = (id: string) => {
  // Read array, filter out the matching ID, write back
  // If array is now empty, remove the key entirely
}
```

### 4. Add `OperationJournal.flushAllInFlight()` function

```rescript
let flushAllInFlight = () => {
  let journal = currentJournal.contents
  journal.entries
  ->Belt.Array.keep(e => e.status == InProgress || e.status == Pending)
  ->Belt.Array.forEach(entry => {
    JournalLogic.saveToEmergencyQueue(entry)
  })
}
```

### 5. Call from PersistenceLayer `beforeunload`

In the `beforeunload` handler in `PersistenceLayer.res`, add:
```rescript
OperationJournal.flushAllInFlight()
```

## Files to Modify

| File | Change |
|------|--------|
| `src/utils/OperationJournal/JournalLogic.res` | Update `saveToEmergencyQueue`, `checkEmergencyQueue`, `clearEmergencyQueueForId` to array format |
| `src/utils/OperationJournal.res` | Add `flushAllInFlight()` |
| `src/utils/PersistenceLayer.res` | Call `OperationJournal.flushAllInFlight()` in `beforeunload` |

## Acceptance Criteria

- [ ] Emergency queue stores an array of snapshots (not single)
- [ ] Multiple in-flight operations are all preserved on tab close
- [ ] `checkEmergencyQueue` correctly restores all entries from array
- [ ] Backwards compatible with old single-snapshot format (migration path)
- [ ] `clearEmergencyQueueForId` removes only the specified entry from the array
- [ ] `flushAllInFlight()` writes all `InProgress`/`Pending` entries
- [ ] Zero compiler warnings
