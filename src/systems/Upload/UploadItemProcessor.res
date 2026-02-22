@@warning("-45")
open ReBindings
open SharedTypes
open UploadTypes

external castToJson: 'a => JSON.t = "%identity"

let processImageWithTimeout = (
  file: ReBindings.File.t,
  ~onStatus: string => unit,
  ~timeoutMs: int=180000,
) => {
  Promise.make((resolve, _reject) => {
    let settled = ref(false)
    let timeoutId = ReBindings.Window.setTimeout(() => {
      if !settled.contents {
        settled := true
        resolve(Error("Processing timed out after " ++ Belt.Int.toString(timeoutMs) ++ "ms"))
      }
    }, timeoutMs)

    Resizer.processAndAnalyzeImage(file, ~onStatus=Some(onStatus))
    ->Promise.then(result => {
      if !settled.contents {
        settled := true
        ReBindings.Window.clearTimeout(timeoutId)
        resolve(result)
      }
      Promise.resolve()
    })
    ->Promise.catch(err => {
      if !settled.contents {
        settled := true
        ReBindings.Window.clearTimeout(timeoutId)
        let (msg, _) = Logger.getErrorDetails(err)
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
  processImageWithTimeout(item.original, ~onStatus)
  ->Promise.then(processResult => {
    let newItem = switch processResult {
    | Ok(res) => handleProcessSuccess(res, item)
    | Error(msg) => handleProcessError(msg, item)
    }
    Promise.resolve(newItem)
  })
  ->Promise.catch(err => {
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
