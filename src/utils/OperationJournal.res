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
  set(journalKey, json)
}

let saveCurrent = () => {
  save(currentJournal.contents)
}

external asJson: 'a => JSON.t = "%identity"

let load = () => {
  get(journalKey)->Promise.then(raw => {
    switch Nullable.toOption(raw) {
    | Some(data) =>
      let json = asJson(data)
      switch JsonCombinators.Json.decode(json, journalDecoder) {
      | Ok(journal) =>
        currentJournal := journal
        Promise.resolve(journal)
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
    | None =>
      let newJournal = make()
      currentJournal := newJournal
      Promise.resolve(newJournal)
    }
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

  let newEntries = Array.concat(currentJournal.contents.entries, [entry])
  currentJournal := {...currentJournal.contents, entries: newEntries}

  let _ = saveCurrent()
  id
}

let updateStatus = (id: string, status: operationStatus) => {
  let newEntries = Belt.Array.map(currentJournal.contents.entries, entry => {
    if entry.id == id {
      {...entry, status, endTime: Some(Date.now())}
    } else {
      entry
    }
  })
  currentJournal := {...currentJournal.contents, entries: newEntries}
  let _ = saveCurrent()
}

let completeOperation = (id: string) => {
  updateStatus(id, Completed)
  // Prune completed operations immediately to keep journal small
  let pendingOnly = Belt.Array.keep(currentJournal.contents.entries, e =>
    switch e.status {
    | InProgress | Pending | Failed(_) | Interrupted => true
    | Completed | Cancelled => false
    }
  )
  currentJournal := {...currentJournal.contents, entries: pendingOnly}
  let _ = saveCurrent()
}

let failOperation = (id: string, reason: string) => {
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
