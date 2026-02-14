open JsonCombinators.Json
open IdbBindings

type operationStatus =
  | Pending
  | InProgress
  | Completed
  | Failed(string)
  | Interrupted
  | Cancelled

type journalEntry = {
  id: string,
  operation: string,
  status: operationStatus,
  startTime: float,
  endTime: option<float>,
  context: JSON.t,
  retryable: bool,
}

type t = {
  entries: array<journalEntry>,
  version: int,
}

let journalKey = "operation_journal"
let emergencyQueueKey = "operation_journal_emergency_queue"
let journalVersion = 2

type emergencySnapshot = {
  id: string,
  operation: string,
  startTime: float,
  retryable: bool,
}

let emergencySnapshotEncoder = (snapshot: emergencySnapshot) => {
  Encode.object([
    ("id", Encode.string(snapshot.id)),
    ("operation", Encode.string(snapshot.operation)),
    ("startTime", Encode.float(snapshot.startTime)),
    ("retryable", Encode.bool(snapshot.retryable)),
  ])
}

let emergencySnapshotDecoder = Decode.object(field => {
  {
    id: field.required("id", Decode.string),
    operation: field.required("operation", Decode.string),
    startTime: field.required("startTime", Decode.float),
    retryable: field.required("retryable", Decode.bool),
  }
})

let isTerminalStatus = (status: operationStatus) => {
  switch status {
  | Completed | Failed(_) | Cancelled => true
  | Pending | InProgress | Interrupted => false
  }
}

// Emergency synchronous backup using localStorage for entries that might be lost in IDB
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

let make = () => {
  {entries: [], version: journalVersion}
}

let normalizeJournal = (journal: t): t => {
  {
    entries: journal.entries->Belt.Array.map(normalizeEntry),
    version: journalVersion,
  }
}

let currentJournal = ref(make())

// --- JSON Encoders ---

let statusEncoder = (status: operationStatus) => {
  switch status {
  | Pending => Encode.string("Pending")
  | InProgress => Encode.string("InProgress")
  | Completed => Encode.string("Completed")
  | Failed(msg) =>
    Encode.object([("status", Encode.string("Failed")), ("error", Encode.string(msg))])
  | Interrupted => Encode.string("Interrupted")
  | Cancelled => Encode.string("Cancelled")
  }
}

let journalEntryEncoder = (entry: journalEntry) => {
  Encode.object([
    ("id", Encode.string(entry.id)),
    ("operation", Encode.string(entry.operation)),
    ("status", statusEncoder(entry.status)),
    ("startTime", Encode.float(entry.startTime)),
    ("endTime", Encode.option(Encode.float)(entry.endTime)),
    ("context", entry.context),
    ("retryable", Encode.bool(entry.retryable)),
  ])
}

let journalEncoder = (journal: t) => {
  Encode.object([
    ("entries", Encode.array(journalEntryEncoder)(journal.entries)),
    ("version", Encode.int(journal.version)),
  ])
}

// --- JSON Decoders ---

let statusDecoder = {
  Decode.oneOf([
    Decode.string->Decode.flatMap(s => {
      switch s {
      | "Pending" => Decode.custom(_ => Pending)
      | "InProgress" => Decode.custom(_ => InProgress)
      | "Completed" => Decode.custom(_ => Completed)
      | "Interrupted" => Decode.custom(_ => Interrupted)
      | "Cancelled" => Decode.custom(_ => Cancelled)
      | _ => Decode.custom(_ => throw(Decode.DecodeError("Unknown status string")))
      }
    }),
    Decode.object(field => {
      let status = field.required("status", Decode.string)
      let error = field.required("error", Decode.string)
      if status == "Failed" {
        Failed(error)
      } else {
        throw(Decode.DecodeError("Invalid status tag: " ++ status))
      }
    }),
  ])
}

let journalEntryDecoder = Decode.object(field => {
  {
    id: field.required("id", Decode.string),
    operation: field.required("operation", Decode.string),
    status: field.required("status", statusDecoder),
    startTime: field.required("startTime", Decode.float),
    endTime: field.optional("endTime", Decode.option(Decode.float))->Option.flatMap(x => x),
    context: field.required("context", Decode.id),
    retryable: field.required("retryable", Decode.bool),
  }
})

let journalDecoder = Decode.object(field => {
  {
    entries: field.required("entries", Decode.array(journalEntryDecoder)),
    version: field.optional("version", Decode.int)->Option.getOr(1),
  }
})

// --- Persistence ---

let save = (journal: t) => {
  let json = journalEncoder(journal)
  Logger.debug(
    ~module_="OperationJournal",
    ~message="Saving journal",
    ~data={"entries": Belt.Array.length(journal.entries), "version": journal.version},
    (),
  )
  set(journalKey, json)
}

