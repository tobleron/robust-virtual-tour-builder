open OperationJournal
open EventBus

let recoverUpload = (entry: OperationJournal.journalEntry) => {
  let decoded = JsonCombinators.Json.decode(
    entry.context,
    JsonCombinators.Json.Decode.object(field => {
      (
        field.optional("processedCount", JsonCombinators.Json.Decode.int),
        field.optional("fileCount", JsonCombinators.Json.Decode.int),
      )
    }),
  )

  let (processedCount, totalCount) = switch decoded {
  | Ok((p, t)) => (Option.getOr(p, 0), Option.getOr(t, 0))
  | _ => (0, 0)
  }

  let description = if processedCount > 0 && totalCount > 0 {
    Belt.Int.toString(processedCount) ++ " of " ++ Belt.Int.toString(totalCount) ++
    " files were successfully processed before the interruption. " ++
    "To complete the upload, please select the remaining files."
  } else if totalCount > 0 {
    "An upload of " ++ Belt.Int.toString(totalCount) ++
    " files was interrupted before any could be processed. " ++
    "Please select the files again to restart the upload."
  } else {
    "An upload was interrupted. Please select the files again to continue."
  }

  EventBus.dispatch(
    ShowModal({
      title: "Upload Interrupted",
      description: Some(description),
      content: None,
      buttons: [
        {
          label: "Select Files",
          class_: "btn-primary",
          onClick: () => EventBus.dispatch(TriggerUpload),
          autoClose: Some(true),
        },
        {
          label: "Dismiss",
          class_: "btn-secondary",
          onClick: () => EventBus.dispatch(CloseModal),
          autoClose: Some(true),
        },
      ],
      icon: Some("upload-cloud"),
      allowClose: Some(true),
      onClose: None,
      className: None,
    }),
  )
  Promise.resolve(true)
}
