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
 * Validates a project ZIP and returns a validation report
 */
let validateProject = (file: File.t): Promise.t<validationReport> => {
  let formData = FormData.newFormData()
  FormData.append(formData, "file", file)

  Fetch.fetch(
    Constants.backendUrl ++ "/validate-project",
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
    Constants.backendUrl ++ "/load-project",
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
    Constants.backendUrl ++ "/extract-metadata",
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
    Constants.backendUrl ++ "/process-image-full",
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
    Constants.backendUrl ++ "/save-project",
    {
      method: "POST",
      body: formData,
      headers: Nullable.null,
    },
  )
  ->Promise.then(handleResponse)
  ->Promise.then(Fetch.blob)
}
