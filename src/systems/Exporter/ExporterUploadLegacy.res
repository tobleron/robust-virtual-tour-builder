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

let formDataToBlob: FormData.t => Promise.t<Blob.t> = %raw(`
  async function(formData) {
    const response = new Response(formData);
    return await response.blob();
  }
`)
