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

let make: unit => t
let startOperation: (
  ~operation: string,
  ~context: JSON.t,
  ~retryable: bool,
) => string // Returns ID
let completeOperation: (string) => unit
let failOperation: (string, string) => unit
let updateStatus: (string, operationStatus) => unit
let getInterrupted: t => array<journalEntry>
let getPending: t => array<journalEntry>
let save: t => Promise.t<unit>
let load: unit => Promise.t<t>
