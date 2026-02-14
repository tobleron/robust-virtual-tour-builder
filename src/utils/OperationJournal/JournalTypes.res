open JsonCombinators.Json

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

let isTerminalStatus = (status: operationStatus) => {
  switch status {
  | Completed | Failed(_) | Cancelled => true
  | Pending | InProgress | Interrupted => false
  }
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