let saveCurrent = () => {
  save(currentJournal.contents)
}

external asJson: 'a => JSON.t = "%identity"

let load = () => {
  get(journalKey)
  ->Promise.then(raw => {
    switch Nullable.toOption(raw) {
    | Some(stored) =>
      let json = asJson(stored)
      try {
        switch JsonCombinators.Json.decode(json, journalDecoder) {
        | Ok(decodedJournal) =>
          let fixedJournal = decodedJournal->checkEmergencyQueue->normalizeJournal
          currentJournal := fixedJournal
          saveCurrent()
          ->Promise.then(() => Promise.resolve(fixedJournal))
          ->Promise.catch(exn => {
            let (msg, _) = Logger.getErrorDetails(exn)
            Logger.warn(
              ~module_="OperationJournal",
              ~message="Failed to persist normalized journal",
              ~data={"error": msg},
              (),
            )
            Promise.resolve(fixedJournal)
          })
        | Error(e) =>
          Logger.warn(
            ~module_="OperationJournal",
            ~message="Failed to decode journal",
            ~data={"error": e},
            (),
          )
          let newJournal = make()
          currentJournal := newJournal
          Promise.resolve(newJournal)
        }
      } catch {
      | decodeError =>
        let (msg, _) = Logger.getErrorDetails(decodeError)
        Logger.warn(
          ~module_="OperationJournal",
          ~message="Journal decode exception",
          ~data={"error": msg},
          (),
        )
        let newJournal = make()
        currentJournal := newJournal
        Promise.resolve(newJournal)
      }
    | None =>
      let newJournal = make()
      currentJournal := newJournal
      Promise.resolve(newJournal)
    }
  })
  ->Promise.catch(exn => {
    let (msg, _) = Logger.getErrorDetails(exn)
    Logger.error(
      ~module_="OperationJournal",
      ~message="Journal load fatal error",
      ~data={"error": msg},
      (),
    )
    let newJournal = make()
    currentJournal := newJournal
    Promise.resolve(newJournal)
  })
}

// --- Operations ---

let generateId = () => {
  let random = Math.random() *. 1000000.0
  Date.now()->Float.toString ++ "_" ++ Float.toString(random)
}

let startOperation = (~operation: string, ~context: JSON.t, ~retryable: bool) => {
  let id = generateId()
  let entry: journalEntry = {
    id,
    operation,
    status: InProgress,
    startTime: Date.now(),
    endTime: None,
    context,
    retryable,
  }

  // Immediately save to emergency queue (synchronous) in case IDB write doesn't complete before reload
  saveToEmergencyQueue(entry)

  let newEntries = Belt.Array.concat(currentJournal.contents.entries, [entry])
  currentJournal := {...currentJournal.contents, entries: newEntries}

  saveCurrent()->Promise.then(() => Promise.resolve(id))
}

let updateStatus = (id: string, status: operationStatus): Promise.t<unit> => {
  let now = Date.now()
  let found = ref(false)
  let newEntries = currentJournal.contents.entries->Belt.Array.map(entry => {
    if entry.id == id {
      found := true
      if isTerminalStatus(entry.status) {
        entry
      } else {
        let nextEndTime = switch status {
        | Pending | InProgress => entry.endTime
        | Interrupted | Completed | Failed(_) | Cancelled => Some(now)
        }
        {...entry, status, endTime: nextEndTime}
      }
    } else {
      entry
    }
  })

  if !found.contents {
    Promise.resolve()
  } else {
    if isTerminalStatus(status) {
      clearEmergencyQueueForId(id)
    }
    currentJournal := {...currentJournal.contents, entries: newEntries}
    saveCurrent()
  }
}

let updateContext = (id: string, context: JSON.t): Promise.t<unit> => {
  let newEntries = Belt.Array.map(currentJournal.contents.entries, entry => {
    if entry.id == id {
      if isTerminalStatus(entry.status) {
        entry
      } else {
        {...entry, context}
      }
    } else {
      entry
    }
  })
  currentJournal := {...currentJournal.contents, entries: newEntries}
  saveCurrent()
}

let completeOperation = (id: string): Promise.t<unit> => {
  updateStatus(id, Completed)
}

let failOperation = (id: string, reason: string): Promise.t<unit> => {
  updateStatus(id, Failed(reason))
}

let getInterrupted = (journal: t) => {
  Belt.Array.keep(journal.entries, entry => {
    switch entry.status {
    | InProgress => true
    | Interrupted => true
    | _ => false
    }
  })
}

let getPending = (journal: t) => {
  Belt.Array.keep(journal.entries, entry => {
    switch entry.status {
    | Pending => true
    | _ => false
    }
  })
}
