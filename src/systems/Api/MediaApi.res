/* src/systems/Api/MediaApi.res */

open SharedTypes
open ApiHelpers
open ReBindings

external castJson: 'a => JSON.t = "%identity"

let processFullNextAllowedAtMs = ref(0.0)
let processFullDynamicSpacingMs = ref(Constants.Media.processFullSpacingStartMs)
let processFullLatencyEmaMs = ref(0.0)
let processFullStableSuccessStreak = ref(0)

let sleepMs = (delayMs: int): Promise.t<unit> =>
  Promise.make((resolve, _reject) => {
    let _ = Window.setTimeout(() => resolve(), delayMs)
  })

let clamp = (~value: float, ~minValue: float, ~maxValue: float) =>
  if value < minValue {
    minValue
  } else if value > maxValue {
    maxValue
  } else {
    value
  }

let updateSpacing = (~nextSpacingMs: float, ~reason: string) => {
  let bounded = clamp(
    ~value=nextSpacingMs,
    ~minValue=Constants.Media.processFullSpacingMinMs,
    ~maxValue=Constants.Media.processFullSpacingMaxMs,
  )
  let previous = processFullDynamicSpacingMs.contents
  if bounded != previous {
    processFullDynamicSpacingMs := bounded
    Logger.info(
      ~module_="MediaApi",
      ~message="PROCESS_FULL_AUTOTUNE_SPACING_UPDATED",
      ~data=Some({
        "reason": reason,
        "fromMs": Float.toFixed(previous, ~digits=0),
        "toMs": Float.toFixed(bounded, ~digits=0),
        "emaLatencyMs": Float.toFixed(processFullLatencyEmaMs.contents, ~digits=0),
      }),
      (),
    )
  }
}

let updateLatencyEma = (sampleMs: float) => {
  if processFullLatencyEmaMs.contents <= 0.0 {
    processFullLatencyEmaMs := sampleMs
  } else {
    let alpha = Constants.Media.processFullLatencyEmaAlpha
    processFullLatencyEmaMs :=
      (1.0 -. alpha) *. processFullLatencyEmaMs.contents +. alpha *. sampleMs
  }
}

let noteProcessFullSuccess = (~durationMs: float, ~attempts: int) => {
  updateLatencyEma(durationMs)

  if attempts > 1 {
    processFullStableSuccessStreak := 0
    updateSpacing(
      ~nextSpacingMs=processFullDynamicSpacingMs.contents +.
      Constants.Media.processFullSpacingStepUpMs,
      ~reason="retry-success",
    )
  } else {
    processFullStableSuccessStreak := processFullStableSuccessStreak.contents + 1
    let reachedWindow =
      processFullStableSuccessStreak.contents >= Constants.Media.processFullAutotuneSuccessWindow
    if reachedWindow {
      processFullStableSuccessStreak := 0
      updateSpacing(
        ~nextSpacingMs=processFullDynamicSpacingMs.contents -.
        Constants.Media.processFullSpacingStepDownMs,
        ~reason="stable-success-window",
      )
    }
  }
}

let reserveProcessFullSlot = async () => {
  let now = Date.now()
  let slotAt = if processFullNextAllowedAtMs.contents > now {
    processFullNextAllowedAtMs.contents
  } else {
    now
  }
  processFullNextAllowedAtMs := slotAt +. processFullDynamicSpacingMs.contents
  let waitMs = slotAt -. now
  if waitMs > 1.0 {
    let _ = await sleepMs(Belt.Float.toInt(waitMs))
  } else {
    ()
  }
}

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

let applyProcessFullBackoff = (seconds: int) => {
  let resumeAt = Date.now() +. Belt.Int.toFloat(seconds * 1000)
  if resumeAt > processFullNextAllowedAtMs.contents {
    processFullNextAllowedAtMs := resumeAt
  }
  processFullStableSuccessStreak := 0
  updateSpacing(
    ~nextSpacingMs=processFullDynamicSpacingMs.contents +.
    Constants.Media.processFullSpacingStepUpMs,
    ~reason="rate-limited",
  )
}

/* Helper functions to reduce nesting */
let handleError = (e, message, logKey) => {
  let (msg, stack) = Logger.getErrorDetails(e)
  Logger.error(
    ~module_="MediaApi",
    ~message=logKey,
    ~data=Logger.castToJson({"error": msg, "stack": stack}),
    (),
  )
  Promise.resolve(Error(message))
}

