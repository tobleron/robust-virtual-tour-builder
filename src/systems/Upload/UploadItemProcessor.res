@@warning("-45")
open ReBindings
open SharedTypes
open UploadTypes

external castToJson: 'a => JSON.t = "%identity"

let sleepMs = (delayMs: int): Promise.t<unit> =>
  Promise.make((resolve, _reject) => {
    let _ = ReBindings.Window.setTimeout(() => resolve(), delayMs)
  })

let parseRateLimitedSeconds = (msg: string): option<int> => {
  if String.startsWith(msg, "RateLimited: ") {
    let parts = String.split(msg, ": ")
    if Array.length(parts) == 2 {
      parts[1]->Option.flatMap(Belt.Int.fromString)
    } else {
      None
    }
  } else {
    None
  }
}

let isBulkheadRejected = (msg: string): bool => String.startsWith(msg, "BulkheadRejected:")

let processImageWithTimeout = (
  file: ReBindings.File.t,
  ~onStatus: string => unit,
  ~timeoutMs: int=300000,
) => {
  Logger.info(
    ~module_="UploadLogic",
    ~message="PROCESS_ITEM_TIMEOUT_GUARD_START",
    ~data=Some({
      "filename": File.name(file),
      "timeoutMs": timeoutMs,
      "size": File.size(file),
    }),
    (),
  )
  Promise.make((resolve, _reject) => {
    let settled = ref(false)
    let timeoutId = ReBindings.Window.setTimeout(() => {
      if !settled.contents {
        settled := true
        Logger.warn(
          ~module_="UploadLogic",
          ~message="PROCESS_ITEM_TIMEOUT_GUARD_TRIGGERED",
          ~data=Some({"filename": File.name(file), "timeoutMs": timeoutMs}),
          (),
        )
        resolve(Error("Processing timed out after " ++ Belt.Int.toString(timeoutMs) ++ "ms"))
      }
    }, timeoutMs)

    Resizer.processAndAnalyzeImage(file, ~onStatus=Some(onStatus))
    ->Promise.then(result => {
      if !settled.contents {
        settled := true
        ReBindings.Window.clearTimeout(timeoutId)
        switch result {
        | Ok(_) =>
          Logger.info(
            ~module_="UploadLogic",
            ~message="PROCESS_ITEM_TIMEOUT_GUARD_RESOLVED",
            ~data=Some({"filename": File.name(file), "outcome": "ok"}),
            (),
          )
        | Error(msg) =>
          Logger.warn(
            ~module_="UploadLogic",
            ~message="PROCESS_ITEM_TIMEOUT_GUARD_RESOLVED",
            ~data=Some({"filename": File.name(file), "outcome": "error", "error": msg}),
            (),
          )
        }
        resolve(result)
      }
      Promise.resolve()
    })
    ->Promise.catch(err => {
      if !settled.contents {
        settled := true
        ReBindings.Window.clearTimeout(timeoutId)
        let (msg, _) = Logger.getErrorDetails(err)
        Logger.warn(
          ~module_="UploadLogic",
          ~message="PROCESS_ITEM_TIMEOUT_GUARD_THROWN",
          ~data=Some({"filename": File.name(file), "error": msg}),
          (),
        )
        resolve(Error(msg))
      }
      Promise.resolve()
    })
    ->ignore
  })
}

let handleProcessSuccess = (res: Resizer.processResult, item: uploadItem) => {
  Logger.debug(
    ~module_="UploadLogic",
    ~message="QUALITY_ANALYSIS",
    ~data=Some({
      "filename": File.name(item.original),
      "avgLuminance": res.qualityData.stats.avgLuminance,
      "isBlurry": res.qualityData.isBlurry,
    }),
    (),
  )
  {
    ...item,
    preview: Some(res.preview),
    tiny: res.tiny,
    metadata: Some(castToJson(res.metadata)),
    quality: Some(castToJson(res.qualityData)),
  }
}

let handleProcessError = (msg, item: uploadItem) => {
  Logger.error(
    ~module_="UploadLogic",
    ~message="FILE_FAILED",
    ~data=Some({"filename": File.name(item.original), "error": msg}),
    (),
  )
  {...item, error: Some(msg)}
}

let processItem = (i, item: uploadItem, onStatus: string => unit) => {
  Logger.debug(
    ~module_="UploadLogic",
    ~message="FILE_START",
    ~data=Some({
      "filename": File.name(item.original),
      "index": i,
      "size": File.size(item.original),
    }),
    (),
  )
  Logger.info(
    ~module_="UploadLogic",
    ~message="PROCESS_ITEM_INVOKED",
    ~data=Some({"filename": File.name(item.original)}),
    (),
  )

  let rec attemptProcess = (remainingRateLimitRetries: int, remainingBulkheadRetries: int) => {
    processImageWithTimeout(item.original, ~onStatus)->Promise.then(processResult => {
      switch processResult {
      | Ok(res) => Promise.resolve(handleProcessSuccess(res, item))
      | Error(msg) =>
        if isBulkheadRejected(msg) && remainingBulkheadRetries > 0 {
          let retryAttempt = 3 - remainingBulkheadRetries + 1
          let waitMs = retryAttempt * 350
          onStatus("Upload queue busy, retrying in " ++ Belt.Int.toString(waitMs) ++ "ms")
          sleepMs(waitMs)->Promise.then(() =>
            attemptProcess(remainingRateLimitRetries, remainingBulkheadRetries - 1)
          )
        } else {
          switch parseRateLimitedSeconds(msg) {
          | Some(seconds) if remainingRateLimitRetries > 0 =>
            onStatus("Rate-limited, retrying in " ++ Belt.Int.toString(seconds) ++ "s")
            let waitMs = seconds * 1000 + 250
            sleepMs(waitMs)->Promise.then(() =>
              attemptProcess(remainingRateLimitRetries - 1, remainingBulkheadRetries)
            )
          | _ => Promise.resolve(handleProcessError(msg, item))
          }
        }
      }
    })
  }

  attemptProcess(2, 3)->Promise.catch(err => {
    let (msg, _) = Logger.getErrorDetails(err)
    Logger.error(
      ~module_="UploadLogic",
      ~message="FILE_FAILED_EXCEPTION",
      ~data=Some({"filename": File.name(item.original), "error": msg}),
      (),
    )
    Promise.resolve({...item, error: Some("Processing failed: " ++ msg)})
  })
}
