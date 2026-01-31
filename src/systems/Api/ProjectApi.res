/* src/systems/Api/ProjectApi.res */

open ApiHelpers
open ReBindings
open RescriptSchema

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
    FormData.append(formData, "file", file)

    Fetch.fetch(
      Constants.backendUrl ++ "/api/project/import",
      Fetch.requestInit(~method="POST", ~body=formData, ()),
    )
    ->Promise.then(handleResponse)
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Ok(response) =>
        Fetch.json(response)
        ->Promise.then(
          json => handleJsonDecode(json, decodeImportResponse, "IMPORT", "Project import failed"),
        )
        ->Promise.catch(
          e =>
            handleError(e, "Project import failed: JSON parsing error", "IMPORT_ERROR_JSON_DECODE"),
        )
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => handleError(e, "Project import failed", "IMPORT_ERROR"))
  })
}

let loadProject = (sessionId: string): Promise.t<apiResult<importResponse>> => {
  RequestQueue.schedule(() => {
    Fetch.fetch(
      Constants.backendUrl ++ "/api/project/load" ++ sessionId,
      Fetch.requestInit(~method="GET", ()),
    )
    ->Promise.then(handleResponse)
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Ok(response) =>
        Fetch.json(response)
        ->Promise.then(
          json => handleJsonDecode(json, decodeImportResponse, "LOAD", "Project load failed"),
        )
        ->Promise.catch(
          e => handleError(e, "Project load failed: JSON parsing error", "LOAD_ERROR_JSON_DECODE"),
        )
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => handleError(e, "Project load failed", "LOAD_ERROR"))
  })
}

let validateProject = (sessionId: string, projectData: JSON.t): Promise.t<
  apiResult<SharedTypes.validationReport>,
> => {
  RequestQueue.schedule(() => {
    Fetch.fetch(
      Constants.backendUrl ++ "/api/project/validate/" ++ sessionId,
      Fetch.requestInit(
        ~method="POST",
        ~body=JSON.stringify(projectData),
        ~headers=Dict.fromArray([("Content-Type", "application/json")]),
        (),
      ),
    )
    ->Promise.then(handleResponse)
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Ok(response) =>
        Fetch.json(response)
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
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => handleError(e, "Project validation failed", "VALIDATION_ERROR"))
  })
}

let saveProject = (sessionId: string, projectData: JSON.t): Promise.t<apiResult<unit>> => {
  RequestQueue.schedule(() => {
    Fetch.fetch(
      Constants.backendUrl ++ "/api/project/save/" ++ sessionId,
      Fetch.requestInit(
        ~method="POST",
        ~body=JSON.stringify(projectData),
        ~headers=Dict.fromArray([("Content-Type", "application/json")]),
        (),
      ),
    )
    ->Promise.then(handleResponse)
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Ok(_) => Promise.resolve(Ok())
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => handleError(e, "Project save failed", "SAVE_ERROR"))
  })
}

let calculatePath = (payload: pathRequest): Promise.t<apiResult<array<step>>> => {
  RequestQueue.schedule(() => {
    // Replaced manual cast/stringify with Schema serialization
    let body = try {
      S.reverseConvertToJsonStringOrThrow(payload, Schemas.Domain.pathRequest)
    } catch {
    | S.Raised(e) =>
      Logger.error(
        ~module_="ProjectApi",
        ~message="Path serialization failed",
        ~data=Logger.castToJson({"error": S.Error.message(e)}),
        (),
      )
      "{}"
    | _ => "{}"
    }

    Fetch.fetch(
      Constants.backendUrl ++ "/api/project/calculate-path",
      Fetch.requestInit(
        ~method="POST",
        ~body,
        ~headers=Dict.fromArray([("Content-Type", "application/json")]),
        (),
      ),
    )
    ->Promise.then(handleResponse)
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Ok(response) =>
        Fetch.json(response)
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
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => handleError(e, "Path calculation failed", "CALCULATE_PATH_ERROR"))
  })
}

let reverseGeocode = (lat: float, lon: float): Promise.t<apiResult<geocodeResponse>> => {
  RequestQueue.schedule(() => {
    let payload: geocodeRequest = {lat, lon}

    let body = try {
      S.reverseConvertToJsonStringOrThrow(payload, Schemas.Shared.geocodeRequest)
    } catch {
    | _ => "{}"
    }

    Fetch.fetch(
      Constants.backendUrl ++ "/api/geocoding/reverse",
      Fetch.requestInit(
        ~method="POST",
        ~body,
        ~headers=Dict.fromArray([("Content-Type", "application/json")]),
        (),
      ),
    )
    ->Promise.then(handleResponse)
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Ok(response) =>
        Fetch.json(response)
        ->Promise.then(
          json => handleJsonDecode(json, decodeGeocodeResponse, "GEOCODE", "Geocoding failed"),
        )
        ->Promise.catch(
          e => {
            let (msg, _) = Logger.getErrorDetails(e)
            Promise.resolve(Error("Decoding geocode response failed: " ++ msg))
          },
        )
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => handleError(e, "Geocoding failed", "GEOCODE_FAILED"))
  })
}
