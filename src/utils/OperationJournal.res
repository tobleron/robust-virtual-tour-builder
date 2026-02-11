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

// Emergency synchronous backup using localStorage for entries that might be lost in IDB
let saveToEmergencyQueue = (_entry: journalEntry) => {
  try {
    let _ = %raw(`console.log("[JOURNAL_EMERGENCY] Saving to localStorage emergency queue")`)
    // Just set a simple flag that an operation is in progress
    Dom.Storage2.localStorage->Dom.Storage2.setItem(emergencyQueueKey, "pending")
  } catch {
  | _ =>
    let _ = %raw(`console.warn("[JOURNAL_EMERGENCY_FAILED] Could not save to emergency queue")`)
  }
}

let checkEmergencyQueue = (journal: t): t => {
  try {
    let _ = %raw(`console.log("[JOURNAL_EMERGENCY_CHECK_START]")`)
    let emergency = Dom.Storage2.localStorage->Dom.Storage2.getItem(emergencyQueueKey)
    let _ = %raw(`console.log("[JOURNAL_EMERGENCY_CHECK] Emergency queue value:", emergency)`)
    switch emergency {
    | Some(_) =>
      let _ = %raw(`console.log("[JOURNAL_EMERGENCY_CHECK] Found emergency queue, creating synthetic interrupted entry")`)
      // Create a synthetic interrupted operation since we detected the emergency flag
      let syntheticId = Date.now()->Float.toString ++ "_synthetic"
      let syntheticEntry: journalEntry = {
        id: syntheticId,
        operation: "UnknownOperation",
        status: Interrupted,
        startTime: Date.now(),
        endTime: Some(Date.now()),
        context: Encode.object([]),
        retryable: false,
      }
      // Clear the emergency queue
      let _ = Dom.Storage2.localStorage->Dom.Storage2.removeItem(emergencyQueueKey)
      let _ = %raw(`console.log("[JOURNAL_EMERGENCY_CLEARED]")`)
      let newEntries = Array.concat(journal.entries, [syntheticEntry])
      {...journal, entries: newEntries}
    | None =>
      let _ = %raw(`console.log("[JOURNAL_EMERGENCY_CHECK] No emergency queue found")`)
      journal
    }
  } catch {
  | _exn =>
    let _ = %raw(`console.warn("[JOURNAL_EMERGENCY_CHECK_FAILED]")`)
    journal
  }
}

let make = () => {
  {entries: [], version: 1}
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
    version: field.required("version", Decode.int),
  }
})

// --- Persistence ---

let save = (journal: t) => {
  let json = journalEncoder(journal)
  let _ = %raw(`console.log("[JOURNAL_SAVE] Saving journal entries:", journal.entries.length)`)
  set(journalKey, json)
}

let saveCurrent = () => {
  save(currentJournal.contents)
}

external asJson: 'a => JSON.t = "%identity"

let load = () => {
  let _ = %raw(`console.log("[JOURNAL_LOAD_START]")`)
  get(journalKey)
  ->Promise.then(raw => {
    let _ = %raw(`console.log("[JOURNAL_GET_SUCCESS]", raw)`)
    let hasData = %raw(`raw != null && raw !== undefined`)
    if hasData {
      let _ = %raw(`console.log("[JOURNAL_HAS_DATA]")`)
      let json = asJson(raw)
      let _ = %raw(`console.log("[JOURNAL_CONVERT_TO_JSON_DONE]")`)
      try {
        switch JsonCombinators.Json.decode(json, journalDecoder) {
        | Ok(journal) =>
          let _ = %raw(`console.log("[JOURNAL_DECODE_SUCCESS] Entries count:", journal._0.entries ? journal._0.entries.length : -1)`)
          // Check emergency queue first - if anything is there, an operation was interrupted
          let _ = %raw(`console.log("[JOURNAL_CHECK_EMERGENCY_START]")`)
          let afterEmergency = checkEmergencyQueue(journal)
          let _ = %raw(`console.log("[JOURNAL_CHECK_EMERGENCY_DONE]")`)
          // Mark any remaining InProgress as Interrupted (they were interrupted by app reload)
          let fixedEntries = if Belt.Array.length(afterEmergency.entries) > 0 {
            Belt.Array.map(afterEmergency.entries, entry => {
              switch entry.status {
              | InProgress =>
                let _ = %raw(`console.log("[JOURNAL_FIX_INTERRUPTED] Entry was InProgress, marking as Interrupted:", entry.id)`)
                {...entry, status: Interrupted}
              | _ => entry
              }
            })
          } else {
            afterEmergency.entries
          }
          let fixedJournal = {...afterEmergency, entries: fixedEntries}
          currentJournal := fixedJournal
          let _ = %raw(`console.log("[JOURNAL_SAVE_CURRENT_START]")`)
          // Save the fixed journal back to IDB to persist the Interrupted status
          saveCurrent()
          ->Promise.then(() => {
            let _ = %raw(`console.log("[JOURNAL_FIXED_SAVED] Fixed journal saved with Interrupted statuses")`)
            Promise.resolve(fixedJournal)
          })
          ->Promise.catch(_e => {
            let _ = %raw(`console.error("[JOURNAL_SAVE_CURRENT_ERROR]")`)
            Promise.resolve(fixedJournal)
          })
        | Error(e) =>
          let _ = %raw(`console.error("[JOURNAL_DECODE_ERROR]", e)`)
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
      | _decodeError =>
        let _ = %raw(`console.error("[JOURNAL_DECODE_EXCEPTION]", _decodeError)`)
        let newJournal = make()
        currentJournal := newJournal
        Promise.resolve(newJournal)
      }
    } else {
      let _ = %raw(`console.log("[JOURNAL_NO_DATA]")`)
      let newJournal = make()
      currentJournal := newJournal
      Promise.resolve(newJournal)
    }
  })
  ->Promise.catch(_e => {
    let _ = %raw(`console.error("[JOURNAL_LOAD_FATAL_ERROR]")`)
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

  let newEntries = Array.concat(currentJournal.contents.entries, [entry])
  currentJournal := {...currentJournal.contents, entries: newEntries}

  saveCurrent()->Promise.then(() => Promise.resolve(id))
}

let updateStatus = (id: string, status: operationStatus): Promise.t<unit> => {
  let newEntries = Belt.Array.map(currentJournal.contents.entries, entry => {
    if entry.id == id {
      {...entry, status, endTime: Some(Date.now())}
    } else {
      entry
    }
  })
  currentJournal := {...currentJournal.contents, entries: newEntries}
  saveCurrent()
}

let updateContext = (id: string, context: JSON.t): Promise.t<unit> => {
  let newEntries = Belt.Array.map(currentJournal.contents.entries, entry => {
    if entry.id == id {
      {...entry, context}
    } else {
      entry
    }
  })
  currentJournal := {...currentJournal.contents, entries: newEntries}
  saveCurrent()
}

let completeOperation = (id: string): Promise.t<unit> => {
  let newEntries = Belt.Array.map(currentJournal.contents.entries, entry => {
    if entry.id == id {
      {...entry, status: Completed, endTime: Some(Date.now())}
    } else {
      entry
    }
  })

  let pendingOnly = Belt.Array.keep(newEntries, e =>
    switch e.status {
    | InProgress | Pending | Interrupted => true
    | Failed(_) | Completed | Cancelled => false
    }
  )
  currentJournal := {...currentJournal.contents, entries: pendingOnly}
  saveCurrent()
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