let handleJsonDecode = (json, decoder, logKey, errorMessage) => {
  switch decoder(json) {
  | Ok(data) => Promise.resolve(Ok(data))
  | Error(msg) =>
    Logger.error(
      ~module_="MediaApi",
      ~message=logKey ++ "_DECODE_FAILED",
      ~data=Logger.castToJson({"error": msg}),
      (),
    )
    Promise.resolve(Error(errorMessage ++ ": " ++ msg))
  }
}

let extractMetadata = (file: File.t): Promise.t<apiResult<metadataResponse>> => {
  RequestQueue.schedule(() => {
    let formData = FormData.newFormData()
    FormData.append(formData, "file", file)

    AuthenticatedClient.requestWithRetry(
      Constants.backendUrl ++ "/api/media/extract-metadata",
      ~method="POST",
      ~formData,
      (),
    )
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Retry.Success(response, _) =>
        response.json()
        ->Promise.then(
          json =>
            handleJsonDecode(
              json,
              decodeMetadataResponse,
              "METADATA",
              "Metadata extraction failed",
            ),
        )
        ->Promise.catch(
          e =>
            handleError(
              e,
              "Metadata extraction failed: JSON parsing error",
              "METADATA_ERROR_JSON_DECODE",
            ),
        )
      | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => handleError(e, "Metadata extraction failed", "METADATA_ERROR"))
  })
}

let processImageFull = (
  file: File.t,
  ~isOptimized: bool=false,
  ~metadata: option<exifMetadata>=?,
): Promise.t<apiResult<Blob.t>> => {
  RequestQueue.schedule(() => {
    reserveProcessFullSlot()->Promise.then(() => {
      let requestStartedAtMs = Date.now()
      let formData = FormData.newFormData()
      FormData.append(formData, "file", file)
      if isOptimized {
        FormData.append(formData, "is_optimized", "true")
      }
      switch metadata {
      | Some(m) =>
        FormData.append(
          formData,
          "metadata",
          JsonCombinators.Json.stringify(JsonParsers.Encoders.exifMetadata(m)),
        )
      | None => ()
      }

      AuthenticatedClient.requestWithRetry(
        Constants.backendUrl ++ "/api/media/process-full",
        ~method="POST",
        ~formData,
        ~retryConfig={
          maxRetries: 1,
          initialDelayMs: 1200,
          maxDelayMs: 5000,
          backoffMultiplier: 2.0,
          jitter: true,
          totalDeadlineMs: 300000, // 5 minutes
        },
        (),
      )
      ->Promise.then(
        resultResponse => {
          switch resultResponse {
          | Retry.Success(response, attempts) =>
            noteProcessFullSuccess(~durationMs=Date.now() -. requestStartedAtMs, ~attempts)
            response.blob()
            ->Promise.then(blob => Promise.resolve(Ok(blob)))
            ->Promise.catch(
              e =>
                handleError(
                  e,
                  "Image processing failed: Blob conversion error",
                  "PROCESSING_ERROR_BLOB_CONVERSION",
                ),
            )
          | Retry.Exhausted(msg) =>
            msg->parseRateLimitedSeconds->Option.forEach(applyProcessFullBackoff)
            Promise.resolve(Error(msg))
          }
        },
      )
      ->Promise.catch(e => handleError(e, "Image processing failed", "PROCESSING_ERROR"))
    })
  })
}

let batchCalculateSimilarity = (pairs: array<similarityPair>): Promise.t<
  apiResult<array<similarityResult>>,
> => {
  RequestQueue.schedule(() => {
    let body = JsonCombinators.Json.Encode.object([
      ("pairs", JsonCombinators.Json.Encode.array(JsonParsers.Encoders.similarityPair)(pairs)),
    ])

    AuthenticatedClient.requestWithRetry(
      Constants.backendUrl ++ "/api/media/similarity",
      ~method="POST",
      ~body=castJson(body),
      (),
    )
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Retry.Success(response, _) =>
        response.json()
        ->Promise.then(
          json => {
            switch decodeSimilarityResponse(json) {
            | Ok(data) => Promise.resolve(Ok(data.results))
            | Error(msg) => Promise.resolve(Error(msg))
            }
          },
        )
        ->Promise.catch(
          e =>
            handleError(
              e,
              "Similarity calculation failed: JSON parsing error",
              "SIMILARITY_BATCH_ERROR_JSON_DECODE",
            ),
        )
      | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => handleError(e, "Similarity calculation failed", "SIMILARITY_BATCH_ERROR"))
  })
}
