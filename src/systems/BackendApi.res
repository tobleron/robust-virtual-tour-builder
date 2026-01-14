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

type geocodeResponse = {
  address: string,
}

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

/* --- HELPER: Handle Response --- */

let handleResponse = (response: Fetch.response) => {
  if Fetch.ok(response) {
    Promise.resolve(response)
  } else {
    Fetch.json(response)
    ->Promise.then((json: apiError) => {
      let msg = switch Nullable.toOption(json.details) {
      | Some(d) => d
      | None => json.error
      }
      Promise.reject(
        JsError.throwWithMessage(
          "Backend error: " ++ Belt.Int.toString(Fetch.status(response)) ++ " " ++ msg,
        ),
      )
    })
    ->Promise.catch(_ => {
      Promise.reject(
        JsError.throwWithMessage(
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

/**
 * Imports a project ZIP via backend
 * Returns sessionId and projectData JSON
 */
let importProject = (file: File.t): Promise.t<apiResult<importResponse>> => {
  let formData = FormData.newFormData()
  FormData.append(formData, "file", file)

  Fetch.fetch(
    Constants.backendUrl ++ "/api/project/import",
    {
      method: "POST",
      body: formData,
      headers: Nullable.null,
    },
  )
  ->Promise.then(handleResponse)
  ->Promise.then(Fetch.json)
  ->Promise.then(json => Promise.resolve(Ok((Obj.magic(json): importResponse))))
  ->Promise.catch(e => {
    Logger.error(
      ~module_="BackendApi",
      ~message="IMPORT_ERROR",
      ~data=Obj.magic({"error": e}),
      (),
    )
    Promise.resolve(Error("Project import failed"))
  })
}

/**
 * Validates a project ZIP and returns a validation report
 */
let validateProject = (file: File.t): Promise.t<apiResult<validationReport>> => {
  let formData = FormData.newFormData()
  FormData.append(formData, "file", file)

  Fetch.fetch(
    Constants.backendUrl ++ "/api/project/validate",
    {
      method: "POST",
      body: formData,
      headers: Nullable.null,
    },
  )
  ->Promise.then(handleResponse)
  ->Promise.then(Fetch.json)
  ->Promise.then(json => Promise.resolve(Ok((Obj.magic(json): validationReport))))
  ->Promise.catch(e => {
    Logger.error(
      ~module_="BackendApi",
      ~message="VALIDATION_ERROR",
      ~data=Obj.magic({"error": e}),
      (),
    )
    Promise.resolve(Error("Project validation failed"))
  })
}

/**
 * Loads a project ZIP and returns it as a Blob
 * This ZIP contains project.json and all scene images
 */
let loadProject = (file: File.t): Promise.t<apiResult<Blob.t>> => {
  let formData = FormData.newFormData()
  FormData.append(formData, "file", file)

  Fetch.fetch(
    Constants.backendUrl ++ "/api/project/load",
    {
      method: "POST",
      body: formData,
      headers: Nullable.null,
    },
  )
  ->Promise.then(handleResponse)
  ->Promise.then(Fetch.blob)
  ->Promise.then(blob => Promise.resolve(Ok(blob)))
  ->Promise.catch(e => {
    Logger.error(
      ~module_="BackendApi",
      ~message="LOAD_ERROR",
      ~data=Obj.magic({"error": e}),
      (),
    )
    Promise.resolve(Error("Project load failed"))
  })
}

/**
 * Extracts metadata and quality analysis for an image
 */
let extractMetadata = (file: File.t): Promise.t<apiResult<metadataResponse>> => {
  let formData = FormData.newFormData()
  FormData.append(formData, "file", file)

  Fetch.fetch(
    Constants.backendUrl ++ "/api/media/extract-metadata",
    {
      method: "POST",
      body: formData,
      headers: Nullable.null,
    },
  )
  ->Promise.then(handleResponse)
  ->Promise.then(Fetch.json)
  ->Promise.then(json => Promise.resolve(Ok((Obj.magic(json): metadataResponse))))
  ->Promise.catch(e => {
    Logger.error(
      ~module_="BackendApi",
      ~message="METADATA_ERROR",
      ~data=Obj.magic({"error": e}),
      (),
    )
    Promise.resolve(Error("Metadata extraction failed"))
  })
}

/**
 * Processes an image (resizes, optimizes) and returns a ZIP blob
 * ZIP contains preview.webp, tiny.webp, and metadata.json
 */
let processImageFull = (file: File.t): Promise.t<apiResult<Blob.t>> => {
  let formData = FormData.newFormData()
  FormData.append(formData, "file", file)

  Fetch.fetch(
    Constants.backendUrl ++ "/api/media/process-full",
    {
      method: "POST",
      body: formData,
      headers: Nullable.null,
    },
  )
  ->Promise.then(handleResponse)
  ->Promise.then(Fetch.blob)
  ->Promise.then(blob => Promise.resolve(Ok(blob)))
  ->Promise.catch(e => {
    Logger.error(
      ~module_="BackendApi",
      ~message="PROCESSING_ERROR",
      ~data=Obj.magic({"error": e}),
      (),
    )
    Promise.resolve(Error("Image processing failed"))
  })
}

/**
 * Saves a project by sending the project JSON to the backend
 * The backend bundles it into a ZIP and returns it
 */
let saveProject = (projectData: JSON.t): Promise.t<apiResult<Blob.t>> => {
  let formData = FormData.newFormData()
  FormData.append(formData, "project_data", projectData)

  Fetch.fetch(
    Constants.backendUrl ++ "/api/project/save",
    {
      method: "POST",
      body: formData,
      headers: Nullable.null,
    },
  )
  ->Promise.then(handleResponse)
  ->Promise.then(Fetch.blob)
  ->Promise.then(blob => Promise.resolve(Ok(blob)))
  ->Promise.catch(e => {
    Logger.error(
      ~module_="BackendApi",
      ~message="SAVE_ERROR",
      ~data=Obj.magic({"error": e}),
      (),
    )
    Promise.resolve(Error("Project save failed"))
  })
}


/**
 * Calculates a navigation path (Teaser/Timeline) via Backend
 */
let calculatePath = (payload: pathRequest): Promise.t<apiResult<array<step>>> => {
  let headers = Dict.make()
  Dict.set(headers, "Content-Type", "application/json")

  Fetch.fetch(
    Constants.backendUrl ++ "/api/project/calculate-path",
    {
      method: "POST",
      body: JSON.stringify(Obj.magic(payload)),
      headers: Nullable.make(headers),
    },
  )
  ->Promise.then(handleResponse)
  ->Promise.then(Fetch.json)
  ->Promise.then(json => Promise.resolve(Ok((Obj.magic(json): array<step>))))
  ->Promise.catch(e => {
    Logger.error(
      ~module_="BackendApi",
      ~message="CALCULATE_PATH_ERROR",
      ~data=Obj.magic({"error": e}),
      (),
    )
    Promise.resolve(Error("Path calculation failed"))
  })
}

/**
 * Reverse geocodes coordinates to a human-readable address
 * Uses backend proxy for privacy and caching
 */
let reverseGeocode = (lat: float, lon: float): Promise.t<string> => {
  let headers = Dict.make()
  Dict.set(headers, "Content-Type", "application/json")

  Fetch.fetch(
    Constants.backendUrl ++ "/api/geocoding/reverse",
    {
      method: "POST",
      headers: Nullable.make(headers),
      body: JSON.stringify(Obj.magic({
        lat: lat,
        lon: lon,
      })),
    },
  )
  ->Promise.then(response => {
    if !Fetch.ok(response) {
      Logger.warn(
        ~module_="BackendApi",
        ~message="GEOCODE_SERVICE_UNAVAILABLE",
        ~data=Obj.magic({"status": Fetch.status(response)}),
        (),
      )
      Promise.resolve("[Geocoding service unavailable]")
    } else {
      Fetch.json(response)->Promise.then(json => {
        let data: geocodeResponse = Obj.magic(json)
        Promise.resolve(data.address)
      })
    }
  })
  ->Promise.catch(e => {
    Logger.error(
      ~module_="BackendApi",
      ~message="GEOCODE_FAILED",
      ~data=Obj.magic({"error": e}),
      (),
    )
    Promise.resolve("[Geocoding failed]")
  })
}


/**
 * Calculates similarity for multiple pairs in parallel on the backend
 */
let batchCalculateSimilarity = (
  pairs: array<similarityPair>,
): Promise.t<apiResult<array<similarityResult>>> => {
  let headers = Dict.make()
  Dict.set(headers, "Content-Type", "application/json")

  Fetch.fetch(
    Constants.backendUrl ++ "/api/media/similarity",
    {
      method: "POST",
      headers: Nullable.make(headers),
      body: JSON.stringify(
        Obj.magic({
          "pairs": pairs,
        }),
      ),
    },
  )
  ->Promise.then(handleResponse)
  ->Promise.then(Fetch.json)
  ->Promise.then(json => {
    let data: similarityResponse = Obj.magic(json)
    Promise.resolve(Ok(data.results))
  })
  ->Promise.catch(e => {
    Logger.error(
      ~module_="BackendApi",
      ~message="SIMILARITY_BATCH_ERROR",
      ~data=Obj.magic({"error": e}),
      (),
    )
    Promise.resolve(Error("Similarity calculation failed"))
  })
}
