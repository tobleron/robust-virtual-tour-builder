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
  MediaApiProcessFull.clamp(~value, ~minValue, ~maxValue)

let updateSpacing = (~nextSpacingMs: float, ~reason: string) =>
  MediaApiProcessFull.updateSpacing(
    ~nextSpacingMs,
    ~reason,
    ~spacingRef=processFullDynamicSpacingMs,
    ~latencyRef=processFullLatencyEmaMs,
  )

let updateLatencyEma = (sampleMs: float) =>
  MediaApiProcessFull.updateLatencyEma(~sampleMs, ~latencyRef=processFullLatencyEmaMs)

let noteProcessFullSuccess = (~durationMs: float, ~attempts: int) =>
  MediaApiProcessFull.noteProcessFullSuccess(
    ~durationMs,
    ~attempts,
    ~spacingRef=processFullDynamicSpacingMs,
    ~latencyRef=processFullLatencyEmaMs,
    ~stableSuccessRef=processFullStableSuccessStreak,
  )

let reserveProcessFullSlot = async () =>
  await MediaApiProcessFull.reserveProcessFullSlot(
    ~nextAllowedAtRef=processFullNextAllowedAtMs,
    ~spacingRef=processFullDynamicSpacingMs,
    ~sleepMs,
  )

let parseRateLimitedSeconds = (msg: string): option<int> =>
  MediaApiProcessFull.parseRateLimitedSeconds(msg)

let applyProcessFullBackoff = (seconds: int) =>
  MediaApiProcessFull.applyProcessFullBackoff(
    ~seconds,
    ~nextAllowedAtRef=processFullNextAllowedAtMs,
    ~spacingRef=processFullDynamicSpacingMs,
    ~latencyRef=processFullLatencyEmaMs,
    ~stableSuccessRef=processFullStableSuccessStreak,
  )

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
              ~module_="MediaApi",
              json,
              decodeMetadataResponse,
              "METADATA",
              "Metadata extraction failed",
            ),
        )
        ->Promise.catch(
          e =>
            handleError(
              ~module_="MediaApi",
              e,
              "Metadata extraction failed: JSON parsing error",
              "METADATA_ERROR_JSON_DECODE",
            ),
        )
      | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e =>
      handleError(~module_="MediaApi", e, "Metadata extraction failed", "METADATA_ERROR")
    )
  })
}

let processImageFull = (
  file: File.t,
  ~isOptimized: bool=false,
  ~metadata: option<exifMetadata>=?,
): Promise.t<apiResult<Blob.t>> => {
  Logger.info(
    ~module_="MediaApi",
    ~message="PROCESS_FULL_SCHEDULED",
    ~data=Some({
      "file": File.name(file),
      "size": File.size(file),
      "isOptimized": isOptimized,
      "hasMetadata": metadata->Option.isSome,
    }),
    (),
  )
  RequestQueue.schedule(() => {
    Logger.info(
      ~module_="MediaApi",
      ~message="PROCESS_FULL_QUEUE_SLOT_ACQUIRED",
      ~data=Some({"file": File.name(file)}),
      (),
    )
    reserveProcessFullSlot()->Promise.then(() => {
      let requestStartedAtMs = Date.now()
      Logger.info(
        ~module_="MediaApi",
        ~message="PROCESS_FULL_BACKOFF_SLOT_ACQUIRED",
        ~data=Some({
          "file": File.name(file),
          "spacingMs": processFullDynamicSpacingMs.contents,
        }),
        (),
      )
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

      Logger.info(
        ~module_="MediaApi",
        ~message="PROCESS_FULL_REQUEST_START",
        ~data=Some({"file": File.name(file), "size": File.size(file)}),
        (),
      )
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
            Logger.info(
              ~module_="MediaApi",
              ~message="PROCESS_FULL_REQUEST_SUCCESS",
              ~data=Some({
                "file": File.name(file),
                "attempts": attempts,
                "durationMs": Date.now() -. requestStartedAtMs,
              }),
              (),
            )
            response.blob()
            ->Promise.then(blob => Promise.resolve(Ok(blob)))
            ->Promise.catch(
              e =>
                handleError(
                  ~module_="MediaApi",
                  e,
                  "Image processing failed: Blob conversion error",
                  "PROCESSING_ERROR_BLOB_CONVERSION",
                ),
            )
          | Retry.Exhausted(msg) =>
            Logger.warn(
              ~module_="MediaApi",
              ~message="PROCESS_FULL_REQUEST_EXHAUSTED",
              ~data=Some({"file": File.name(file), "error": msg}),
              (),
            )
            msg->parseRateLimitedSeconds->Option.forEach(applyProcessFullBackoff)
            Promise.resolve(Error(msg))
          }
        },
      )
      ->Promise.catch(
        e => {
          let (msg, _) = Logger.getErrorDetails(e)
          Logger.warn(
            ~module_="MediaApi",
            ~message="PROCESS_FULL_REQUEST_THROWN",
            ~data=Some({"file": File.name(file), "error": msg}),
            (),
          )
          handleError(~module_="MediaApi", e, "Image processing failed", "PROCESSING_ERROR")
        },
      )
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
          json =>
            handleJsonDecode(
              ~module_="MediaApi",
              json,
              decodeSimilarityResponse,
              "SIMILARITY_BATCH",
              "Similarity calculation failed",
            )->Promise.then(
              decoded => {
                switch decoded {
                | Ok(data) => Promise.resolve(Ok(data.results))
                | Error(msg) => Promise.resolve(Error(msg))
                }
              },
            ),
        )
        ->Promise.catch(
          e =>
            handleError(
              ~module_="MediaApi",
              e,
              "Similarity calculation failed: JSON parsing error",
              "SIMILARITY_BATCH_ERROR_JSON_DECODE",
            ),
        )
      | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e =>
      handleError(~module_="MediaApi", e, "Similarity calculation failed", "SIMILARITY_BATCH_ERROR")
    )
  })
}
