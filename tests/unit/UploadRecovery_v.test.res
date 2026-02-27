open Vitest
open EventBus
open UploadRecovery

describe("UploadRecovery", () => {
  testAsync("displays progress modal when files were processed", async t => {
    let dispatched = ref(None)
    let unsubscribe = EventBus.subscribe(
      evt => {
        dispatched := Some(evt)
      },
    )

    let context = JsonCombinators.Json.Encode.object([
      ("processedCount", JsonCombinators.Json.Encode.int(10)),
      ("fileCount", JsonCombinators.Json.Encode.int(50)),
    ])

    let entry: OperationJournal.journalEntry = {
      id: "test",
      operation: "UploadImages",
      status: OperationJournal.Interrupted,
      startTime: 0.0,
      endTime: None,
      context,
      retryable: true,
    }

    let _ = await recoverUpload(entry)

    unsubscribe()

    switch dispatched.contents {
    | Some(ShowModal(config)) =>
      t->expect(config.title)->Expect.toBe("Upload Interrupted")
      t
      ->expect(config.description)
      ->Expect.toBe(
        Some(
          "10 of 50 files were successfully processed before the interruption. To complete the upload, please select the remaining files.",
        ),
      )
      t->expect(config.icon)->Expect.toBe(Some("upload-cloud"))
      t->expect(Array.length(config.buttons))->Expect.toBe(2)
      let btn1 = Belt.Array.getExn(config.buttons, 0)
      let btn2 = Belt.Array.getExn(config.buttons, 1)
      t->expect(btn1.label)->Expect.toBe("Select Files")
      t->expect(btn2.label)->Expect.toBe("Dismiss")
    | _ => t->expect(false)->Expect.toBe(true) // Fail if no modal
    }
  })

  testAsync("displays restart modal when no files were processed but total known", async t => {
    let dispatched = ref(None)
    let unsubscribe = EventBus.subscribe(
      evt => {
        dispatched := Some(evt)
      },
    )

    let context = JsonCombinators.Json.Encode.object([
      ("fileCount", JsonCombinators.Json.Encode.int(50)),
    ])

    let entry: OperationJournal.journalEntry = {
      id: "test",
      operation: "UploadImages",
      status: OperationJournal.Interrupted,
      startTime: 0.0,
      endTime: None,
      context,
      retryable: true,
    }

    let _ = await recoverUpload(entry)

    unsubscribe()

    switch dispatched.contents {
    | Some(ShowModal(config)) =>
      t
      ->expect(config.description)
      ->Expect.toBe(
        Some(
          "An upload of 50 files was interrupted before any could be processed. Please select the files again to restart the upload.",
        ),
      )
    | _ => t->expect(false)->Expect.toBe(true)
    }
  })

  testAsync("displays generic modal when context is missing", async t => {
    let dispatched = ref(None)
    let unsubscribe = EventBus.subscribe(
      evt => {
        dispatched := Some(evt)
      },
    )

    let context = JsonCombinators.Json.Encode.null

    let entry: OperationJournal.journalEntry = {
      id: "test",
      operation: "UploadImages",
      status: OperationJournal.Interrupted,
      startTime: 0.0,
      endTime: None,
      context,
      retryable: true,
    }

    let _ = await recoverUpload(entry)

    unsubscribe()

    switch dispatched.contents {
    | Some(ShowModal(config)) =>
      t
      ->expect(config.description)
      ->Expect.toBe(Some("An upload was interrupted. Please select the files again to continue."))
    | _ => t->expect(false)->Expect.toBe(true)
    }
  })
})
