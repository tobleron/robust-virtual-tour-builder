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

        if (token) {
          xhr.setRequestHeader("Authorization", "Bearer " + token);
        }

        if (signal) {
          signal.addEventListener('abort', () => {
            xhr.abort();
            reject(new Error("AbortError: Export cancelled by user"));
          });
          if (signal.aborted) {
            xhr.abort();
            reject(new Error("AbortError: Export cancelled by user"));
            return;
          }
        }

        xhr.upload.onprogress = (e) => {
            if (e.lengthComputable) {
                const percent = Math.round((e.loaded / e.total) * 50);
                if (onProgress) onProgress(percent, 100, "Uploading: " + Math.round((e.loaded / 1024 / 1024)) + "MB sent");
            }
        };

        xhr.onload = () => {
            if (xhr.status === 200) {
                if (onProgress) onProgress(100, 100, "Download Ready");
                resolve(xhr.response);
            } else {
                const rejectWithStatus = (payload) => {
                    const bodyText = String(payload ?? "");
                    reject(new Error("HttpError: Status " + xhr.status + " - " + bodyText));
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
                    reject(new Error("HttpError: Status " + xhr.status + " - Backend returned status"));
                }
            }
        };

        xhr.onerror = () => {
            reject(new Error("NetworkError: Export upload failed to " + backendUrl + "/api/project/create-tour-package. The backend may be unreachable."));
        };
        xhr.ontimeout = () => reject(new Error("TimeoutError: Export upload timed out after 5 minutes. Try with fewer scenes or a faster connection."));

        xhr.upload.onload = () => {
            if (onProgress) onProgress(50, 100, "Processing on Server (Please Wait)...");
        };

        xhr.responseType = "blob";
        xhr.send(formData);
    });
  }
`)
