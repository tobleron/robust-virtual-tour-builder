// @efficiency-role: data-model

open SharedTypes
open RescriptSchema
open ReBindings

/* From ApiLogic.res - ApiTypes */
type importResponse = {
  sessionId: string,
  projectData: JSON.t,
}

type geocodeRequest = {
  lat: float,
  lon: float,
}

type geocodeResponse = {address: string}

type transitionTarget = Types.transitionTarget
type arrivalView = Types.arrivalView
type step = Types.step

type pathRequest = {
  @as("type") type_: string,
  scenes: array<Types.scene>,
  skipAutoForward: bool,
  timeline?: array<Types.timelineItem>,
}

type apiError = {
  error: string,
  details: Nullable.t<string>,
}

type apiResult<'a> = result<'a, string>

/* Decoders using Schemas */
let decodeImportResponse = (json: JSON.t): result<importResponse, string> => {
  Schemas.parse(json, Schemas.Shared.importResponse)->Result.flatMap(((
    sessionId,
    projectData,
  )) => {
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
