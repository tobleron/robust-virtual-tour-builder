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
    FormData.append(formData, "zip", file)

    let headers = Dict.make()
    let token = Dom.Storage2.localStorage->Dom.Storage2.getItem("auth_token")

    switch token {
    | Some(t) => Dict.set(headers, "Authorization", "Bearer " ++ t)
    | None => ()
    }

    Fetch.fetch(
      Constants.backendUrl ++ "/api/project/import",
      Fetch.requestInit(~method="POST", ~body=formData, ~headers, ()),
    )
    ->Promise.then(response => {
      if Fetch.ok(response) {
        Promise.resolve(Ok(response))
      } else {
        Fetch.text(response)->Promise.then(
          text => {
            let errorMsg = if text == "" {
              `Request failed with status ${Int.toString(Fetch.status(response))}`
            } else {
              text
            }
            Promise.resolve(Error(errorMsg))
          },
        )
      }
    })
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
      Constants.backendUrl ++ "/api/project/load/" ++ sessionId,
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
    // projectData is already a JSON value (from PersistenceLayer or similar)
    // We use Json.stringify to convert it to a string for the body
    let body = JsonCombinators.Json.stringify(projectData)

    Fetch.fetch(
      Constants.backendUrl ++ "/api/project/validate/" ++ sessionId,
      Fetch.requestInit(
        ~method="POST",
        ~body=body,
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
    let body = JsonCombinators.Json.stringify(projectData)

    Fetch.fetch(
      Constants.backendUrl ++ "/api/project/save/" ++ sessionId,
      Fetch.requestInit(
        ~method="POST",
        ~body=body,
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
    let body = JsonCombinators.Json.stringify(JsonParsers.Encoders.pathRequest(payload))

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
    let payload = JsonCombinators.Json.Encode.object([
      ("lat", JsonCombinators.Json.Encode.float(lat)),
      ("lon", JsonCombinators.Json.Encode.float(lon))
    ])

    let body = JsonCombinators.Json.stringify(payload)

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
