open ReBindings

let uploadAndProcessRaw: (FormData.t, (float, float, string) => unit, string, int, ~signal: BrowserBindings.AbortSignal.t, ~token: option<string>, ~operationId: option<string>) => Promise.t<Blob.t> = %raw(`
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
include ExporterUploadRequests
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
let sha256HexForBlob: Blob.t => Promise.t<string> = %raw(`async function(blob){const ab=await blob.arrayBuffer();const digest=await crypto.subtle.digest("SHA-256",ab);const bytes=new Uint8Array(digest);return Array.from(bytes).map(b=>b.toString(16).padStart(2,"0")).join("")}`)
let isAborted = (signal: BrowserBindings.AbortSignal.t): bool => BrowserBindings.AbortSignal.aborted(signal)
let requestExportInit = (payloadBlob: Blob.t, ~filename: string, ~chunkSizeBytes: int=defaultExportChunkSizeBytes, ~signal: option<BrowserBindings.AbortSignal.t>=?, ~operationId: option<string>=?): Promise.t<apiResult<exportInitResponse>> =>
  ExporterUploadRequests.requestExportInit(payloadBlob, ~filename, ~chunkSizeBytes, ~signal?, ~operationId?)
let requestExportStatus = (uploadId: string, ~signal: option<BrowserBindings.AbortSignal.t>=?, ~operationId: option<string>=?): Promise.t<apiResult<exportStatusResponse>> =>
  ExporterUploadRequests.requestExportStatus(uploadId, ~signal?, ~operationId?)
let requestExportChunk = (payloadBlob: Blob.t, ~filename: string, ~uploadId: string, ~chunkIndex: int, ~chunkSizeBytes: int, ~signal: option<BrowserBindings.AbortSignal.t>=?, ~operationId: option<string>=?): Promise.t<apiResult<exportChunkResponse>> =>
  ExporterUploadRequests.requestExportChunk(payloadBlob, ~filename, ~uploadId, ~chunkIndex, ~chunkSizeBytes, ~signal?, ~operationId?)
let requestExportComplete = (payloadBlob: Blob.t, ~filename: string, ~uploadId: string, ~totalChunks: int, ~signal: option<BrowserBindings.AbortSignal.t>=?, ~operationId: option<string>=?): Promise.t<apiResult<exportCompleteResponse>> =>
  ExporterUploadRequests.requestExportComplete(payloadBlob, ~filename, ~uploadId, ~totalChunks, ~signal?, ~operationId?)
let requestExportAbort = (uploadId: string, ~signal: option<BrowserBindings.AbortSignal.t>=?, ~operationId: option<string>=?): Promise.t<unit> =>
  ExporterUploadRequests.requestExportAbort(uploadId, ~signal?, ~operationId?)

let uploadChunkedWithResume = async (
  payloadBlob: Blob.t,
  ~filename: string,
  onProgress: (float, float, string) => unit,
  ~signal: BrowserBindings.AbortSignal.t,
  ~operationId: option<string>=?,
): apiResult<exportCompleteResponse> => {
  await ExporterUploadChunked.uploadChunkedWithResume(
    payloadBlob,
    ~filename,
    onProgress,
    ~signal,
    ~operationId?,
  )
}
let formDataToBlob: FormData.t => Promise.t<Blob.t> = %raw(`async function(formData){const response=new Response(formData);return await response.blob()}`)
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
  switch await uploadChunkedWithResume(payloadBlob, ~filename="tour_package.multipart", onProgress, ~signal, ~operationId?) {
  | Ok(_) =>
    await uploadAndProcessRaw(formData, onProgress, backendUrl, timeoutMs, ~signal, ~token, ~operationId)
  | Error(msg) =>
    Logger.warn(~module_="ExporterUpload", ~message="EXPORT_CHUNKED_FALLBACK_TO_LEGACY", ~data=Logger.castToJson({"error": msg}), ())
    await uploadAndProcessRaw(formData, onProgress, backendUrl, timeoutMs, ~signal, ~token, ~operationId)
  }
}
