/* src/systems/BackendApi.res */

open ReBindings

/* --- API TYPES (Matching Rust Structs) --- */

type validationReport = {
  brokenLinksRemoved: int,
  orphanedScenes: array<string>,
  unusedFiles: array<string>,
  warnings: array<string>,
  errors: array<string>,
}

type exifMetadata = {
  make: Nullable.t<string>,
  model: Nullable.t<string>,
  dateTime: Nullable.t<string>,
  width: int,
  height: int,
  focalLength: Nullable.t<float>,
  aperture: Nullable.t<float>,
  iso: Nullable.t<int>,
}

type qualityStats = {
  avgLuminance: int,
  blackClipping: float,
  whiteClipping: float,
  sharpnessVariance: int,
}

type qualityAnalysis = {
  score: float,
  histogram: array<int>,
  stats: qualityStats,
  isBlurry: bool,
  isSoft: bool,
  isSeverelyDark: bool,
  isDim: bool,
  hasBlackClipping: bool,
  hasWhiteClipping: bool,
  issues: int,
  warnings: int,
  analysis: Nullable.t<string>,
}

type metadataResponse = {
  exif: exifMetadata,
  quality: qualityAnalysis,
  isOptimized: bool,
  checksum: string,
  suggestedName: Nullable.t<string>,
}

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

type similarityPair = {
  idA: string,
  idB: string,
  histogramA: JSON.t,
  histogramB: JSON.t,
}

type similarityResult = {
  idA: string,
  idB: string,
  similarity: float,
}

type similarityResponse = {
  results: array<similarityResult>,
  durationMs: float,
}

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
let importProject = (file: File.t): Promise.t<importResponse> => {
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
  ->Promise.then(json => Promise.resolve((Obj.magic(json): importResponse)))
}

/**
 * Validates a project ZIP and returns a validation report
 */
let validateProject = (file: File.t): Promise.t<validationReport> => {
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
}

/**
 * Loads a project ZIP and returns it as a Blob
 * This ZIP contains project.json and all scene images
 */
let loadProject = (file: File.t): Promise.t<Blob.t> => {
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
}

/**
 * Extracts metadata and quality analysis for an image
 */
let extractMetadata = (file: File.t): Promise.t<metadataResponse> => {
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
}

/**
 * Processes an image (resizes, optimizes) and returns a ZIP blob
 * ZIP contains preview.webp, tiny.webp, and metadata.json
 */
let processImageFull = (file: File.t): Promise.t<Blob.t> => {
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
}

/**
 * Saves a project by sending the project JSON to the backend
 * The backend bundles it into a ZIP and returns it
 */
let saveProject = (projectData: 'a): Promise.t<Blob.t> => {
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
}


/**
 * Calculates a navigation path (Teaser/Timeline) via Backend
 */
let calculatePath = (payload: pathRequest): Promise.t<array<step>> => {
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
  ->Promise.then(json => Promise.resolve((Obj.magic(json): array<step>)))
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
      Promise.resolve("[Geocoding service unavailable]")
    } else {
      Fetch.json(response)->Promise.then(json => {
        let data: geocodeResponse = Obj.magic(json)
        Promise.resolve(data.address)
      })
    }
  })
  ->Promise.catch(_ => {
    Promise.resolve("[Geocoding failed]")
  })
}


/**
 * Calculates similarity for multiple pairs in parallel on the backend
 */
let batchCalculateSimilarity = (pairs: array<similarityPair>): Promise.t<array<similarityResult>> => {
  let headers = Dict.make()
  Dict.set(headers, "Content-Type", "application/json")

  Fetch.fetch(
    Constants.backendUrl ++ "/api/media/similarity",
    {
      method: "POST",
      headers: Nullable.make(headers),
      body: JSON.stringify(Obj.magic({
        "pairs": pairs,
      })),
    },
  )
  ->Promise.then(handleResponse)
  ->Promise.then(Fetch.json)
  ->Promise.then(json => {
    let data: similarityResponse = Obj.magic(json)
    Promise.resolve(data.results)
  })
  ->Promise.catch(e => {
    Logger.error(
      ~module_="BackendApi",
      ~message="SIMILARITY_BATCH_ERROR",
      ~data=Obj.magic({"error": e}),
      (),
    )
    Promise.resolve([])
  })
}
