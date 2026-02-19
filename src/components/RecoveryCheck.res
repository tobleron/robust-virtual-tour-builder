open EventBus
open OperationJournal
open ReBindings

@react.component
let make = () => {
  React.useEffect0(() => {
    let checkRecovery = async () => {
      let journal = await OperationJournal.load()
      let interrupted = OperationJournal.getInterrupted(journal)
      let resumable = interrupted->Belt.Array.keep(RecoveryManager.canRetry)
      Logger.debug(
        ~module_="RecoveryCheck",
        ~message="CHECKING_RECOVERY",
        ~data=Some(
          Logger.castToJson({
            "interruptedCount": Array.length(interrupted),
            "resumableCount": Array.length(resumable),
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

        let resumeButtons = if Array.length(resumable) > 0 {
          [
            {
              label: "Resume Upload",
              class_: "btn-primary",
              onClick: () => retryAll(resumable),
              autoClose: Some(false),
            },
          ]
        } else {
          []
        }

        let dismissedCount = Array.length(interrupted) - Array.length(resumable)
        let description = if dismissedCount > 0 {
          "We found unfinished tasks from your last session. " ++
          Belt.Int.toString(dismissedCount) ++ " item(s) cannot be resumed and will be discarded."
        } else {
          "We found an interrupted upload from your last session."
        }

        let _ = Window.setTimeout(() => {
          EventBus.dispatch(
            ShowModal({
              title: "Incomplete Uploads Detected",
              description: Some(description),
              content: Some(<RecoveryPrompt entries={interrupted} />),
              buttons: Belt.Array.concat(
                resumeButtons,
                [
                  {
                    label: "Discard",
                    class_: "btn-secondary",
                    onClick: () => clearInterrupted(),
                    autoClose: Some(false),
                  },
                ],
              ),
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
