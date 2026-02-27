open ReBindings

/* XHR Upload Logic via Raw JS (for progress events) with Abort Support */
let uploadAndProcessRaw: (
  FormData.t,
  (float, float, string) => unit,
  string,
  int,
  ~signal: BrowserBindings.AbortSignal.t,
  ~token: option<string>,
  ~operationId: option<string>,
) => Promise.t<Blob.t> = %raw(`
  function(formData, onProgress, backendUrl, timeoutMs, signal, token, operationId) {
    return new Promise((resolve, reject) => {
        const xhr = new XMLHttpRequest();
        xhr.open("POST", backendUrl + "/api/project/create-tour-package");
        xhr.timeout = timeoutMs;
        let serverPulseTimer = null;
        let settled = false;

        const emitProgress = (p, t, message) => {
          if (!onProgress) return;
          try {
            onProgress(p, t, message);
          } catch (_) {
            // Never allow UI callback failures to block export completion.
          }
        };

        const cleanup = () => {
          if (serverPulseTimer) { clearInterval(serverPulseTimer); serverPulseTimer = null; }
        };

        if (token) {
          xhr.setRequestHeader("Authorization", "Bearer " + token);
        }
        if (operationId) {
          xhr.setRequestHeader("X-Operation-ID", operationId);
          xhr.setRequestHeader("X-Correlation-ID", operationId);
        }

        if (signal) {
          signal.addEventListener('abort', () => {
            cleanup();
            xhr.abort();
            if (!settled) { settled = true; reject(new Error("AbortError: Export cancelled by user")); }
          });
          if (signal.aborted) {
            xhr.abort();
            reject(new Error("AbortError: Export cancelled by user"));
            return;
          }
        }

        xhr.upload.onprogress = (e) => {
            if (e.lengthComputable) {
                // Map upload progress to the 40-75% range
                const percent = 40 + Math.round((e.loaded / e.total) * 35);
                const sentMB = Math.round(e.loaded / 1024 / 1024);
                const totalMB = Math.round(e.total / 1024 / 1024);
                emitProgress(percent, 100, "Uploading: " + sentMB + " of " + totalMB + " MB");
            }
        };

        xhr.onload = () => {
            cleanup();
            if (xhr.status === 200) {
                if (!settled) { settled = true; resolve(xhr.response); }
                emitProgress(95, 100, "Preparing download...");
            } else {
                const rejectWithStatus = (payload) => {
                    const bodyText = String(payload ?? "");
                    if (!settled) { settled = true; reject(new Error("HttpError: Status " + xhr.status + " - " + bodyText)); }
                };
                try {
                    if (xhr.responseType === "blob") {
                        const reader = new FileReader();
                        reader.onload = () => {
                            rejectWithStatus(reader.result);
                        };
                        reader.readAsText(xhr.response);
                    } else {
                        rejectWithStatus(xhr.responseText);
                    }
                } catch (e) {
                    if (!settled) { settled = true; reject(new Error("HttpError: Status " + xhr.status + " - Backend returned status")); }
                }
            }
        };

        xhr.onloadend = () => {
            cleanup();
            // Fallback: ensure successful terminal response always resolves once.
            if (!settled && xhr.readyState === 4 && xhr.status === 200) {
                settled = true;
                resolve(xhr.response);
            }
        };

        xhr.onabort = () => {
            cleanup();
            if (!settled) { settled = true; reject(new Error("AbortError: Export cancelled by user")); }
        };

        xhr.onerror = () => {
            cleanup();
            if (!settled) { settled = true; reject(new Error("NetworkError: Export upload failed to " + backendUrl + "/api/project/create-tour-package. The backend may be unreachable.")); }
        };
        xhr.ontimeout = () => {
            cleanup();
            const mins = Math.max(1, Math.round((timeoutMs || 0) / 60000));
            if (!settled) { settled = true; reject(new Error("TimeoutError: Export upload timed out after " + mins + " minutes. Try again or reduce export size.")); }
        };

        xhr.upload.onload = () => {
            // Upload bytes sent — server is now processing. Start synthetic pulse 75→95%
            let serverPct = 75;
            emitProgress(75, 100, "Building your tour...");
            serverPulseTimer = setInterval(() => {
              if (serverPct < 94) {
                serverPct += 2;
                emitProgress(serverPct, 100, "Building your tour...");
              }
            }, 3000);
        };

        xhr.responseType = "blob";
        xhr.send(formData);
    });
  }
`)

type apiResult<'a> = result<'a, string>

