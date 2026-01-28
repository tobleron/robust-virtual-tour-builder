/* src/systems/api/ProjectApi.res */

open ReBindings
open ApiTypes

/* --- API CALLS: Project Logic --- */

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
          json => {
            switch decodeImportResponse(json) {
            | Ok(data) => Promise.resolve(Ok(data))
            | Error(msg) => Promise.resolve(Error(msg))
            }
          },
        )
        ->Promise.catch(
          e => {
            let (msg, stack) = Logger.getErrorDetails(e)
            Logger.error(
              ~module_="ProjectApi",
              ~message="IMPORT_ERROR_JSON_DECODE",
              ~data=Logger.castToJson({"error": msg, "stack": stack}),
              (),
            )
            Promise.resolve(Error("Project import failed: JSON parsing or decoding error"))
          },
        )
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => {
      let (msg, stack) = Logger.getErrorDetails(e)
      Logger.error(
        ~module_="ProjectApi",
        ~message="IMPORT_ERROR",
        ~data=Logger.castToJson({"error": msg, "stack": stack}),
        (),
      )
      Promise.resolve(Error("Project import failed"))
    })
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
          json => {
            switch decodeImportResponse(json) {
            | Ok(data) => Promise.resolve(Ok(data))
            | Error(msg) => Promise.resolve(Error(msg))
            }
          },
        )
        ->Promise.catch(
          e => {
            let (msg, stack) = Logger.getErrorDetails(e)
            Logger.error(
              ~module_="ProjectApi",
              ~message="LOAD_ERROR_JSON_DECODE",
              ~data=Logger.castToJson({"error": msg, "stack": stack}),
              (),
            )
            Promise.resolve(Error("Project load failed: JSON parsing error"))
          },
        )
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => {
      let (msg, stack) = Logger.getErrorDetails(e)
      Logger.error(
        ~module_="ProjectApi",
        ~message="LOAD_ERROR",
        ~data=Logger.castToJson({"error": msg, "stack": stack}),
        (),
      )
      Promise.resolve(Error("Project load failed"))
    })
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
          json => {
            switch decodeValidationReport(json) {
            | Ok(report) => Promise.resolve(Ok(report))
            | Error(msg) => Promise.resolve(Error(msg))
            }
          },
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
    ->Promise.catch(e => {
      let (msg, stack) = Logger.getErrorDetails(e)
      Logger.error(
        ~module_="ProjectApi",
        ~message="VALIDATION_ERROR",
        ~data=Logger.castToJson({"error": msg, "stack": stack}),
        (),
      )
      Promise.resolve(Error("Project validation failed"))
    })
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
    ->Promise.catch(e => {
      let (msg, stack) = Logger.getErrorDetails(e)
      Logger.error(
        ~module_="ProjectApi",
        ~message="SAVE_ERROR",
        ~data=Logger.castToJson({"error": msg, "stack": stack}),
        (),
      )
      Promise.resolve(Error("Project save failed"))
    })
  })
}

let calculatePath = (payload: pathRequest): Promise.t<apiResult<array<step>>> => {
  RequestQueue.schedule(() => {
    Fetch.fetch(
      Constants.backendUrl ++ "/api/project/calculate-path",
      Fetch.requestInit(
        ~method="POST",
        ~body=JSON.stringify(Logger.castToJson(payload)),
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
          json => {
            switch decodeSteps(json) {
            | Ok(data) => Promise.resolve(Ok(data))
            | Error(msg) => Promise.resolve(Error(msg))
            }
          },
        )
        ->Promise.catch(
          e => {
            let (msg, stack) = Logger.getErrorDetails(e)
            Logger.error(
              ~module_="ProjectApi",
              ~message="CALCULATE_PATH_ERROR_JSON_DECODE",
              ~data=Logger.castToJson({"error": msg, "stack": stack}),
              (),
            )
            Promise.resolve(Error("Path calculation failed: JSON parsing or decoding error"))
          },
        )
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => {
      let (msg, stack) = Logger.getErrorDetails(e)
      Logger.error(
        ~module_="ProjectApi",
        ~message="CALCULATE_PATH_ERROR",
        ~data=Logger.castToJson({"error": msg, "stack": stack}),
        (),
      )
      Promise.resolve(Error("Path calculation failed"))
    })
  })
}

let reverseGeocode = (lat: float, lon: float): Promise.t<apiResult<geocodeResponse>> => {
  RequestQueue.schedule(() => {
    let payload = Dict.fromArray([("lat", JSON.Encode.float(lat)), ("lon", JSON.Encode.float(lon))])
    Fetch.fetch(
      Constants.backendUrl ++ "/api/geocoding/reverse",
      Fetch.requestInit(
        ~method="POST",
        ~body=JSON.stringify(JSON.Encode.object(payload)),
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
          json => {
            switch decodeGeocodeResponse(json) {
            | Ok(data) => Promise.resolve(Ok(data))
            | Error(msg) => {
                Logger.warn(
                  ~module_="ProjectApi",
                  ~message="GEOCODE_DECODE_FAILED",
                  ~data=Logger.castToJson({"error": msg}),
                  (),
                )
                Promise.resolve(Error(msg))
              }
            }
          },
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
    ->Promise.catch(e => {
      let (msg, stack) = Logger.getErrorDetails(e)
      Logger.error(
        ~module_="ProjectApi",
        ~message="GEOCODE_FAILED",
        ~data=Logger.castToJson({"error": msg, "stack": stack}),
        (),
      )
      Promise.resolve(Error("Geocoding failed: " ++ msg))
    })
  })
}
