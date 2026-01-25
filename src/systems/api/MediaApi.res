/* src/systems/api/MediaApi.res */

open ReBindings
open SharedTypes
open ApiTypes

/* --- API CALLS: Media Logic --- */

/**
 * Extracts metadata and quality analysis for an image
 */
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
          json => {
            switch decodeMetadataResponse(json) {
            | Ok(data) => Promise.resolve(Ok(data))
            | Error(msg) => Promise.resolve(Error(msg))
            }
          },
        )
        ->Promise.catch(
          e => {
            let (msg, stack) = Logger.getErrorDetails(e)
            Logger.error(
              ~module_="MediaApi",
              ~message="METADATA_ERROR_JSON_DECODE",
              ~data=Logger.castToJson({"error": msg, "stack": stack}),
              (),
            )
            Promise.resolve(Error("Metadata extraction failed: JSON parsing or decoding error"))
          },
        )
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => {
      let (msg, stack) = Logger.getErrorDetails(e)
      Logger.error(
        ~module_="MediaApi",
        ~message="METADATA_ERROR",
        ~data=Logger.castToJson({"error": msg, "stack": stack}),
        (),
      )
      Promise.resolve(Error("Metadata extraction failed"))
    })
  })
}

/**
 * Processes an image (resizes, optimizes) and returns a ZIP blob
 * ZIP contains preview.webp, tiny.webp, and metadata.json
 */
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
    | Some(m) => FormData.append(formData, "metadata", JSON.stringify(Logger.castToJson(m)))
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
          e => {
            let (msg, stack) = Logger.getErrorDetails(e)
            Logger.error(
              ~module_="MediaApi",
              ~message="PROCESSING_ERROR_BLOB_CONVERSION",
              ~data=Logger.castToJson({"error": msg, "stack": stack}),
              (),
            )
            Promise.resolve(Error("Image processing failed: Blob conversion error"))
          },
        )
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => {
      let (msg, stack) = Logger.getErrorDetails(e)
      Logger.error(
        ~module_="MediaApi",
        ~message="PROCESSING_ERROR",
        ~data=Logger.castToJson({"error": msg, "stack": stack}),
        (),
      )
      Promise.resolve(Error("Image processing failed"))
    })
  })
}

/**
 * Calculates similarity for multiple pairs in parallel on the backend
 */
let batchCalculateSimilarity = (pairs: array<similarityPair>): Promise.t<
  apiResult<array<similarityResult>>,
> => {
  RequestQueue.schedule(() => {
    let headers = Dict.make()
    Dict.set(headers, "Content-Type", "application/json")

    Fetch.fetch(
      Constants.backendUrl ++ "/api/media/similarity",
      Fetch.requestInit(
        ~method="POST",
        ~headers,
        ~body=JSON.stringify(
          Logger.castToJson({
            "pairs": pairs,
          }),
        ),
        (),
      ),
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
          e => {
            let (msg, stack) = Logger.getErrorDetails(e)
            Logger.error(
              ~module_="MediaApi",
              ~message="SIMILARITY_BATCH_ERROR_JSON_DECODE",
              ~data=Logger.castToJson({"error": msg, "stack": stack}),
              (),
            )
            Promise.resolve(Error("Similarity calculation failed: JSON parsing or decoding error"))
          },
        )
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => {
      let (msg, stack) = Logger.getErrorDetails(e)
      Logger.error(
        ~module_="MediaApi",
        ~message="SIMILARITY_BATCH_ERROR",
        ~data=Logger.castToJson({"error": msg, "stack": stack}),
        (),
      )
      Promise.resolve(Error("Similarity calculation failed"))
    })
  })
}