type exportInitResponse = {
  uploadId: string,
  chunkSizeBytes: int,
  totalChunks: int,
  expiresAtEpochMs: int,
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
  expiresAtEpochMs: int,
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
    expiresAtEpochMs: field.required("expiresAtEpochMs", int),
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
    expiresAtEpochMs: field.required("expiresAtEpochMs", int),
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

let isAborted = (signal: BrowserBindings.AbortSignal.t): bool => BrowserBindings.AbortSignal.aborted(signal)

let requestExportInit = (
  payloadBlob: Blob.t,
  ~filename: string,
  ~chunkSizeBytes: int=defaultExportChunkSizeBytes,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~operationId: option<string>=?,
): Promise.t<apiResult<exportInitResponse>> => {
  let body = JsonCombinators.Json.Encode.object([
    ("filename", JsonCombinators.Json.Encode.string(filename)),
    ("sizeBytes", JsonCombinators.Json.Encode.int(Float.toInt(Blob.size(payloadBlob)))),
    ("chunkSizeBytes", JsonCombinators.Json.Encode.int(chunkSizeBytes)),
  ])

  AuthenticatedClient.requestWithRetry(
    Constants.backendUrl ++ "/api/project/export/init",
    ~method="POST",
    ~body=AuthenticatedClient.castBody(body),
    ~signal?,
    ~operationId?,
    (),
  )->Promise.then(resultResponse =>
    switch resultResponse {
    | Retry.Success(response, _) =>
      response.json()
      ->Promise.then(json =>
        ApiHelpers.handleJsonDecode(
          ~module_="ExporterUpload",
          json,
          json => JsonCombinators.Json.decode(json, decodeExportInitResponse),
          "EXPORT_INIT",
          "Export session initialization failed",
        )
      )
    | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
    }
  )
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
  )->Promise.then(resultResponse =>
    switch resultResponse {
    | Retry.Success(response, _) =>
      response.json()
      ->Promise.then(json =>
        ApiHelpers.handleJsonDecode(
          ~module_="ExporterUpload",
          json,
          json => JsonCombinators.Json.decode(json, decodeExportStatusResponse),
          "EXPORT_STATUS",
          "Export session status failed",
        )
      )
    | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
    }
  )
}

