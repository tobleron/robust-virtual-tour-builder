open JsonCombinators.Json
open JournalTypes

let saveToEmergencyQueue = (entry: journalEntry) => {
  try {
    let snapshot: emergencySnapshot = {
      id: entry.id,
      operation: entry.operation,
      startTime: entry.startTime,
      retryable: entry.retryable,
    }

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
  | exn =>
    let (msg, _) = Logger.getErrorDetails(exn)
    Logger.warn(
      ~module_="OperationJournal",
      ~message="Failed to write emergency snapshot",
      ~data={"error": msg},
      (),
    )
  }
}

let clearEmergencyQueueForId = (id: string) => {
  try {
    switch Dom.Storage2.localStorage->Dom.Storage2.getItem(emergencyQueueKey) {
    | Some(raw) =>
      switch JsonCombinators.Json.parse(raw) {
      | Ok(json) =>
        let existingSnapshots = switch JsonCombinators.Json.decode(json, JsonCombinators.Json.Decode.array(emergencySnapshotDecoder)) {
        | Ok(arr) => arr
        | Error(_) =>
          switch JsonCombinators.Json.decode(json, emergencySnapshotDecoder) {
          | Ok(single) => [single]
          | Error(_) => []
          }
        }

        let updatedSnapshots = existingSnapshots->Belt.Array.keep(s => s.id != id)

        if Array.length(updatedSnapshots) == 0 {
          Dom.Storage2.localStorage->Dom.Storage2.removeItem(emergencyQueueKey)
        } else {
          let raw = JsonCombinators.Json.stringify(
            JsonCombinators.Json.Encode.array(emergencySnapshotEncoder)(updatedSnapshots)
          )
          Dom.Storage2.localStorage->Dom.Storage2.setItem(emergencyQueueKey, raw)
        }

      | Error(_) => Dom.Storage2.localStorage->Dom.Storage2.removeItem(emergencyQueueKey)
      }
    | None => ()
    }
  } catch {
  | _ => ()
  }
}

let checkEmergencyQueue = (journal: t): t => {
  try {
    switch Dom.Storage2.localStorage->Dom.Storage2.getItem(emergencyQueueKey) {
    | Some(raw) =>
      Dom.Storage2.localStorage->Dom.Storage2.removeItem(emergencyQueueKey)
      switch JsonCombinators.Json.parse(raw) {
      | Ok(json) =>
        let snapshots = switch JsonCombinators.Json.decode(json, JsonCombinators.Json.Decode.array(emergencySnapshotDecoder)) {
        | Ok(arr) => arr
        | Error(_) =>
          switch JsonCombinators.Json.decode(json, emergencySnapshotDecoder) {
          | Ok(single) => [single]
          | Error(_) => []
          }
        }

        let newEntries = snapshots->Belt.Array.reduce(journal.entries, (acc, snapshot) => {
           let hasEntry = acc->Belt.Array.some(entry => entry.id == snapshot.id)
           if hasEntry {
             acc
           } else {
             let syntheticEntry: journalEntry = {
               id: snapshot.id,
               operation: snapshot.operation,
               status: Interrupted,
               startTime: snapshot.startTime,
               endTime: Some(Date.now()),
               context: Encode.object([]),
               retryable: snapshot.retryable,
             }
             Belt.Array.concat(acc, [syntheticEntry])
           }
        })

        {...journal, entries: newEntries}

      | Error(_) =>
        Logger.warn(~module_="OperationJournal", ~message="Failed to parse emergency snapshot", ())
        journal
      }
    | None => journal
    }
  } catch {
  | exn =>
    let (msg, _) = Logger.getErrorDetails(exn)
    Logger.warn(
      ~module_="OperationJournal",
      ~message="Emergency snapshot check failed",
      ~data={"error": msg},
      (),
    )
    journal
  }
}

let normalizeEntry = (entry: journalEntry) => {
  switch entry.status {
  | InProgress => {
      ...entry,
      status: Interrupted,
      endTime: switch entry.endTime {
      | Some(ts) => Some(ts)
      | None => Some(Date.now())
      },
    }
  | Pending | Interrupted | Completed | Failed(_) | Cancelled => entry
  }
}

let normalizeJournal = (journal: t): t => {
  {
    entries: journal.entries->Belt.Array.map(normalizeEntry),
    version: journalVersion,
  }
}
