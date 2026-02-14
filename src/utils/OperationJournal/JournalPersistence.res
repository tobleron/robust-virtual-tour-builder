open IdbBindings
open JournalTypes

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

external asJson: 'a => JSON.t = "%identity"

let load = (currentJournal: ref<t>) => {
  get(journalKey)
  ->Promise.then(raw => {
    switch Nullable.toOption(raw) {
    | Some(stored) =>
      let json = asJson(stored)
      try {
        switch JsonCombinators.Json.decode(json, journalDecoder) {
        | Ok(decodedJournal) =>
          let fixedJournal = decodedJournal->JournalLogic.checkEmergencyQueue->JournalLogic.normalizeJournal
          currentJournal := fixedJournal
          save(fixedJournal)
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
          let newJournal = {entries: [], version: journalVersion}
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
        let newJournal = {entries: [], version: journalVersion}
        currentJournal := newJournal
        Promise.resolve(newJournal)
      }
    | None =>
      let newJournal = {entries: [], version: journalVersion}
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
    let newJournal = {entries: [], version: journalVersion}
    currentJournal := newJournal
    Promise.resolve(newJournal)
  })
}
