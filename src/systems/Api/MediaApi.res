/* src/systems/Api/MediaApi.res */

open SharedTypes
open ApiHelpers
open ReBindings

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

    Fetch.fetch(
      Constants.backendUrl ++ "/api/media/extract-metadata",
      Fetch.requestInit(~method="POST", ~body=formData, ()),
    )
    ->Promise.then(handleResponse)
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Ok(response) =>
        Fetch.json(response)
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
      | Error(msg) => Promise.resolve(Error(msg))
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

    Fetch.fetch(
      Constants.backendUrl ++ "/api/media/process-full",
      Fetch.requestInit(~method="POST", ~body=formData, ()),
    )
    ->Promise.then(handleResponse)
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Ok(response) =>
        Fetch.blob(response)
        ->Promise.then(blob => Promise.resolve(Ok(blob)))
        ->Promise.catch(
          e =>
            handleError(
              e,
              "Image processing failed: Blob conversion error",
              "PROCESSING_ERROR_BLOB_CONVERSION",
            ),
        )
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => handleError(e, "Image processing failed", "PROCESSING_ERROR"))
  })
}

let batchCalculateSimilarity = (pairs: array<similarityPair>): Promise.t<
  apiResult<array<similarityResult>>,
> => {
  RequestQueue.schedule(() => {
    let headers = Dict.make()
    Dict.set(headers, "Content-Type", "application/json")

    let body = JsonCombinators.Json.stringify(JsonCombinators.Json.Encode.object([
      ("pairs", JsonCombinators.Json.Encode.array(JsonParsers.Encoders.similarityPair)(pairs))
    ]))

    Fetch.fetch(
      Constants.backendUrl ++ "/api/media/similarity",
      Fetch.requestInit(~method="POST", ~headers, ~body, ()),
    )
    ->Promise.then(handleResponse)
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Ok(response) =>
        Fetch.json(response)
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
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => handleError(e, "Similarity calculation failed", "SIMILARITY_BATCH_ERROR"))
  })
}
