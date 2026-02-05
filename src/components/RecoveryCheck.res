open EventBus
open OperationJournal

@react.component
let make = () => {
  React.useEffect0(() => {
    let checkRecovery = async () => {
      let journal = await OperationJournal.load()
      let interrupted = OperationJournal.getInterrupted(journal)

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
      }
    }

    let _ = checkRecovery()
    None
  })

  React.null
}
