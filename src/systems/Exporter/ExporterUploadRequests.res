open ReBindings

type apiResult<'a> = result<'a, string>

type exportInitResponse = {
  uploadId: string,
  chunkSizeBytes: int,
  totalChunks: int,
  expiresAtEpochMs: float,
}

type exportChunkResponse = {
  accepted: bool,
  nextExpectedChunk: int,
  receivedCount: int,
}

type exportStatusResponse = {
  receivedChunks: array<int>,
  nextExpectedChunk: int,
  totalChunks: int,
  expiresAtEpochMs: float,
}

type exportCompleteResponse = {
  staged: bool,
  stagedUploadId: string,
  assembledSizeBytes: int,
}

let defaultExportChunkSizeBytes = 50 * 1024 * 1024

let decodeExportInitResponse = {
  open JsonCombinators.Json.Decode
  object(field => {
    uploadId: field.required("uploadId", string),
    chunkSizeBytes: field.required("chunkSizeBytes", int),
    totalChunks: field.required("totalChunks", int),
    expiresAtEpochMs: field.required("expiresAtEpochMs", JsonCombinators.Json.Decode.float),
  })
}

let decodeExportChunkResponse = {
  open JsonCombinators.Json.Decode
  object(field => {
    accepted: field.required("accepted", bool),
    nextExpectedChunk: field.required("nextExpectedChunk", int),
    receivedCount: field.required("receivedCount", int),
  })
}

let decodeExportStatusResponse = {
  open JsonCombinators.Json.Decode
  object(field => {
    receivedChunks: field.required("receivedChunks", array(int)),
    nextExpectedChunk: field.required("nextExpectedChunk", int),
    totalChunks: field.required("totalChunks", int),
    expiresAtEpochMs: field.required("expiresAtEpochMs", JsonCombinators.Json.Decode.float),
  })
}

let decodeExportCompleteResponse = {
  open JsonCombinators.Json.Decode
  object(field => {
    staged: field.required("staged", bool),
    stagedUploadId: field.required("stagedUploadId", string),
    assembledSizeBytes: field.required("assembledSizeBytes", int),
  })
}

let blobSlice: (Blob.t, int, int) => Blob.t = %raw(`(blob, start, end) => blob.slice(start, end)`)

let sha256HexForBlob: Blob.t => Promise.t<string> = %raw(`
  async function(blob) {
    const ab = await blob.arrayBuffer();
    const digest = await crypto.subtle.digest("SHA-256", ab);
    const bytes = new Uint8Array(digest);
    return Array.from(bytes).map(b => b.toString(16).padStart(2, "0")).join("");
  }
`)

let isAborted = (signal: BrowserBindings.AbortSignal.t): bool =>
  BrowserBindings.AbortSignal.aborted(signal)

let requestExportInit = (
  payloadBlob: Blob.t,
  ~filename: string,
  ~chunkSizeBytes: int=defaultExportChunkSizeBytes,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~operationId: option<string>=?,
): Promise.t<apiResult<exportInitResponse>> => {
  let body = ExporterUploadRequestsRuntime.encodeInitBody(payloadBlob, ~filename, ~chunkSizeBytes)

  AuthenticatedClient.requestWithRetry(
    Constants.backendUrl ++ "/api/project/export/init",
    ~method="POST",
    ~body=AuthenticatedClient.castBody(body),
    ~signal?,
    ~operationId?,
    ~dedupeKey="export-init:" ++ filename,
    (),
  )->Promise.then(resultResponse => {
    switch resultResponse {
    | Retry.Success(response, _) =>
      response.json()->Promise.then(json =>
        ExporterUploadRequestsRuntime.decodeJson(
          json,
          ~decoder=decodeExportInitResponse,
          ~event="EXPORT_INIT",
          ~message="Export session initialization failed",
        )
      )
    | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
    }
  })
}

let requestExportStatus = (
  uploadId: string,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~operationId: option<string>=?,
): Promise.t<apiResult<exportStatusResponse>> => {
  AuthenticatedClient.requestWithRetry(
    Constants.backendUrl ++ "/api/project/export/status/" ++ uploadId,
    ~method="GET",
    ~signal?,
    ~operationId?,
    (),
  )->Promise.then(resultResponse => {
    switch resultResponse {
    | Retry.Success(response, _) =>
      response.json()->Promise.then(json =>
        ExporterUploadRequestsRuntime.decodeJson(
          json,
          ~decoder=decodeExportStatusResponse,
          ~event="EXPORT_STATUS",
          ~message="Export session status failed",
        )
      )
    | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
    }
  })
}

let requestExportChunk = async (
  payloadBlob: Blob.t,
  ~filename: string,
  ~uploadId: string,
  ~chunkIndex: int,
  ~chunkSizeBytes: int,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~operationId: option<string>=?,
): apiResult<exportChunkResponse> => {
  switch await ExporterUploadRequestsRuntime.buildChunkFormData(
    payloadBlob,
    ~filename,
    ~chunkIndex,
    ~chunkSizeBytes,
    ~blobSlice,
    ~sha256HexForBlob,
  ) {
  | Error(msg) => Error(msg)
  | Ok(formData) =>
    FormData.append(formData, "uploadId", uploadId)
    switch await AuthenticatedClient.requestWithRetry(
      Constants.backendUrl ++ "/api/project/export/chunk",
      ~method="POST",
      ~formData,
      ~signal?,
      ~operationId?,
      (),
    ) {
    | Retry.Success(response, _) =>
      let json = await response.json()
      await ExporterUploadRequestsRuntime.decodeJson(
        json,
        ~decoder=decodeExportChunkResponse,
        ~event="EXPORT_CHUNK",
        ~message="Export chunk upload failed",
      )
    | Retry.Exhausted(msg) => Error(msg)
    }
  }
}

let requestExportComplete = (
  payloadBlob: Blob.t,
  ~filename: string,
  ~uploadId: string,
  ~totalChunks: int,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~operationId: option<string>=?,
): Promise.t<apiResult<exportCompleteResponse>> => {
  let body =
    ExporterUploadRequestsRuntime.encodeCompleteBody(payloadBlob, ~filename, ~uploadId, ~totalChunks)

  AuthenticatedClient.requestWithRetry(
    Constants.backendUrl ++ "/api/project/export/complete",
    ~method="POST",
    ~body=AuthenticatedClient.castBody(body),
    ~signal?,
    ~operationId?,
    ~dedupeKey="export-complete:" ++ uploadId,
    (),
  )->Promise.then(resultResponse => {
    switch resultResponse {
    | Retry.Success(response, _) =>
      response.json()->Promise.then(json =>
        ExporterUploadRequestsRuntime.decodeJson(
          json,
          ~decoder=decodeExportCompleteResponse,
          ~event="EXPORT_COMPLETE",
          ~message="Export session completion failed",
        )
      )
    | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
    }
  })
}

let requestExportAbort = (
  uploadId: string,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~operationId: option<string>=?,
): Promise.t<unit> => {
  let body = ExporterUploadRequestsRuntime.encodeAbortBody(uploadId)
  AuthenticatedClient.requestWithRetry(
    Constants.backendUrl ++ "/api/project/export/abort",
    ~method="POST",
    ~body=AuthenticatedClient.castBody(body),
    ~signal?,
    ~operationId?,
    ~dedupeKey="export-abort:" ++ uploadId,
    (),
  )
  ->Promise.then(_ => Promise.resolve())
  ->Promise.catch(_ => Promise.resolve())
}
