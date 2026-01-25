/* src/systems/BackendApi.res */

open ReBindings
open SharedTypes
/* --- API TYPES (Matching Rust Structs) --- */

// Types imported from SharedTypes:
// - validationReport
// - exifMetadata
// - qualityAnalysis
// - metadataResponse

type importResponse = {
  sessionId: string,
  projectData: JSON.t,
}

/* --- GEOCoding TYPES --- */

type geocodeRequest = {
  lat: float,
  lon: float,
}

type geocodeResponse = {address: string}

/* --- SIMILARITY TYPES --- */

// Moved to SharedTypes

/* --- PATHFINDER TYPES --- */

type transitionTarget = {
  yaw: float,
  pitch: float,
  targetName: string,
  timelineItemId: option<string>,
}

type arrivalView = {
  yaw: float,
  pitch: float,
}

type step = {
  idx: int,
  transitionTarget: option<transitionTarget>,
  arrivalView: arrivalView,
}

type pathRequest = {
  @as("type") type_: string,
  scenes: array<Types.scene>,
  skipAutoForward: bool,
  timeline?: array<Types.timelineItem>,
}

/* --- API ERROR TYPE --- */

type apiError = {
  error: string,
  details: Nullable.t<string>,
}

type apiResult<'a> = result<'a, string>

/* --- DECODERS (Manual implementation for type safety) --- */

let decodeImportResponse = (json: JSON.t): result<importResponse, string> => {
  switch json {
  | Object(dict) =>
    let sessionId = dict->Dict.get("sessionId")->Option.flatMap(JSON.Decode.string)
    let projectData = dict->Dict.get("projectData")
    switch (sessionId, projectData) {
    | (Some(s), Some(p)) => Ok({sessionId: s, projectData: p})
    | _ => Error("Invalid import response")
    }
  | _ => Error("Expected object for import response")
  }
}

let decodeValidationReport = (json: JSON.t): result<validationReport, string> => {
  // Using safe cast from JsonTypes
  switch json {
  | Object(_) => Ok(JsonTypes.castToValidationReport(json))
  | _ => Error("Invalid validation report")
  }
}

let decodeMetadataResponse = (json: JSON.t): result<metadataResponse, string> => {
  switch json {
  | Object(_) => Ok((JsonTypes.castToMetadataResponse(json): metadataResponse))
  | _ => Error("Invalid metadata response")
  }
}

let decodeSteps = (json: JSON.t): result<array<step>, string> => {
  switch json {
  | Array(_) =>
    let jsonSteps = JsonTypes.castToSteps(json)
    let steps = Belt.Array.map(jsonSteps, js => {
      idx: js.idx,
      arrivalView: {
        yaw: js.arrivalView.yaw,
        pitch: js.arrivalView.pitch,
      },
      transitionTarget: switch Nullable.toOption(js.transitionTarget) {
      | Some(tt) =>
        Some({
          yaw: tt.yaw,
          pitch: tt.pitch,
          targetName: tt.targetName,
          timelineItemId: Nullable.toOption(tt.timelineItemId),
        })
      | None => None
      },
    })
    Ok(steps)
  | _ => Error("Invalid path steps response")
  }
}

let decodeGeocodeResponse = (json: JSON.t): result<geocodeResponse, string> => {
  switch json {
  | Object(dict) =>
    switch dict->Dict.get("address")->Option.flatMap(JSON.Decode.string) {
    | Some(address) => Ok({address: address})
    | None => Error("Missing address in geocode response")
    }
  | _ => Error("Invalid geocode response")
  }
}

let decodeSimilarityResponse = (json: JSON.t): result<similarityResponse, string> => {
  switch json {
  | Object(_) => Ok((JsonTypes.castToSimilarityResponse(json): similarityResponse))
  | _ => Error("Invalid similarity response")
  }
}

/* --- HELPER: Handle Response --- */

let handleResponse = (response: Fetch.response): Promise.t<apiResult<Fetch.response>> => {
  if Fetch.ok(response) {
    Promise.resolve(Ok(response))
  } else {
    Fetch.json(response)
    ->Promise.then((json: apiError) => {
      let msg = switch Nullable.toOption(json.details) {
      | Some(d) => d
      | None => json.error
      }
      Promise.resolve(
        Error("Backend error: " ++ Belt.Int.toString(Fetch.status(response)) ++ " " ++ msg),
      )
    })
    ->Promise.catch(_ => {
      Promise.resolve(
        Error(
          "Backend error: " ++
          Belt.Int.toString(Fetch.status(response)) ++
          " " ++
          Fetch.statusText(response),
        ),
      )
    })
  }
}

