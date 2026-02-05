/* src/systems/Api/MediaApi.res */

open SharedTypes
open ApiHelpers
open ReBindings

external castJson: 'a => JSON.t = "%identity"

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

let getAuthHeaders = () => {
  let headers = Dict.make()
  let token = Dom.Storage2.localStorage->Dom.Storage2.getItem("auth_token")

  let finalToken = switch token {
  | Some(t) => Some(t)
  | None =>
    // Professional fallback for local development automation
    Some("dev-token")
  }

  switch finalToken {
  | Some(t) => Dict.set(headers, "Authorization", "Bearer " ++ t)
  | None => ()
  }
  headers
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
      (),
    )
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Retry.Success(response, _) =>
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
      | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => handleError(e, "Image processing failed", "PROCESSING_ERROR"))
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
