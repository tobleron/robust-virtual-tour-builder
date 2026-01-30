/* src/systems/ApiLogic.res - Extracted logic for Api.res */

open SharedTypes
open RescriptSchema

/* Capture global Dom before shadowing */
module GlobalDom = Dom

open ReBindings

module ApiTypes = {
  /* From ApiTypes.res */
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

  let handleResponse = (response: Fetch.response): Promise.t<apiResult<Fetch.response>> => {
    if Fetch.ok(response) {
      Promise.resolve(Ok(response))
    } else {
      processErrorResponse(response)
    }
  }
}

module AuthenticatedClient = {
  /* From AuthenticatedClient.res */
  exception HttpError(int, string)

  let dispatchLogout = () => {
    let _ = %raw("window.dispatchEvent(new Event('auth:logout'))")
  }

  type response = {
    ok: bool,
    status: int,
    statusText: string,
    json: unit => Promise.t<JSON.t>,
    text: unit => Promise.t<string>,
  }

  @val external fetch: (string, 'options) => Promise.t<response> = "fetch"

  let request = async (url, ~method="GET", ~body: option<JSON.t>=?, ~headers=Dict.make(), ()) => {
    let token = GlobalDom.Storage2.localStorage->GlobalDom.Storage2.getItem("auth_token")

    switch token {
    | Some(t) => Dict.set(headers, "Authorization", "Bearer " ++ t)
    | None => ()
    }

    switch body {
    | Some(_) =>
      if Dict.get(headers, "Content-Type") == None {
        Dict.set(headers, "Content-Type", "application/json")
      }
    | None => ()
    }

    let bodyVal = switch body {
    | Some(b) => Some(JSON.stringify(b))
    | None => None
    }

    let options = {
      "method": method,
      "headers": headers,
      "body": bodyVal,
    }

    let response = await fetch(url, options)

    if response.status == 401 {
      dispatchLogout()
      throw(HttpError(401, "Unauthorized"))
    }

    if response.status >= 400 {
      throw(HttpError(response.status, response.statusText))
    }

    response
  }
}

module MediaApi = {
  /* From MediaApi.res */
  open ApiTypes

  let extractMetadata = (file: File.t): Promise.t<apiResult<metadataResponse>> => {
    RequestQueue.schedule(() => {
      let formData = FormData.newFormData()
      FormData.append(formData, "file", file)

      Fetch.fetch(
        Constants.backendUrl ++ "/api/media/extract-metadata",
        Fetch.requestInit(~method="POST", ~body=formData, ()),
      )
      ->Promise.then(handleResponse)
      ->Promise.then(resultResponse => {
        switch resultResponse {
        | Ok(response) =>
          Fetch.json(response)
          ->Promise.then(
            json => {
              switch decodeMetadataResponse(json) {
              | Ok(data) => Promise.resolve(Ok(data))
              | Error(msg) => Promise.resolve(Error(msg))
              }
            },
          )
          ->Promise.catch(
            e => {
              let (msg, stack) = Logger.getErrorDetails(e)
              Logger.error(
                ~module_="MediaApi",
                ~message="METADATA_ERROR_JSON_DECODE",
                ~data=Logger.castToJson({"error": msg, "stack": stack}),
                (),
              )
              Promise.resolve(Error("Metadata extraction failed: JSON parsing or decoding error"))
            },
          )
        | Error(msg) => Promise.resolve(Error(msg))
        }
      })
      ->Promise.catch(e => {
        let (msg, stack) = Logger.getErrorDetails(e)
        Logger.error(
          ~module_="MediaApi",
          ~message="METADATA_ERROR",
          ~data=Logger.castToJson({"error": msg, "stack": stack}),
          (),
        )
        Promise.resolve(Error("Metadata extraction failed"))
      })
    })
  }

  let processImageFull = (
    file: File.t,
    ~isOptimized: bool=false,
    ~metadata: option<exifMetadata>=?,
  ): Promise.t<apiResult<Blob.t>> => {
    RequestQueue.schedule(() => {
      let formData = FormData.newFormData()
      FormData.append(formData, "file", file)
      if isOptimized {
        FormData.append(formData, "is_optimized", "true")
      }
      switch metadata {
      | Some(m) => FormData.append(formData, "metadata", JSON.stringify(Logger.castToJson(m)))
      | None => ()
      }

      Fetch.fetch(
        Constants.backendUrl ++ "/api/media/process-full",
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
                ~module_="MediaApi",
                ~message="PROCESSING_ERROR_BLOB_CONVERSION",
                ~data=Logger.castToJson({"error": msg, "stack": stack}),
                (),
              )
              Promise.resolve(Error("Image processing failed: Blob conversion error"))
            },
          )
        | Error(msg) => Promise.resolve(Error(msg))
        }
      })
      ->Promise.catch(e => {
        let (msg, stack) = Logger.getErrorDetails(e)
        Logger.error(
          ~module_="MediaApi",
          ~message="PROCESSING_ERROR",
          ~data=Logger.castToJson({"error": msg, "stack": stack}),
          (),
        )
        Promise.resolve(Error("Image processing failed"))
      })
    })
  }

  let batchCalculateSimilarity = (pairs: array<similarityPair>): Promise.t<
    apiResult<array<similarityResult>>,
  > => {
    RequestQueue.schedule(() => {
      let headers = Dict.make()
      Dict.set(headers, "Content-Type", "application/json")

      Fetch.fetch(
        Constants.backendUrl ++ "/api/media/similarity",
        Fetch.requestInit(
          ~method="POST",
          ~headers,
          ~body=JSON.stringify(
            Logger.castToJson({
              "pairs": pairs,
            }),
          ),
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
              switch decodeSimilarityResponse(json) {
              | Ok(data) => Promise.resolve(Ok(data.results))
              | Error(msg) => Promise.resolve(Error(msg))
              }
            },
          )
          ->Promise.catch(
            e => {
              let (msg, stack) = Logger.getErrorDetails(e)
              Logger.error(
                ~module_="MediaApi",
                ~message="SIMILARITY_BATCH_ERROR_JSON_DECODE",
                ~data=Logger.castToJson({"error": msg, "stack": stack}),
                (),
              )
              Promise.resolve(
                Error("Similarity calculation failed: JSON parsing or decoding error"),
              )
            },
          )
        | Error(msg) => Promise.resolve(Error(msg))
        }
      })
      ->Promise.catch(e => {
        let (msg, stack) = Logger.getErrorDetails(e)
        Logger.error(
          ~module_="MediaApi",
          ~message="SIMILARITY_BATCH_ERROR",
          ~data=Logger.castToJson({"error": msg, "stack": stack}),
          (),
        )
        Promise.resolve(Error("Similarity calculation failed"))
      })
    })
  }
}

module ProjectApi = {
  /* From ProjectApi.res */
  open ApiTypes

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
      let payload = Dict.fromArray([
        ("lat", JSON.Encode.float(lat)),
        ("lon", JSON.Encode.float(lon)),
      ])
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
}
