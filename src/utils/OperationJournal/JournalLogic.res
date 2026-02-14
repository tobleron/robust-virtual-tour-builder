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
    let raw = JsonCombinators.Json.stringify(emergencySnapshotEncoder(snapshot))
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
        switch JsonCombinators.Json.decode(json, emergencySnapshotDecoder) {
        | Ok(snapshot) =>
          if snapshot.id == id {
            Dom.Storage2.localStorage->Dom.Storage2.removeItem(emergencyQueueKey)
          }
        | Error(_) => Dom.Storage2.localStorage->Dom.Storage2.removeItem(emergencyQueueKey)
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
        switch JsonCombinators.Json.decode(json, emergencySnapshotDecoder) {
        | Ok(snapshot) =>
          let hasEntry = journal.entries->Belt.Array.some(entry => entry.id == snapshot.id)
          if hasEntry {
            journal
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
            let newEntries = Belt.Array.concat(journal.entries, [syntheticEntry])
            {...journal, entries: newEntries}
          }
        | Error(e) =>
          Logger.warn(
            ~module_="OperationJournal",
            ~message="Failed to decode emergency snapshot",
            ~data={"error": e},
            (),
          )
          journal
        }
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
