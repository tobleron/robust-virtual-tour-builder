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

type importInitResponse = {
  uploadId: string,
  chunkSizeBytes: int,
  totalChunks: int,
  expiresAtEpochMs: float,
}

type importChunkResponse = {
  accepted: bool,
  nextExpectedChunk: int,
  receivedCount: int,
}

type importStatusResponse = {
  receivedChunks: array<int>,
  nextExpectedChunk: int,
  totalChunks: int,
  expiresAtEpochMs: float,
}

let decodeImportInitResponse = json =>
  JsonCombinators.Json.decode(
    json,
    JsonCombinators.Json.Decode.object(field => {
      {
        uploadId: field.required("uploadId", JsonCombinators.Json.Decode.string),
        chunkSizeBytes: field.required("chunkSizeBytes", JsonCombinators.Json.Decode.int),
        totalChunks: field.required("totalChunks", JsonCombinators.Json.Decode.int),
        expiresAtEpochMs: field.required("expiresAtEpochMs", JsonCombinators.Json.Decode.float),
      }
    }),
  )

let decodeImportChunkResponse = json =>
  JsonCombinators.Json.decode(
    json,
    JsonCombinators.Json.Decode.object(field => {
      {
        accepted: field.required("accepted", JsonCombinators.Json.Decode.bool),
        nextExpectedChunk: field.required("nextExpectedChunk", JsonCombinators.Json.Decode.int),
        receivedCount: field.required("receivedCount", JsonCombinators.Json.Decode.int),
      }
    }),
  )

let decodeImportStatusResponse = json =>
  JsonCombinators.Json.decode(
    json,
    JsonCombinators.Json.Decode.object(field => {
      {
        receivedChunks: field.required(
          "receivedChunks",
          JsonCombinators.Json.Decode.array(JsonCombinators.Json.Decode.int),
        ),
        nextExpectedChunk: field.required("nextExpectedChunk", JsonCombinators.Json.Decode.int),
        totalChunks: field.required("totalChunks", JsonCombinators.Json.Decode.int),
        expiresAtEpochMs: field.required("expiresAtEpochMs", JsonCombinators.Json.Decode.float),
      }
    }),
  )

let requestImportInit = (
  file: File.t,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~operationId: option<string>=?,
): Promise.t<apiResult<importInitResponse>> => {
  let body = JsonCombinators.Json.Encode.object([
    ("filename", JsonCombinators.Json.Encode.string(File.name(file))),
    ("sizeBytes", JsonCombinators.Json.Encode.int(Float.toInt(File.size(file)))),
    ("chunkSizeBytes", JsonCombinators.Json.Encode.int(FileSlicer.defaultChunkSizeBytes)),
  ])

  AuthenticatedClient.requestWithRetry(
    Constants.backendUrl ++ "/api/project/import/init",
    ~method="POST",
    ~body=AuthenticatedClient.castBody(body),
    ~signal?,
    ~operationId?,
    (),
  )->Promise.then(resultResponse => {
    switch resultResponse {
    | Retry.Success(response, _) =>
      response.json()
      ->Promise.then(json =>
        handleJsonDecode(
          json,
          decodeImportInitResponse,
          "IMPORT_INIT",
          "Project import initialization failed",
        )
      )
      ->Promise.catch(e =>
        handleError(
          e,
          "Project import initialization failed: JSON parsing error",
          "IMPORT_INIT_ERROR_JSON_DECODE",
        )
      )
    | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
    }
  })
}

let requestImportStatus = (
  uploadId: string,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~operationId: option<string>=?,
): Promise.t<apiResult<importStatusResponse>> => {
  AuthenticatedClient.requestWithRetry(
    Constants.backendUrl ++ "/api/project/import/status/" ++ uploadId,
    ~method="GET",
    ~signal?,
    ~operationId?,
    (),
  )->Promise.then(resultResponse => {
    switch resultResponse {
    | Retry.Success(response, _) =>
      response.json()
      ->Promise.then(json =>
        handleJsonDecode(
          json,
          decodeImportStatusResponse,
          "IMPORT_STATUS",
          "Project import status failed",
        )
      )
      ->Promise.catch(e =>
        handleError(
          e,
          "Project import status failed: JSON parsing error",
          "IMPORT_STATUS_ERROR_JSON_DECODE",
        )
      )
    | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
    }
  })
}

let requestImportChunk = (
  file: File.t,
  ~uploadId: string,
  ~chunkIndex: int,
  ~chunkSizeBytes: int,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~operationId: option<string>=?,
): Promise.t<apiResult<importChunkResponse>> => {
  let sizeBytes = Float.toInt(File.size(file))

  switch (
    FileSlicer.sliceChunk(file, ~chunkSizeBytes, ~chunkIndex),
    FileSlicer.chunkByteLengthForIndex(~sizeBytes, ~chunkSizeBytes, ~chunkIndex),
  ) {
  | (Some(chunkBlob), Some(chunkByteLength)) =>
    let formData = FormData.newFormData()
    FormData.append(formData, "uploadId", uploadId)
    FormData.append(formData, "chunkIndex", Belt.Int.toString(chunkIndex))
    FormData.append(formData, "chunkByteLength", Belt.Int.toString(chunkByteLength))
    FormData.appendWithFilename(
      formData,
      "chunk",
      chunkBlob,
      File.name(file) ++ ".part-" ++ Belt.Int.toString(chunkIndex),
    )

    AuthenticatedClient.requestWithRetry(
      Constants.backendUrl ++ "/api/project/import/chunk",
      ~method="POST",
      ~formData,
      ~signal?,
      ~operationId?,
      (),
    )->Promise.then(resultResponse => {
      switch resultResponse {
      | Retry.Success(response, _) =>
        response.json()
        ->Promise.then(json =>
          handleJsonDecode(
            json,
            decodeImportChunkResponse,
            "IMPORT_CHUNK",
            "Project import chunk failed",
          )
        )
        ->Promise.catch(e =>
          handleError(
            e,
            "Project import chunk failed: JSON parsing error",
            "IMPORT_CHUNK_ERROR_JSON_DECODE",
          )
        )
      | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
      }
    })
  | _ =>
    Promise.resolve(
      Error("Failed to prepare chunk " ++ Belt.Int.toString(chunkIndex) ++ " for project import"),
    )
  }
}

