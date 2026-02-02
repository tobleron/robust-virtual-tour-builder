/* src/systems/ApiHelpers.res */

open SharedTypes
open ReBindings

type importResponse = SharedTypes.importResponse
// type geocodeRequest = SharedTypes.geocodeRequest // Already defined in SharedTypes
type geocodeResponse = SharedTypes.geocodeResponse

type transitionTarget = Types.transitionTarget
type arrivalView = Types.arrivalView
type step = Types.step

type pathRequest = Types.pathRequest

type apiError = {
  error: string,
  details: Nullable.t<string>,
}

type apiResult<'a> = result<'a, string>

let decodeImportResponse = (json: JSON.t): result<importResponse, string> => {
  JsonCombinators.Json.decode(json, JsonParsers.Shared.importResponse)
}

let decodeValidationReport = (json: JSON.t): result<validationReport, string> => {
  JsonCombinators.Json.decode(json, JsonParsers.Shared.validationReport)
}

let decodeMetadataResponse = (json: JSON.t): result<metadataResponse, string> => {
  JsonCombinators.Json.decode(json, JsonParsers.Shared.metadataResponse)
}

let decodeSteps = (json: JSON.t): result<array<step>, string> => {
  JsonCombinators.Json.decode(json, JsonParsers.Domain.steps)
}

let decodeGeocodeResponse = (json: JSON.t): result<geocodeResponse, string> => {
  JsonCombinators.Json.decode(json, JsonParsers.Shared.geocodeResponse)
}

let decodeSimilarityResponse = (json: JSON.t): result<similarityResponse, string> => {
  JsonCombinators.Json.decode(json, JsonParsers.Shared.similarityResponse)
}

let extractErrorMessage = (json: apiError): string => {
  switch Nullable.toOption(json.details) {
  | Some(d) => d
  | None => json.error
  }
}

let processErrorResponse = (response: Fetch.response): Promise.t<apiResult<Fetch.response>> => {
  Fetch.json(response)
  ->Promise.then(json => {
    // Safely extract message from JSON.t without unsafe record casting
    let msg = switch JsonCombinators.Json.decode(
      json,
      JsonCombinators.Json.Decode.oneOf([
        JsonCombinators.Json.Decode.field("message", JsonCombinators.Json.Decode.string),
        JsonCombinators.Json.Decode.field("error", JsonCombinators.Json.Decode.string),
        JsonCombinators.Json.Decode.field("detail", JsonCombinators.Json.Decode.string),
        JsonCombinators.Json.Decode.field("details", JsonCombinators.Json.Decode.string),
        JsonCombinators.Json.Decode.field("msg", JsonCombinators.Json.Decode.string),
      ]),
    ) {
    | Ok(m) => m
    | Error(_) =>
      // Fallback: If it's a simple string, use it. If it's an object, stringify briefly or use statusText
      switch JsonCombinators.Json.decode(json, JsonCombinators.Json.Decode.string) {
      | Ok(s) => s
      | Error(_) => Fetch.statusText(response)
      }
    }

    Logger.error(
      ~module_="ApiHelpers",
      ~message="Backend Error",
      ~data=JsonCombinators.Json.Encode.object([
        ("status", JsonCombinators.Json.Encode.int(Fetch.status(response))),
        ("message", JsonCombinators.Json.Encode.string(msg)),
      ]),
      (),
    )
    Promise.resolve(
      Error("Backend error: " ++ Belt.Int.toString(Fetch.status(response)) ++ " " ++ msg),
    )
  })
  ->Promise.catch(e => {
    let (msg, _) = Logger.getErrorDetails(e)
    Logger.error(
      ~module_="ApiHelpers",
      ~message="Fetch/Network Error",
      ~data=JsonCombinators.Json.Encode.object([
        ("status", JsonCombinators.Json.Encode.int(Fetch.status(response))),
        ("message", JsonCombinators.Json.Encode.string(msg)),
      ]),
      (),
    )
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

let handleResponse = (response: Fetch.response): Promise.t<apiResult<Fetch.response>> => {
  if Fetch.status(response) == 401 {
    Dom.Storage2.localStorage->Dom.Storage2.removeItem("auth_token")
    let _ = %raw("window.dispatchEvent(new Event('auth:logout'))")
    Logger.warn(
      ~module_="ApiHelpers",
      ~message="UNAUTHORIZED",
      ~data=JsonCombinators.Json.Encode.object([
        (
          "action",
          JsonCombinators.Json.Encode.string(
            "Cleared invalid auth_token, next request will use fallback",
          ),
        ),
      ]),
      (),
    )
  }

  if Fetch.ok(response) {
    Promise.resolve(Ok(response))
  } else {
    processErrorResponse(response)
  }
}
