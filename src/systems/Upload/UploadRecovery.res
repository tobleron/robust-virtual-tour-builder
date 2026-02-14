open OperationJournal
open EventBus

let recoverUpload = (entry: OperationJournal.journalEntry) => {
  let count = switch JsonCombinators.Json.decode(
    entry.context,
    JsonCombinators.Json.Decode.object(field =>
      field.optional("processedCount", JsonCombinators.Json.Decode.int)
    ),
  ) {
  | Ok(Some(c)) => c
  | _ => 0
  }

  EventBus.dispatch(
    ShowModal({
      title: "Partial Upload Detected",
      description: Some(
        "Upload was interrupted. " ++
        Belt.Int.toString(
          count,
        ) ++ " files were processed. Please select the files again to continue.",
      ),
      content: None,
      buttons: [
        {
          label: "Finish Upload",
          class_: "btn-primary",
          onClick: () => EventBus.dispatch(TriggerUpload),
          autoClose: Some(true),
        },
      ],
      icon: Some("alert-circle"),
      allowClose: Some(true),
      onClose: None,
      className: None,
    }),
  )
  Promise.resolve(true)
}
