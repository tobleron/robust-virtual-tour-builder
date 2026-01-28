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
            decodeImportResponse(json)->Promise.then(
              result => {
                switch result {
                | Ok(data) => Promise.resolve(Ok(data))
                | Error(msg) => Promise.resolve(Error(msg))
                }
              },
            )
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

/**
 * Validates a project ZIP and returns a validation report
 */
let validateProject = (file: File.t): Promise.t<apiResult<SharedTypes.validationReport>> => {
  RequestQueue.schedule(() => {
    let formData = FormData.newFormData()
    FormData.append(formData, "file", file)

    Fetch.fetch(
      Constants.backendUrl ++ "/api/project/validate",
      Fetch.requestInit(~method="POST", ~body=formData, ()),
    )
    ->Promise.then(handleResponse)
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Ok(response) =>
        Fetch.json(response)
        ->Promise.then(
          json => {
            switch decodeValidationReport(json) {
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
              ~message="VALIDATION_ERROR_JSON_DECODE",
              ~data=Logger.castToJson({"error": msg, "stack": stack}),
              (),
            )
            Promise.resolve(Error("Project validation failed: JSON parsing or decoding error"))
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

/**
 * Loads a project ZIP and returns it as a Blob
 * This ZIP contains project.json and all scene images
 */
let loadProject = (file: File.t): Promise.t<apiResult<Blob.t>> => {
  RequestQueue.schedule(() => {
    let formData = FormData.newFormData()
    FormData.append(formData, "file", file)

    Fetch.fetch(
      Constants.backendUrl ++ "/api/project/load",
      Fetch.requestInit(~method="POST", ~body=formData, ()),
    )
    ->Promise.then(handleResponse)
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Ok(response) =>
        Fetch.blob(response)
        ->Promise.then(blob => Promise.resolve(Ok(blob)))
        ->Promise.catch(
          e => {
            let (msg, stack) = Logger.getErrorDetails(e)
            Logger.error(
              ~module_="ProjectApi",
              ~message="LOAD_ERROR_BLOB_CONVERSION",
              ~data=Logger.castToJson({"error": msg, "stack": stack}),
              (),
            )
            Promise.resolve(Error("Project load failed: Blob conversion error"))
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

/**
 * Saves a project by sending the project JSON to the backend
 * The backend bundles it into a ZIP and returns it
 */
let saveProject = (projectData: JSON.t): Promise.t<apiResult<Blob.t>> => {
  RequestQueue.schedule(() => {
    let formData = FormData.newFormData()
    FormData.append(formData, "project_data", projectData)

    Fetch.fetch(
      Constants.backendUrl ++ "/api/project/save",
      Fetch.requestInit(~method="POST", ~body=formData, ()),
    )
    ->Promise.then(handleResponse)
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Ok(response) =>
        Fetch.blob(response)
        ->Promise.then(blob => Promise.resolve(Ok(blob)))
        ->Promise.catch(
          e => {
            let (msg, stack) = Logger.getErrorDetails(e)
            Logger.error(
              ~module_="ProjectApi",
              ~message="SAVE_ERROR_BLOB_CONVERSION",
              ~data=Logger.castToJson({"error": msg, "stack": stack}),
              (),
            )
            Promise.resolve(Error("Project save failed: Blob conversion error"))
          },
        )
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

/**
 * Calculates a navigation path (Teaser/Timeline) via Backend
 */
let calculatePath = (payload: pathRequest): Promise.t<apiResult<array<step>>> => {
  RequestQueue.schedule(() => {
    let headers = Dict.make()
    Dict.set(headers, "Content-Type", "application/json")

    Fetch.fetch(
      Constants.backendUrl ++ "/api/project/calculate-path",
      Fetch.requestInit(
        ~method="POST",
        ~body=JSON.stringify(Logger.castToJson(payload)),
        ~headers,
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

/**
 * Reverse geocodes coordinates to a human-readable address
 * Uses backend proxy for privacy and caching
 */
let reverseGeocode = (lat: float, lon: float): Promise.t<apiResult<string>> => {
  RequestQueue.schedule(() => {
    let headers = Dict.make()
    Dict.set(headers, "Content-Type", "application/json")

    Fetch.fetch(
      Constants.backendUrl ++ "/api/geocoding/reverse",
      Fetch.requestInit(
        ~method="POST",
        ~headers,
        ~body=JSON.stringify(
          Logger.castToJson({
            lat,
            lon,
          }),
        ),
        (),
      ),
    )
    ->Promise.then(response => {
      if !Fetch.ok(response) {
        Logger.warn(
          ~module_="ProjectApi",
          ~message="GEOCODE_SERVICE_UNAVAILABLE",
          ~data=Logger.castToJson({"status": Fetch.status(response)}),
          (),
        )
        Promise.resolve(Error("Geocoding service unavailable"))
      } else {
        Fetch.json(response)->Promise.then(
          json => {
            switch decodeGeocodeResponse(json) {
            | Ok(data) => Promise.resolve(Ok(data.address))
            | Error(msg) =>
              Logger.warn(
                ~module_="ProjectApi",
                ~message="GEOCODE_DECODE_FAILED",
                ~data=Logger.castToJson({"error": msg}),
                (),
              )
              Promise.resolve(Error("Geocoding decode failed: " ++ msg))
            }
          },
        )
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
