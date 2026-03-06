/* src/systems/Api/ProjectApi.res */

open ApiHelpers
open ReBindings

include ProjectImportOrchestrator

let saveProject = (sessionId: string, projectData: JSON.t): Promise.t<apiResult<unit>> => {
  let formData = FormData.newFormData()
  FormData.append(formData, "project_data", JsonCombinators.Json.stringify(projectData))
  FormData.append(formData, "session_id", sessionId)

  RequestQueue.schedule(() => {
    AuthenticatedClient.requestWithRetry(
      Constants.backendUrl ++ "/api/project/save",
      ~method="POST",
      ~formData,
      ~dedupeKey="project-save:" ++ sessionId,
      (),
    )
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Retry.Success(_, _) => Promise.resolve(Ok())
      | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => handleError(~module_="ProjectApi", e, "Project save failed", "SAVE_ERROR"))
  })
}

let calculatePath = (~signal: option<ReBindings.AbortSignal.t>=?, payload: pathRequest): Promise.t<
  apiResult<array<step>>,
> => {
  RequestQueue.schedule(() => {
    let body = AuthenticatedClient.castBody(JsonParsers.Encoders.pathRequest(payload))

    AuthenticatedClient.requestWithRetry(
      Constants.backendUrl ++ "/api/project/calculate-path",
      ~method="POST",
      ~body,
      ~signal?,
      (),
    )
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Retry.Success(response, _) =>
        response.json()
        ->Promise.then(
          json =>
            handleJsonDecode(
              ~module_="ProjectApi",
              json,
              decodeSteps,
              "CALCULATE_PATH",
              "Path calculation failed",
            ),
        )
        ->Promise.catch(
          e =>
            handleError(
              ~module_="ProjectApi",
              e,
              "Path calculation failed: JSON parsing error",
              "CALCULATE_PATH_ERROR_JSON_DECODE",
            ),
        )
      | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e =>
      handleError(~module_="ProjectApi", e, "Path calculation failed", "CALCULATE_PATH_ERROR")
    )
  })
}

let reverseGeocode = (lat: float, lon: float): Promise.t<apiResult<geocodeResponse>> => {
  RequestQueue.schedule(() => {
    let body = JsonCombinators.Json.Encode.object([
      ("lat", JsonCombinators.Json.Encode.float(lat)),
      ("lon", JsonCombinators.Json.Encode.float(lon)),
    ])

    AuthenticatedClient.requestWithRetry(
      Constants.backendUrl ++ "/api/geocoding/reverse",
      ~method="POST",
      ~body=AuthenticatedClient.castBody(body),
      (),
    )
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Retry.Success(response, _) =>
        response.json()
        ->Promise.then(
          json =>
            handleJsonDecode(
              ~module_="ProjectApi",
              json,
              decodeGeocodeResponse,
              "GEOCODE",
              "Geocoding failed",
            ),
        )
        ->Promise.catch(
          e => {
            let (msg, _) = Logger.getErrorDetails(e)
            Promise.resolve(Error("Decoding geocode response failed: " ++ msg))
          },
        )
      | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e =>
      handleError(~module_="ProjectApi", e, "Geocoding failed", "GEOCODE_FAILED")
    )
  })
}
