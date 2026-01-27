/* src/systems/api/ApiTypes.res */

open ReBindings
open SharedTypes

/* --- API TYPES (Matching Rust Structs) --- */

// Types used from SharedTypes:
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

let parse = (json: 'any, schema: RescriptSchema.S.t<'a>): result<'a, string> => {
  try {
    Ok(RescriptSchema.S.parseOrThrow(json, schema))
  } catch {
  | exn => Error(RescriptSchema.S.Error.message(Obj.magic(exn)))
  }
}

let decodeImportResponse = (json: JSON.t): result<importResponse, string> => {
  parse(json, Schemas.Shared.importResponse)->Result.map(((sessionId, projectData)) => {
    sessionId,
    projectData,
  })
}

let decodeValidationReport = (json: JSON.t): result<validationReport, string> => {
  parse(json, Schemas.Shared.validationReport)
}

let decodeMetadataResponse = (json: JSON.t): result<metadataResponse, string> => {
  parse(json, Schemas.Shared.metadataResponse)
}

let decodeSteps = (json: JSON.t): result<array<step>, string> => {
  parse(json, RescriptSchema.S.array(JsonTypes.JsonSchemas.step))->Result.map(jsonSteps => {
    jsonSteps->Belt.Array.map(js => {
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
  })
}

let decodeGeocodeResponse = (json: JSON.t): result<geocodeResponse, string> => {
  parse(json, Schemas.Shared.geocodeResponse)->Result.map(address => {
    address: address,
  })
}

let decodeSimilarityResponse = (json: JSON.t): result<similarityResponse, string> => {
  parse(json, Schemas.Shared.similarityResponse)
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
