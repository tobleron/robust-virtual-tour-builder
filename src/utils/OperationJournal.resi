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
let startOperation: (~operation: string, ~context: JSON.t, ~retryable: bool) => Promise.t<string> // Returns ID
let completeOperation: string => Promise.t<unit>
let failOperation: (string, string) => Promise.t<unit>
let updateStatus: (string, operationStatus) => Promise.t<unit>
let updateContext: (string, JSON.t) => Promise.t<unit>
let getInterrupted: t => array<journalEntry>
let getPending: t => array<journalEntry>
let load: unit => Promise.t<t>
let flushAllInFlight: unit => unit
