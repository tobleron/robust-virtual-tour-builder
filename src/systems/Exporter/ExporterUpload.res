open ReBindings

/* XHR Upload Logic via Raw JS (for progress events) with Abort Support */
let uploadAndProcessRaw: (
  FormData.t,
  (float, float, string) => unit,
  string,
  ~signal: BrowserBindings.AbortSignal.t,
  ~token: option<string>,
) => Promise.t<Blob.t> = %raw(`
  function(formData, onProgress, backendUrl, signal, token) {
    return new Promise((resolve, reject) => {
        const xhr = new XMLHttpRequest();
        xhr.open("POST", backendUrl + "/api/project/create-tour-package");
        xhr.timeout = 300000; // 5 minutes
        let serverPulseTimer = null;
        let settled = false;

        const cleanup = () => {
          if (serverPulseTimer) { clearInterval(serverPulseTimer); serverPulseTimer = null; }
        };

        if (token) {
          xhr.setRequestHeader("Authorization", "Bearer " + token);
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
                if (onProgress) onProgress(percent, 100, "Uploading: " + sentMB + " of " + totalMB + " MB");
            }
        };

        xhr.onload = () => {
            cleanup();
            if (xhr.status === 200) {
                if (onProgress) onProgress(95, 100, "Preparing download...");
                if (!settled) { settled = true; resolve(xhr.response); }
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

        xhr.onerror = () => {
            cleanup();
            if (!settled) { settled = true; reject(new Error("NetworkError: Export upload failed to " + backendUrl + "/api/project/create-tour-package. The backend may be unreachable.")); }
        };
        xhr.ontimeout = () => {
            cleanup();
            if (!settled) { settled = true; reject(new Error("TimeoutError: Export upload timed out after 5 minutes. Try with fewer scenes or a faster connection.")); }
        };

        xhr.upload.onload = () => {
            // Upload bytes sent — server is now processing. Start synthetic pulse 75→95%
            let serverPct = 75;
            if (onProgress) onProgress(75, 100, "Building your tour...");
            serverPulseTimer = setInterval(() => {
              if (serverPct < 94) {
                serverPct += 2;
                if (onProgress) onProgress(serverPct, 100, "Building your tour...");
              }
            }, 3000);
        };

        xhr.responseType = "blob";
        xhr.send(formData);
    });
  }
`)
