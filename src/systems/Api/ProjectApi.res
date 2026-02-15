/* src/systems/Api/ProjectApi.res */

open ApiHelpers
open ReBindings

let handleError = (e, message, logKey) => {
  let (msg, stack) = Logger.getErrorDetails(e)
  Logger.error(
    ~module_="ProjectApi",
    ~message=logKey,
    ~data=Logger.castToJson({"error": msg, "stack": stack}),
    (),
  )
  Promise.resolve(Error(message))
}

let handleJsonDecode = (json, decoder, logKey, errorMessage) => {
  switch decoder(json) {
  | Ok(data) => Promise.resolve(Ok(data))
  | Error(msg) =>
    Logger.error(
      ~module_="ProjectApi",
      ~message=logKey ++ "_DECODE_FAILED",
      ~data=Logger.castToJson({"error": msg}),
      (),
    )
    Promise.resolve(Error(errorMessage ++ ": " ++ msg))
  }
}

let importProject = (file: File.t): Promise.t<apiResult<importResponse>> => {
  RequestQueue.schedule(() => {
    let formData = FormData.newFormData()
    // Backend expects 'file' field for multipart imports
    FormData.append(formData, "file", file)

    AuthenticatedClient.requestWithRetry(
      Constants.backendUrl ++ "/api/project/import",
      ~method="POST",
      ~formData,
      (),
    )
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Retry.Success(response, _) =>
        response.json()
        ->Promise.then(
          json => handleJsonDecode(json, decodeImportResponse, "IMPORT", "Project import failed"),
        )
        ->Promise.catch(
          e =>
            handleError(e, "Project import failed: JSON parsing error", "IMPORT_ERROR_JSON_DECODE"),
        )
      | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => handleError(e, "Project import failed", "IMPORT_ERROR"))
  })
}

let loadProject = (sessionId: string): Promise.t<apiResult<importResponse>> => {
  RequestQueue.schedule(() => {
    AuthenticatedClient.requestWithRetry(
      Constants.backendUrl ++ "/api/project/load/" ++ sessionId,
      ~method="GET",
      (),
    )
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Retry.Success(response, _) =>
        response.json()
        ->Promise.then(
          json => handleJsonDecode(json, decodeImportResponse, "LOAD", "Project load failed"),
        )
        ->Promise.catch(
          e => handleError(e, "Project load failed: JSON parsing error", "LOAD_ERROR_JSON_DECODE"),
        )
      | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => handleError(e, "Project load failed", "LOAD_ERROR"))
  })
}

let validateProject = (sessionId: string, projectData: JSON.t): Promise.t<
  apiResult<SharedTypes.validationReport>,
> => {
  RequestQueue.schedule(() => {
    AuthenticatedClient.requestWithRetry(
      Constants.backendUrl ++ "/api/project/validate/" ++ sessionId,
      ~method="POST",
      ~body=projectData,
      (),
    )
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Retry.Success(response, _) =>
        response.json()
        ->Promise.then(
          json =>
            handleJsonDecode(
              json,
              decodeValidationReport,
              "VALIDATION",
              "Project validation failed",
            ),
        )
        ->Promise.catch(
          e => {
            let (msg, _) = Logger.getErrorDetails(e)
            Promise.resolve(Error("Decoding validation report failed: " ++ msg))
          },
        )
      | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => handleError(e, "Project validation failed", "VALIDATION_ERROR"))
  })
}

let saveProject = (sessionId: string, projectData: JSON.t): Promise.t<apiResult<unit>> => {
  let formData = FormData.newFormData()
  FormData.append(formData, "project_data", JsonCombinators.Json.stringify(projectData))
  FormData.append(formData, "session_id", sessionId)

  RequestQueue.schedule(() => {
    AuthenticatedClient.requestWithRetry(
      Constants.backendUrl ++ "/api/project/save",
      ~method="POST",
      ~formData,
      (),
    )
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Retry.Success(_, _) => Promise.resolve(Ok())
      | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => handleError(e, "Project save failed", "SAVE_ERROR"))
  })
}

let calculatePath = (payload: pathRequest): Promise.t<apiResult<array<step>>> => {
  RequestQueue.schedule(() => {
    let body = AuthenticatedClient.castBody(JsonParsers.Encoders.pathRequest(payload))

    AuthenticatedClient.requestWithRetry(
      Constants.backendUrl ++ "/api/project/calculate-path",
      ~method="POST",
      ~body,
      (),
    )
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Retry.Success(response, _) =>
        response.json()
        ->Promise.then(
          json => handleJsonDecode(json, decodeSteps, "CALCULATE_PATH", "Path calculation failed"),
        )
        ->Promise.catch(
          e =>
            handleError(
              e,
              "Path calculation failed: JSON parsing error",
              "CALCULATE_PATH_ERROR_JSON_DECODE",
            ),
        )
      | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => handleError(e, "Path calculation failed", "CALCULATE_PATH_ERROR"))
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
          json => handleJsonDecode(json, decodeGeocodeResponse, "GEOCODE", "Geocoding failed"),
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
    ->Promise.catch(e => handleError(e, "Geocoding failed", "GEOCODE_FAILED"))
  })
}
