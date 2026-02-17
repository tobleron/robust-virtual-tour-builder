type operationStatus = JournalTypes.operationStatus =
  | Pending
  | InProgress
  | Completed
  | Failed(string)
  | Interrupted
  | Cancelled

type journalEntry = JournalTypes.journalEntry = {
  id: string,
  operation: string,
  status: operationStatus,
  startTime: float,
  endTime: option<float>,
  context: JSON.t,
  retryable: bool,
}

type t = JournalTypes.t = {
  entries: array<journalEntry>,
  version: int,
}

// --- TYPES ---

let make = () => {
  {entries: [], version: JournalTypes.journalVersion}
}

let currentJournal = ref(make())

let saveCurrent = () => {
  JournalPersistence.save(currentJournal.contents)
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
  JournalLogic.saveToEmergencyQueue(entry)

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
      if JournalTypes.isTerminalStatus(entry.status) {
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
    if JournalTypes.isTerminalStatus(status) {
      JournalLogic.clearEmergencyQueueForId(id)
    }
    currentJournal := {...currentJournal.contents, entries: newEntries}
    saveCurrent()
  }
}

let updateContext = (id: string, context: JSON.t): Promise.t<unit> => {
  let newEntries = Belt.Array.map(currentJournal.contents.entries, entry => {
    if entry.id == id {
      if JournalTypes.isTerminalStatus(entry.status) {
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

let load = () => {
  JournalPersistence.load(currentJournal)
}

let flushAllInFlight = () => {
  let journal = currentJournal.contents
  journal.entries
  ->Belt.Array.keep(e =>
    switch e.status {
    | Pending | InProgress => true
    | _ => false
    }
  )
  ->Belt.Array.forEach(entry => {
    JournalLogic.saveToEmergencyQueue(entry)
  })
}
