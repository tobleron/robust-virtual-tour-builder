/* src/systems/ApiLogic.res - Extracted logic for Api.res */

open SharedTypes

/* Capture global Dom before shadowing */
module GlobalDom = Dom

open ReBindings

/* Alias ApiTypes to the new helper module */
module ApiTypes = ApiHelpers
open ApiTypes

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

  let prepareRequestBody = (body: option<JSON.t>, headers: Dict.t<string>) => {
    switch body {
    | Some(b) =>
      if Dict.get(headers, "Content-Type") == None {
        Dict.set(headers, "Content-Type", "application/json")
      }
      Some(JSON.stringify(b))
    | None => None
    }
  }

  let request = async (url, ~method="GET", ~body: option<JSON.t>=?, ~headers=Dict.make(), ()) => {
    let token = GlobalDom.Storage2.localStorage->GlobalDom.Storage2.getItem("auth_token")

    switch token {
    | Some(t) => Dict.set(headers, "Authorization", "Bearer " ++ t)
    | None => ()
    }

    let bodyVal = prepareRequestBody(body, headers)

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

  /* Helper functions to reduce nesting */
  let handleError = (e, message, logKey) => {
    let (msg, stack) = Logger.getErrorDetails(e)
    Logger.error(
      ~module_="MediaApi",
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
          ~module_="MediaApi",
          ~message=logKey ++ "_DECODE_FAILED",
          ~data=Logger.castToJson({"error": msg}),
          (),
       )
       Promise.resolve(Error(errorMessage ++ ": " ++ msg))
    }
  }

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
          ->Promise.then(json => handleJsonDecode(
            json,
            decodeMetadataResponse,
            "METADATA",
            "Metadata extraction failed"
          ))
          ->Promise.catch(e => handleError(e, "Metadata extraction failed: JSON parsing error", "METADATA_ERROR_JSON_DECODE"))
        | Error(msg) => Promise.resolve(Error(msg))
        }
      })
      ->Promise.catch(e => handleError(e, "Metadata extraction failed", "METADATA_ERROR"))
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
          ->Promise.catch(e => handleError(e, "Image processing failed: Blob conversion error", "PROCESSING_ERROR_BLOB_CONVERSION"))
        | Error(msg) => Promise.resolve(Error(msg))
        }
      })
      ->Promise.catch(e => handleError(e, "Image processing failed", "PROCESSING_ERROR"))
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
          ->Promise.then(json => {
            switch decodeSimilarityResponse(json) {
            | Ok(data) => Promise.resolve(Ok(data.results))
            | Error(msg) => Promise.resolve(Error(msg))
            }
          })
          ->Promise.catch(e => handleError(e, "Similarity calculation failed: JSON parsing error", "SIMILARITY_BATCH_ERROR_JSON_DECODE"))
        | Error(msg) => Promise.resolve(Error(msg))
        }
      })
      ->Promise.catch(e => handleError(e, "Similarity calculation failed", "SIMILARITY_BATCH_ERROR"))
    })
  }
}

module ProjectApi = {
  /* From ProjectApi.res */

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
          ->Promise.then(json => handleJsonDecode(
            json,
            decodeImportResponse,
            "IMPORT",
            "Project import failed"
          ))
          ->Promise.catch(e => handleError(e, "Project import failed: JSON parsing error", "IMPORT_ERROR_JSON_DECODE"))
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
          ->Promise.then(json => handleJsonDecode(
            json,
            decodeImportResponse,
            "LOAD",
            "Project load failed"
          ))
          ->Promise.catch(e => handleError(e, "Project load failed: JSON parsing error", "LOAD_ERROR_JSON_DECODE"))
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
          ->Promise.then(json => handleJsonDecode(
            json,
            decodeValidationReport,
            "VALIDATION",
            "Project validation failed"
          ))
          ->Promise.catch(e => {
             let (msg, _) = Logger.getErrorDetails(e)
             Promise.resolve(Error("Decoding validation report failed: " ++ msg))
          })
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
          ->Promise.then(json => handleJsonDecode(
            json,
            decodeSteps,
            "CALCULATE_PATH",
            "Path calculation failed"
          ))
          ->Promise.catch(e => handleError(e, "Path calculation failed: JSON parsing error", "CALCULATE_PATH_ERROR_JSON_DECODE"))
        | Error(msg) => Promise.resolve(Error(msg))
        }
      })
      ->Promise.catch(e => handleError(e, "Path calculation failed", "CALCULATE_PATH_ERROR"))
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
          ->Promise.then(json => handleJsonDecode(
            json,
            decodeGeocodeResponse,
            "GEOCODE",
            "Geocoding failed"
          ))
          ->Promise.catch(e => {
             let (msg, _) = Logger.getErrorDetails(e)
             Promise.resolve(Error("Decoding geocode response failed: " ++ msg))
          })
        | Error(msg) => Promise.resolve(Error(msg))
        }
      })
      ->Promise.catch(e => handleError(e, "Geocoding failed", "GEOCODE_FAILED"))
    })
  }
}