/* --- API CALLS --- */

let importProject = (file: File.t): Promise.t<apiResult<importResponse>> => {
  RequestQueue.schedule(() => {
    let formData = FormData.newFormData()
    FormData.append(formData, "file", file)

    Fetch.fetch(
      Constants.backendUrl ++ "/api/project/import",
      Fetch.requestInit(~method="POST", ~body=formData, ()),
    )
    ->Promise.then(handleResponse)
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Ok(response) =>
        Fetch.json(response)
        ->Promise.then(
          json => {
            switch decodeImportResponse(json) {
            | Ok(data) => Promise.resolve(Ok(data))
            | Error(msg) => Promise.resolve(Error(msg))
            }
          },
        )
        ->Promise.catch(
          e => {
            let (msg, stack) = Logger.getErrorDetails(e)
            Logger.error(
              ~module_="BackendApi",
              ~message="IMPORT_ERROR_JSON_DECODE",
              ~data=Logger.castToJson({"error": msg, "stack": stack}),
              (),
            )
            Promise.resolve(Error("Project import failed: JSON parsing or decoding error"))
          },
        )
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => {
      let (msg, stack) = Logger.getErrorDetails(e)
      Logger.error(
        ~module_="BackendApi",
        ~message="IMPORT_ERROR",
        ~data=Logger.castToJson({"error": msg, "stack": stack}),
        (),
      )
      Promise.resolve(Error("Project import failed"))
    })
  })
}

/**
 * Validates a project ZIP and returns a validation report
 */
let validateProject = (file: File.t): Promise.t<apiResult<validationReport>> => {
  RequestQueue.schedule(() => {
    let formData = FormData.newFormData()
    FormData.append(formData, "file", file)

    Fetch.fetch(
      Constants.backendUrl ++ "/api/project/validate",
      Fetch.requestInit(~method="POST", ~body=formData, ()),
    )
    ->Promise.then(handleResponse)
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Ok(response) =>
        Fetch.json(response)
        ->Promise.then(
          json => {
            switch decodeValidationReport(json) {
            | Ok(data) => Promise.resolve(Ok(data))
            | Error(msg) => Promise.resolve(Error(msg))
            }
          },
        )
        ->Promise.catch(
          e => {
            let (msg, stack) = Logger.getErrorDetails(e)
            Logger.error(
              ~module_="BackendApi",
              ~message="VALIDATION_ERROR_JSON_DECODE",
              ~data=Logger.castToJson({"error": msg, "stack": stack}),
              (),
            )
            Promise.resolve(Error("Project validation failed: JSON parsing or decoding error"))
          },
        )
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => {
      let (msg, stack) = Logger.getErrorDetails(e)
      Logger.error(
        ~module_="BackendApi",
        ~message="VALIDATION_ERROR",
        ~data=Logger.castToJson({"error": msg, "stack": stack}),
        (),
      )
      Promise.resolve(Error("Project validation failed"))
    })
  })
}

/**
 * Loads a project ZIP and returns it as a Blob
 * This ZIP contains project.json and all scene images
 */
let loadProject = (file: File.t): Promise.t<apiResult<Blob.t>> => {
  RequestQueue.schedule(() => {
    let formData = FormData.newFormData()
    FormData.append(formData, "file", file)

    Fetch.fetch(
      Constants.backendUrl ++ "/api/project/load",
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
              ~module_="BackendApi",
              ~message="LOAD_ERROR_BLOB_CONVERSION",
              ~data=Logger.castToJson({"error": msg, "stack": stack}),
              (),
            )
            Promise.resolve(Error("Project load failed: Blob conversion error"))
          },
        )
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => {
      let (msg, stack) = Logger.getErrorDetails(e)
      Logger.error(
        ~module_="BackendApi",
        ~message="LOAD_ERROR",
        ~data=Logger.castToJson({"error": msg, "stack": stack}),
        (),
      )
      Promise.resolve(Error("Project load failed"))
    })
  })
}

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
              ~module_="BackendApi",
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
        ~module_="BackendApi",
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
) => {
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
              ~module_="BackendApi",
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
        ~module_="BackendApi",
        ~message="PROCESSING_ERROR",
        ~data=Logger.castToJson({"error": msg, "stack": stack}),
        (),
      )
      Promise.resolve(Error("Image processing failed"))
    })
  })
}

/**
 * Saves a project by sending the project JSON to the backend
 * The backend bundles it into a ZIP and returns it
 */
