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
