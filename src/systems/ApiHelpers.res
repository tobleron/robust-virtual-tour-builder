/* src/systems/ApiHelpers.res */

open SharedTypes
open RescriptSchema
open ReBindings

type importResponse = {
  sessionId: string,
  projectData: JSON.t,
}

type geocodeRequest = SharedTypes.geocodeRequest

type geocodeResponse = {address: string}

type transitionTarget = Types.transitionTarget
type arrivalView = Types.arrivalView
type step = Types.step

type pathRequest = Types.pathRequest

type apiError = {
  error: string,
  details: Nullable.t<string>,
}

type apiResult<'a> = result<'a, string>

/* Decoders using Schemas */
let decodeImportResponse = (json: JSON.t): result<importResponse, string> => {
  Schemas.parse(json, Schemas.Shared.importResponse)->Result.flatMap(((sessionId, projectData)) => {
    if sessionId == "" {
      Error("Session ID required")
    } else {
      Ok({
        sessionId,
        projectData,
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

let extractErrorMessage = (json: apiError): string => {
  switch Nullable.toOption(json.details) {
  | Some(d) => d
  | None => json.error
  }
}

let processErrorResponse = (response: Fetch.response): Promise.t<apiResult<Fetch.response>> => {
  Fetch.json(response)
  ->Promise.then((json: apiError) => {
    let msg = extractErrorMessage(json)
    Logger.error(
      ~module_="ApiHelpers",
      ~message="Backend Error",
      ~data=Obj.magic({"status": Fetch.status(response), "message": msg}),
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
      ~data=Obj.magic({"status": Fetch.status(response), "message": msg}),
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
  if Fetch.ok(response) {
    Promise.resolve(Ok(response))
  } else {
    processErrorResponse(response)
  }
}
