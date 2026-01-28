open RescriptSchema
/* src/systems/api/ApiTypes.res */

open ReBindings
open SharedTypes

/* --- API TYPES (Matching Rust Structs) --- */

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

/* --- PATHFINDER TYPES Re-exported for convenience --- */

type transitionTarget = Types.transitionTarget
type arrivalView = Types.arrivalView
type step = Types.step

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

/* --- DECODERS (Safe: Schema-backed parsers) --- */

let decodeImportResponse = (json: JSON.t): result<importResponse, string> => {
  Schemas.parse(json, Schemas.Shared.importResponse)->Result.flatMap(((sessionId, projectData)) => {
     if sessionId == "" {
       Error("Session ID required")
     } else {
       Ok({
         sessionId: sessionId,
         projectData: projectData
       })
     }
  })
}

let decodeValidationReport = (json: JSON.t): result<validationReport, string> => {
  Schemas.parse(json, Schemas.Shared.validationReport)
}

let decodeMetadataResponse = (json: JSON.t): result<metadataResponse, string> => {
  Schemas.parse(json, Schemas.Shared.metadataResponse)
}

let decodeSteps = (json: JSON.t): result<array<step>, string> => {
  Schemas.parse(json, S.array(Schemas.Domain.step))
}

let decodeGeocodeResponse = (json: JSON.t): result<geocodeResponse, string> => {
  Schemas.parse(json, Schemas.Shared.geocodeResponse)->Result.map(address => {
    address: address,
  })
}

let decodeSimilarityResponse = (json: JSON.t): result<similarityResponse, string> => {
  Schemas.parse(json, Schemas.Shared.similarityResponse)
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