let saveProject = (projectData: JSON.t): Promise.t<apiResult<Blob.t>> => {
  RequestQueue.schedule(() => {
    let formData = FormData.newFormData()
    FormData.append(formData, "project_data", projectData)

    Fetch.fetch(
      Constants.backendUrl ++ "/api/project/save",
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
              ~module_="BackendApi",
              ~message="SAVE_ERROR_BLOB_CONVERSION",
              ~data=Logger.castToJson({"error": msg, "stack": stack}),
              (),
            )
            Promise.resolve(Error("Project save failed: Blob conversion error"))
          },
        )
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => {
      let (msg, stack) = Logger.getErrorDetails(e)
      Logger.error(
        ~module_="BackendApi",
        ~message="SAVE_ERROR",
        ~data=Logger.castToJson({"error": msg, "stack": stack}),
        (),
      )
      Promise.resolve(Error("Project save failed"))
    })
  })
}

/**
 * Calculates a navigation path (Teaser/Timeline) via Backend
 */
let calculatePath = (payload: pathRequest): Promise.t<apiResult<array<step>>> => {
  RequestQueue.schedule(() => {
    let headers = Dict.make()
    Dict.set(headers, "Content-Type", "application/json")

    Fetch.fetch(
      Constants.backendUrl ++ "/api/project/calculate-path",
      Fetch.requestInit(
        ~method="POST",
        ~body=JSON.stringify(Logger.castToJson(payload)),
        ~headers,
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
            switch decodeSteps(json) {
            | Ok(data) => Promise.resolve(Ok(data))
            | Error(msg) => Promise.resolve(Error(msg))
            }
          },
        )
        ->Promise.catch(
          e => {
            let (msg, stack) = Logger.getErrorDetails(e)
            Logger.error(
              ~module_="BackendApi",
              ~message="CALCULATE_PATH_ERROR_JSON_DECODE",
              ~data=Logger.castToJson({"error": msg, "stack": stack}),
              (),
            )
            Promise.resolve(Error("Path calculation failed: JSON parsing or decoding error"))
          },
        )
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => {
      let (msg, stack) = Logger.getErrorDetails(e)
      Logger.error(
        ~module_="BackendApi",
        ~message="CALCULATE_PATH_ERROR",
        ~data=Logger.castToJson({"error": msg, "stack": stack}),
        (),
      )
      Promise.resolve(Error("Path calculation failed"))
    })
  })
}

/**
 * Reverse geocodes coordinates to a human-readable address
 * Uses backend proxy for privacy and caching
 */
let reverseGeocode = (lat: float, lon: float): Promise.t<apiResult<string>> => {
  RequestQueue.schedule(() => {
    let headers = Dict.make()
    Dict.set(headers, "Content-Type", "application/json")

    Fetch.fetch(
      Constants.backendUrl ++ "/api/geocoding/reverse",
      Fetch.requestInit(
        ~method="POST",
        ~headers,
        ~body=JSON.stringify(
          Logger.castToJson({
            lat,
            lon,
          }),
        ),
        (),
      ),
    )
    ->Promise.then(response => {
      if !Fetch.ok(response) {
        Logger.warn(
          ~module_="BackendApi",
          ~message="GEOCODE_SERVICE_UNAVAILABLE",
          ~data=Logger.castToJson({"status": Fetch.status(response)}),
          (),
        )
        Promise.resolve(Error("Geocoding service unavailable"))
      } else {
        Fetch.json(response)->Promise.then(
          json => {
            switch decodeGeocodeResponse(json) {
            | Ok(data) => Promise.resolve(Ok(data.address))
            | Error(msg) =>
              Logger.warn(
                ~module_="BackendApi",
                ~message="GEOCODE_DECODE_FAILED",
                ~data=Logger.castToJson({"error": msg}),
                (),
              )
              Promise.resolve(Error("Geocoding decode failed: " ++ msg))
            }
          },
        )
      }
    })
    ->Promise.catch(e => {
      let (msg, stack) = Logger.getErrorDetails(e)
      Logger.error(
        ~module_="BackendApi",
        ~message="GEOCODE_FAILED",
        ~data=Logger.castToJson({"error": msg, "stack": stack}),
        (),
      )
      Promise.resolve(Error("Geocoding failed: " ++ msg))
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
              ~module_="BackendApi",
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
        ~module_="BackendApi",
        ~message="SIMILARITY_BATCH_ERROR",
        ~data=Logger.castToJson({"error": msg, "stack": stack}),
        (),
      )
      Promise.resolve(Error("Similarity calculation failed"))
    })
  })
}
