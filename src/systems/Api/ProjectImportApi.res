/* src/systems/Api/ProjectImportApi.res */
open ApiHelpers
open ReBindings
include ProjectImportTypes

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
        ApiHelpers.handleJsonDecode(
          ~module_="ProjectImportApi",
          json,
          decodeImportInitResponse,
          "IMPORT_INIT",
          "Project import initialization failed",
        )
      )
      ->Promise.catch(e =>
        ApiHelpers.handleError(
          ~module_="ProjectImportApi",
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
        ApiHelpers.handleJsonDecode(
          ~module_="ProjectImportApi",
          json,
          decodeImportStatusResponse,
          "IMPORT_STATUS",
          "Project import status failed",
        )
      )
      ->Promise.catch(e =>
        ApiHelpers.handleError(
          ~module_="ProjectImportApi",
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
          ApiHelpers.handleJsonDecode(
            ~module_="ProjectImportApi",
            json,
            decodeImportChunkResponse,
            "IMPORT_CHUNK",
            "Project import chunk failed",
          )
        )
        ->Promise.catch(e =>
          ApiHelpers.handleError(
            ~module_="ProjectImportApi",
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
        ApiHelpers.handleJsonDecode(
          ~module_="ProjectImportApi",
          json,
          decodeImportResponse,
          "IMPORT_COMPLETE",
          "Project import completion failed",
        )
      )
      ->Promise.catch(e =>
        ApiHelpers.handleError(
          ~module_="ProjectImportApi",
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
  Logger.error(
    ~module_="ProjectImportApi",
    ~message="REQUEST_IMPORT_ABORT_START",
    ~data=Logger.castToJson({"uploadId": uploadId}),
    (),
  )
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
  ->Promise.then(result => {
    switch result {
    | Retry.Success(_, _) =>
      Logger.warn(
        ~module_="ProjectImportApi",
        ~message="REQUEST_IMPORT_ABORT_SUCCESS",
        ~data=Logger.castToJson({"uploadId": uploadId}),
        (),
      )
    | Retry.Exhausted(err) =>
      Logger.error(
        ~module_="ProjectImportApi",
        ~message="REQUEST_IMPORT_ABORT_EXHAUSTED",
        ~data=Logger.castToJson({"uploadId": uploadId, "error": err}),
        (),
      )
    }
    Promise.resolve()
  })
  ->Promise.catch(e => {
    let (msg, _) = Logger.getErrorDetails(e)
    Logger.error(
      ~module_="ProjectImportApi",
      ~message="REQUEST_IMPORT_ABORT_FAILED",
      ~data=Logger.castToJson({"uploadId": uploadId, "error": msg}),
      (),
    )
    Promise.resolve()
  })
}
