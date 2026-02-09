open EventBus
open OperationJournal
open ReBindings

@react.component
let make = () => {
  React.useEffect0(() => {
    let checkRecovery = async () => {
      let _ = %raw(`console.log("[RECOVERY_CHECK] Started checking...")`)
      let _ = %raw(`console.log("[RECOVERY_CHECK] About to call OperationJournal.load()")`)
      let journal = await OperationJournal.load()
      let _ = %raw(`console.log("[RECOVERY_CHECK] Got journal, entries:", journal)`)
      let interrupted = OperationJournal.getInterrupted(journal)
      let _ = %raw(`console.log("[RECOVERY_CHECK] Got interrupted, count:", interrupted.length)`)
      Logger.debug(
        ~module_="RecoveryCheck",
        ~message="CHECKING_RECOVERY",
        ~data=Some(
          Logger.castToJson({
            "interruptedCount": Array.length(interrupted),
            "journalEntries": Array.length(journal.entries),
          }),
        ),
        (),
      )

      if Array.length(interrupted) > 0 {
        let clearInterrupted = () => {
          Belt.Array.forEach(interrupted, entry => {
            OperationJournal.updateStatus(entry.id, Cancelled)->ignore
          })
          EventBus.dispatch(CloseModal)
        }

        let retryAll = entries => {
          EventBus.dispatch(CloseModal)
          Belt.Array.forEach(entries, entry => {
            let _ = RecoveryManager.retry(entry)
          })
        }

        let _ = Window.setTimeout(() => {
          EventBus.dispatch(
            ShowModal({
              title: "Interrupted Operations Detected",
              description: Some("The app closed unexpectedly while operations were in progress."),
              content: Some(<RecoveryPrompt entries={interrupted} />),
              buttons: [
                {
                  label: "Retry All",
                  class_: "btn-primary",
                  onClick: () => retryAll(interrupted),
                  autoClose: Some(false),
                },
                {
                  label: "Dismiss All",
                  class_: "btn-secondary",
                  onClick: () => clearInterrupted(),
                  autoClose: Some(false),
                },
              ],
              icon: Some("alert-triangle"),
              allowClose: Some(true),
              onClose: None,
              className: None,
            }),
          )
        }, 500)
      }
    }

    let _promise = checkRecovery()
    None
  })

  React.null
}