let requestExportChunk = (
  payloadBlob: Blob.t,
  ~filename: string,
  ~uploadId: string,
  ~chunkIndex: int,
  ~chunkSizeBytes: int,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~operationId: option<string>=?,
): Promise.t<apiResult<exportChunkResponse>> => {
  let totalSize = Float.toInt(Blob.size(payloadBlob))
  let start = chunkIndex * chunkSizeBytes
  let candidateEnd = start + chunkSizeBytes
  let end_ = if candidateEnd > totalSize { totalSize } else { candidateEnd }

  if start >= totalSize || end_ <= start {
    Promise.resolve(Error("Invalid chunk index " ++ Belt.Int.toString(chunkIndex)))
  } else {
    let chunkBlob = blobSlice(payloadBlob, start, end_)
    let chunkByteLength = end_ - start
    sha256HexForBlob(chunkBlob)->Promise.then(chunkSha256 => {
      let formData = FormData.newFormData()
      FormData.append(formData, "uploadId", uploadId)
      FormData.append(formData, "chunkIndex", Belt.Int.toString(chunkIndex))
      FormData.append(formData, "chunkByteLength", Belt.Int.toString(chunkByteLength))
      FormData.append(formData, "chunkSha256", chunkSha256)
      FormData.appendWithFilename(
        formData,
        "chunk",
        chunkBlob,
        filename ++ ".part-" ++ Belt.Int.toString(chunkIndex),
      )

      AuthenticatedClient.requestWithRetry(
        Constants.backendUrl ++ "/api/project/export/chunk",
        ~method="POST",
        ~formData,
        ~signal?,
        ~operationId?,
        (),
      )->Promise.then(resultResponse =>
        switch resultResponse {
        | Retry.Success(response, _) =>
          response.json()
          ->Promise.then(json =>
            ApiHelpers.handleJsonDecode(
              ~module_="ExporterUpload",
              json,
              json => JsonCombinators.Json.decode(json, decodeExportChunkResponse),
              "EXPORT_CHUNK",
              "Export chunk upload failed",
            )
          )
        | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
        }
      )
    })
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
  let body = JsonCombinators.Json.Encode.object([
    ("uploadId", JsonCombinators.Json.Encode.string(uploadId)),
    ("filename", JsonCombinators.Json.Encode.string(filename)),
    ("sizeBytes", JsonCombinators.Json.Encode.int(Float.toInt(Blob.size(payloadBlob)))),
    ("totalChunks", JsonCombinators.Json.Encode.int(totalChunks)),
  ])

  AuthenticatedClient.requestWithRetry(
    Constants.backendUrl ++ "/api/project/export/complete",
    ~method="POST",
    ~body=AuthenticatedClient.castBody(body),
    ~signal?,
    ~operationId?,
    (),
  )->Promise.then(resultResponse =>
    switch resultResponse {
    | Retry.Success(response, _) =>
      response.json()
      ->Promise.then(json =>
        ApiHelpers.handleJsonDecode(
          ~module_="ExporterUpload",
          json,
          json => JsonCombinators.Json.decode(json, decodeExportCompleteResponse),
          "EXPORT_COMPLETE",
          "Export session completion failed",
        )
      )
    | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
    }
  )
}

let requestExportAbort = (
  uploadId: string,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~operationId: option<string>=?,
): Promise.t<unit> => {
  let body = JsonCombinators.Json.Encode.object([
    ("uploadId", JsonCombinators.Json.Encode.string(uploadId)),
  ])
  AuthenticatedClient.requestWithRetry(
    Constants.backendUrl ++ "/api/project/export/abort",
    ~method="POST",
    ~body=AuthenticatedClient.castBody(body),
    ~signal?,
    ~operationId?,
    (),
  )
  ->Promise.then(_ => Promise.resolve())
  ->Promise.catch(_ => Promise.resolve())
}

let uploadChunkedWithResume = async (
  payloadBlob: Blob.t,
  ~filename: string,
  onProgress: (float, float, string) => unit,
  ~signal: BrowserBindings.AbortSignal.t,
  ~operationId: option<string>=?,
): apiResult<exportCompleteResponse> => {
  if isAborted(signal) {
    Error("AbortError: Export cancelled by user")
  } else {
    switch await requestExportInit(payloadBlob, ~filename, ~signal, ~operationId?) {
    | Error(msg) => Error(msg)
    | Ok(init) =>
      switch await requestExportStatus(init.uploadId, ~signal, ~operationId?) {
      | Error(msg) =>
        ignore(await requestExportAbort(init.uploadId, ~signal, ~operationId?))
        Error(msg)
      | Ok(status) =>
        let totalChunks = if init.totalChunks > 0 {
          init.totalChunks
        } else {
          status.totalChunks
        }
        let uploadedCount = ref(Belt.Array.length(status.receivedChunks))

        let rec uploadLoop = async chunkIndex => {
          if chunkIndex >= totalChunks {
            Ok()
          } else if isAborted(signal) {
            ignore(await requestExportAbort(init.uploadId, ~signal, ~operationId?))
            Error("AbortError: Export cancelled by user")
          } else if Belt.Array.some(status.receivedChunks, idx => idx == chunkIndex) {
            await uploadLoop(chunkIndex + 1)
          } else {
            switch await requestExportChunk(
              payloadBlob,
              ~filename,
              ~uploadId=init.uploadId,
              ~chunkIndex,
              ~chunkSizeBytes=init.chunkSizeBytes,
              ~signal,
              ~operationId?,
            ) {
            | Error(msg) => Error(msg)
            | Ok(_) =>
              uploadedCount := uploadedCount.contents + 1
              let pct = 40.0 +. 35.0 *. Int.toFloat(uploadedCount.contents) /. Int.toFloat(totalChunks)
              onProgress(
                pct,
                100.0,
                "Uploading chunks: " ++
                Belt.Int.toString(uploadedCount.contents) ++
                "/" ++
                Belt.Int.toString(totalChunks),
              )
              await uploadLoop(chunkIndex + 1)
            }
          }
        }

        switch await uploadLoop(0) {
        | Error(msg) =>
          ignore(await requestExportAbort(init.uploadId, ~signal, ~operationId?))
          Error(msg)
        | Ok() =>
          if isAborted(signal) {
            ignore(await requestExportAbort(init.uploadId, ~signal, ~operationId?))
            Error("AbortError: Export cancelled by user")
          } else {
            await requestExportComplete(
              payloadBlob,
              ~filename,
              ~uploadId=init.uploadId,
              ~totalChunks,
              ~signal,
              ~operationId?,
            )
          }
        }
      }
    }
  }
}

let formDataToBlob: FormData.t => Promise.t<Blob.t> = %raw(`
  async function(formData) {
    const response = new Response(formData);
    return await response.blob();
  }
`)

let uploadChunkedThenLegacy = async (
  formData: FormData.t,
  onProgress: (float, float, string) => unit,
  backendUrl: string,
  timeoutMs: int,
  ~signal: BrowserBindings.AbortSignal.t,
  ~token: option<string>,
  ~operationId: option<string>,
): Blob.t => {
  let payloadBlob = await formDataToBlob(formData)
  let chunkFilename = "tour_package.multipart"
  switch await uploadChunkedWithResume(
    payloadBlob,
    ~filename=chunkFilename,
    onProgress,
    ~signal,
    ~operationId?,
  ) {
  | Ok(_) =>
    // Phase C compatibility path: keep legacy package generation output unchanged.
    await uploadAndProcessRaw(
      formData,
      onProgress,
      backendUrl,
      timeoutMs,
      ~signal,
      ~token,
      ~operationId,
    )
  | Error(msg) =>
    Logger.warn(
      ~module_="ExporterUpload",
      ~message="EXPORT_CHUNKED_FALLBACK_TO_LEGACY",
      ~data=Logger.castToJson({"error": msg}),
      (),
    )
    await uploadAndProcessRaw(
      formData,
      onProgress,
      backendUrl,
      timeoutMs,
      ~signal,
      ~token,
      ~operationId,
    )
  }
}