let requestImportComplete = (
  file: File.t,
  ~uploadId: string,
  ~totalChunks: int,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~operationId: option<string>=?,
): Promise.t<apiResult<importResponse>> => {
  let body = JsonCombinators.Json.Encode.object([
    ("uploadId", JsonCombinators.Json.Encode.string(uploadId)),
    ("filename", JsonCombinators.Json.Encode.string(File.name(file))),
    ("sizeBytes", JsonCombinators.Json.Encode.int(Float.toInt(File.size(file)))),
    ("totalChunks", JsonCombinators.Json.Encode.int(totalChunks)),
  ])

  AuthenticatedClient.requestWithRetry(
    Constants.backendUrl ++ "/api/project/import/complete",
    ~method="POST",
    ~body=AuthenticatedClient.castBody(body),
    ~signal?,
    ~operationId?,
    (),
  )->Promise.then(resultResponse => {
    switch resultResponse {
    | Retry.Success(response, _) =>
      response.json()
      ->Promise.then(json =>
        handleJsonDecode(
          json,
          decodeImportResponse,
          "IMPORT_COMPLETE",
          "Project import completion failed",
        )
      )
      ->Promise.catch(e =>
        handleError(
          e,
          "Project import completion failed: JSON parsing error",
          "IMPORT_COMPLETE_ERROR_JSON_DECODE",
        )
      )
    | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
    }
  })
}

let requestImportAbort = (
  uploadId: string,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~operationId: option<string>=?,
) => {
  let body = JsonCombinators.Json.Encode.object([
    ("uploadId", JsonCombinators.Json.Encode.string(uploadId)),
  ])

  AuthenticatedClient.requestWithRetry(
    Constants.backendUrl ++ "/api/project/import/abort",
    ~method="POST",
    ~body=AuthenticatedClient.castBody(body),
    ~signal?,
    ~operationId?,
    (),
  )
  ->Promise.then(_ => Promise.resolve())
  ->Promise.catch(_ => Promise.resolve())
}

let rec uploadMissingChunks = async (
  file: File.t,
  ~uploadId: string,
  ~chunkSizeBytes: int,
  ~totalChunks: int,
  ~receivedChunks: array<int>,
  ~currentIndex: int,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~operationId: option<string>=?,
): apiResult<unit> => {
  if currentIndex >= totalChunks {
    Ok()
  } else if receivedChunks->Belt.Array.some(idx => idx == currentIndex) {
    await uploadMissingChunks(
      file,
      ~uploadId,
      ~chunkSizeBytes,
      ~totalChunks,
      ~receivedChunks,
      ~currentIndex=currentIndex + 1,
      ~signal?,
      ~operationId?,
    )
  } else {
    let chunkResult = await requestImportChunk(
      file,
      ~uploadId,
      ~chunkIndex=currentIndex,
      ~chunkSizeBytes,
      ~signal?,
      ~operationId?,
    )
    switch chunkResult {
    | Ok(_) =>
      await uploadMissingChunks(
        file,
        ~uploadId,
        ~chunkSizeBytes,
        ~totalChunks,
        ~receivedChunks,
        ~currentIndex=currentIndex + 1,
        ~signal?,
        ~operationId?,
      )
    | Error(msg) => Error(msg)
    }
  }
}

let importProject = (
  file: File.t,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~operationId: option<string>=?,
): Promise.t<apiResult<importResponse>> => {
  RequestQueue.schedule(() => {
    let chunkedFlow = async () => {
      let initResult = await requestImportInit(file, ~signal?, ~operationId?)
      switch initResult {
      | Error(msg) => Error(msg)
      | Ok(initData) =>
        let statusResult = await requestImportStatus(initData.uploadId, ~signal?, ~operationId?)
        let receivedChunks = switch statusResult {
        | Ok(status) => status.receivedChunks
        | Error(msg) =>
          Logger.warn(
            ~module_="ProjectApi",
            ~message="CHUNK_IMPORT_STATUS_FALLBACK_EMPTY",
            ~data=Logger.castToJson({"reason": msg, "uploadId": initData.uploadId}),
            (),
          )
          []
        }

        let uploadResult = await uploadMissingChunks(
          file,
          ~uploadId=initData.uploadId,
          ~chunkSizeBytes=initData.chunkSizeBytes,
          ~totalChunks=initData.totalChunks,
          ~receivedChunks,
          ~currentIndex=0,
          ~signal?,
          ~operationId?,
        )

        switch uploadResult {
        | Error(msg) =>
          let _ = requestImportAbort(initData.uploadId, ~signal?, ~operationId?)
          Error(msg)
        | Ok(_) =>
          await requestImportComplete(
            file,
            ~uploadId=initData.uploadId,
            ~totalChunks=initData.totalChunks,
            ~signal?,
            ~operationId?,
          )
        }
      }
    }

    chunkedFlow()->Promise.catch(e => handleError(e, "Project import failed", "IMPORT_ERROR"))
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
