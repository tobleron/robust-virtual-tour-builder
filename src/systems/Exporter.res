/* src/systems/Exporter.res */

open ReBindings
open Types

type apiError = {
  error: string,
  details: option<string>,
}

let apiErrorDecoder = JsonCombinators.Json.Decode.object(field => {
  {
    error: field.required("error", JsonCombinators.Json.Decode.string),
    details: field.optional("details", JsonCombinators.Json.Decode.string),
  }
})

// Version is accessed natively

/* Helper to fetch library files */
let fetchLib = async filename => {
  try {
    let response = await Fetch.fetch("/libs/" ++ filename, Fetch.requestInit(~method="GET", ()))

    if !Fetch.ok(response) {
      Error("Missing Library: " ++ filename)
    } else {
      let b = await Fetch.blob(response)
      Ok(b)
    }
  } catch {
  | exn =>
    let (msg, _stack) = Logger.getErrorDetails(exn)
    Error(msg)
  }
}

/* XHR Upload Logic via Raw JS (for progress events) */
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
        if (!navigator.onLine) {
            reject(new Error("NetworkOffline: You appear to be offline. Please check your connection."));
            return;
        }

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
            if (!navigator.onLine) {
                reject(new Error("NetworkOffline: You appear to be offline. Please check your connection and try again."));
            } else {
                reject(new Error("NetworkError: Export upload failed. The backend may be unreachable."));
            }
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

let throwableMessageRaw: 'a => string = %raw(`
  function(e) {
    try {
      if (e == null) return "";
      if (typeof e === "string") return e;
      if (e instanceof Error) return e.message || String(e);
      if (typeof e.message === "string" && e.message.length > 0) return e.message;
      if (typeof e === "object") {
        try {
          return JSON.stringify(e);
        } catch (_) {
          return String(e);
        }
      }
      return String(e);
    } catch (_) {
      return "";
    }
  }
`)

let normalizeThrowableMessage = (exn: exn): string => {
  let (msg, _) = Logger.getErrorDetails(exn)
  if msg != "" && msg != "Unknown JS Error" && msg != "Unknown Error" {
    msg
  } else {
    let fallback = throwableMessageRaw(exn)
    if fallback != "" {
      fallback
    } else {
      "Unexpected export error"
    }
  }
}

let isUnauthorizedHttpError = (msg: string): bool => {
  String.includes(msg, "HttpError: Status 401")
}

let extractHttpErrorBody = (msg: string): string => {
  let parts = String.split(msg, " - ")
  if Belt.Array.length(parts) > 1 {
    Belt.Array.get(parts, 1)->Option.getOr(msg)
  } else {
    msg
  }
}

let fetchSceneUrlBlob = async (~url: string, ~authToken: option<string>): result<
  Blob.t,
  string,
> => {
  try {
    let headers = Dict.make()
    authToken->Option.forEach(t => Dict.set(headers, "Authorization", "Bearer " ++ t))
    let response = await Fetch.fetch(url, Fetch.requestInit(~method="GET", ~headers, ()))
    if Fetch.ok(response) {
      let b = await Fetch.blob(response)
      Ok(b)
    } else {
      let body = await Fetch.text(response)
      Error("HttpError: Status " ++ Belt.Int.toString(Fetch.status(response)) ++ " - " ++ body)
    }
  } catch {
  | exn => {
      let msg = normalizeThrowableMessage(exn)
      Error("Failed to fetch scene asset: " ++ msg)
    }
  }
}

let normalizeLogoExtension = (name: string): string => {
  let parts = name->String.toLowerCase->String.split(".")
  let ext = parts->Belt.Array.get(Array.length(parts) - 1)->Option.getOr("png")
  switch ext {
  | "png" | "jpg" | "jpeg" | "webp" | "svg" => ext
  | _ => "png"
  }
}

let filenameFromUrl = (url: string): option<string> => {
  let cleaned = url->String.split("?")->Belt.Array.get(0)->Option.getOr(url)
  let segments = cleaned->String.split("/")
  let fileName = segments->Belt.Array.get(Array.length(segments) - 1)->Option.getOr("")
  if fileName == "" {
    None
  } else {
    Some(fileName)
  }
}

let isLikelyImageUrl = (url: string): bool => {
  let lowered = url->String.toLowerCase
  String.includes(lowered, ".png") ||
  String.includes(lowered, ".jpg") ||
  String.includes(lowered, ".jpeg") ||
  String.includes(lowered, ".webp") ||
  String.includes(lowered, ".svg")
}

let isLikelyImageBlob = (~blob: Blob.t, ~urlHint: option<string>): bool => {
  let mime = blob->Blob.type_->String.toLowerCase
  if String.startsWith(mime, "image/") {
    true
  } else {
    switch (mime, urlHint) {
    | ("", Some(url)) => isLikelyImageUrl(url)
    | _ => false
    }
  }
}

let exportTour = async (
  scenes: array<scene>,
  ~tourName: string,
  ~logo: option<file>,
  ~projectData: option<JSON.t>=?,
  ~signal: BrowserBindings.AbortSignal.t,
  onProgress: option<(float, float, string) => unit>,
): result<unit, string> => {
  let progress = (p, t, m) => {
    switch onProgress {
    | Some(cb) => cb(p, t, m)
    | None => ()
    }
  }

  let tourName = if tourName == "" {
    "Virtual_Tour"
  } else {
    tourName
  }
  let safeName = tourName->String.replaceRegExp(/[^a-z0-9]/gi, "_")->String.toLowerCase

  // Progress starts after confirmation in higher level?
  // For Export it starts immediately because there is no file picker BEFORE upload.
  progress(0.0, 100.0, "Preparing assets...")
  let exportStartTime = Date.now()
  let currentPhase = ref("INITIAL")

  Logger.startOperation(
    ~module_="Exporter",
    ~operation="EXPORT",
    ~data=Some({"sceneCount": Belt.Array.length(scenes), "tourName": tourName}),
    (),
  )

  try {
    let formData = FormData.newFormData()
    let version = Version.version
    let token = Dom.Storage2.localStorage->Dom.Storage2.getItem("auth_token")
    let finalToken = switch token {
    | Some(t) => Some(t)
    | None if Constants.isDebugBuild() => Some("dev-token")
    | None => None
    }

    /* 1. Set Logo (prioritize custom uploaded logo) */
    currentPhase := "LOGO"
    Logger.debug(~module_="Exporter", ~message="PHASE_LOGO", ())

    let logoFilename = ref(None)

    switch logo {
    | Some(File(f)) => {
        let name = "logo." ++ normalizeLogoExtension(f->File.name)
        FormData.appendWithFilename(formData, name, f, name)
        logoFilename := Some(name)
      }
    | Some(Blob(b)) => {
        let name = "logo.png" // Default extension for blobs if unknown
        FormData.appendWithFilename(formData, name, b, name)
        logoFilename := Some(name)
      }
    | Some(Url(url)) =>
      if url == "" || !isLikelyImageUrl(url) {
        Logger.warn(
          ~module_="Exporter",
          ~message="LOGO_URL_SKIPPED_INVALID",
          ~data=Some({"url": url}),
          (),
        )
      } else {
        switch await fetchSceneUrlBlob(~url, ~authToken=finalToken) {
        | Ok(logoBlob) =>
          if isLikelyImageBlob(~blob=logoBlob, ~urlHint=Some(url)) {
            let ext = switch filenameFromUrl(url) {
            | Some(fileName) => normalizeLogoExtension(fileName)
            | None => "png"
            }
            let name = "logo." ++ ext
            FormData.appendWithFilename(formData, name, logoBlob, name)
            logoFilename := Some(name)
          } else {
            Logger.warn(
              ~module_="Exporter",
              ~message="LOGO_URL_NOT_IMAGE",
              ~data=Some({"url": url, "blobType": logoBlob->Blob.type_}),
              (),
            )
          }
        | Error(msg) =>
          Logger.warn(
            ~module_="Exporter",
            ~message="LOGO_URL_FETCH_FAILED",
            ~data=Some({"url": url, "error": msg}),
            (),
          )
        }
      }
    | None => ()
    }

    if logoFilename.contents == None {
      try {
        let extensions = ["png", "jpg", "jpeg", "webp"]
        let rec findLogo = async exts => {
          switch exts {
          | list{} => ()
          | list{ext, ...rest} => {
              let filename = "logo." ++ ext
              let path = "/images/" ++ filename
              let res = await Fetch.fetchSimple(path)
              if Fetch.ok(res) {
                let logoBlob = await Fetch.blob(res)
                if isLikelyImageBlob(~blob=logoBlob, ~urlHint=Some(path)) {
                  FormData.appendWithFilename(formData, filename, logoBlob, filename)
                  logoFilename := Some(filename)
                } else {
                  await findLogo(rest)
                }
              } else {
                await findLogo(rest)
              }
            }
          }
        }
        await findLogo(Belt.List.fromArray(extensions))
      } catch {
      | _ => Logger.warn(~module_="Exporter", ~message="LOGO_NOT_FOUND", ())
      }
    }

    /* 2. Generate HTML Templates */
    currentPhase := "TEMPLATES"
    Logger.debug(~module_="Exporter", ~message="PHASE_TEMPLATES", ())
    let html4k = TourTemplates.generateTourHTML(
      scenes,
      tourName,
      logoFilename.contents,
      "4k",
      28,
      60,
      version,
    )
    let html2k = TourTemplates.generateTourHTML(
      scenes,
      tourName,
      logoFilename.contents,
      "2k",
      28,
      50,
      version,
    )
    let htmlHd = TourTemplates.generateTourHTML(
      scenes,
      tourName,
      logoFilename.contents,
      "hd",
      28,
      40,
      version,
    )
    let htmlIndex = TourTemplates.generateExportIndex(tourName, version, logoFilename.contents)
    let embed = TourTemplates.generateEmbedCodes(tourName, Version.version)

    FormData.append(formData, "html_4k", html4k)
    FormData.append(formData, "html_2k", html2k)
    FormData.append(formData, "html_hd", htmlHd)
    FormData.append(formData, "html_index", htmlIndex)
    FormData.append(formData, "embed_codes", embed)
    projectData->Option.forEach(data =>
      FormData.append(formData, "project_data", JsonCombinators.Json.stringify(data))
    )

    /* 3. Append Libraries */
    currentPhase := "LIBRARIES"
    Logger.debug(~module_="Exporter", ~message="PHASE_LIBRARIES", ())
    try {
      let panJSRes: result<Blob.t, string> = await fetchLib("pannellum.js")
      let panCSSRes: result<Blob.t, string> = await fetchLib("pannellum.css")
      switch (panJSRes, panCSSRes) {
      | (Ok(panJS), Ok(panCSS)) => {
          FormData.appendWithFilename(formData, "pannellum.js", panJS, "pannellum.js")
          FormData.appendWithFilename(formData, "pannellum.css", panCSS, "pannellum.css")
        }
      | (Error(e), _) | (_, Error(e)) =>
        Logger.error(~module_="Exporter", ~message="FETCH_LIBS_FAILED", ~data={"error": e}, ())
      }
    } catch {
    | exn =>
      let (msg, stack) = Logger.getErrorDetails(exn)
      Logger.error(
        ~module_="Exporter",
        ~message="FETCH_LIBS_FAILED",
        ~data={"error": msg, "stack": stack},
        (),
      )
    }

    /* 4. Append Scene Images */
    currentPhase := "SCENES"
    Logger.debug(
      ~module_="Exporter",
      ~message="PHASE_SCENES",
      ~data=Some({"count": Belt.Array.length(scenes)}),
      (),
    )
    let rec appendScenes = async (sceneList, idx) => {
      switch sceneList {
      | list{} => Ok()
      | list{s, ...rest} => {
          let sourceFile = switch s.originalFile {
          | Some(f) => f
          | None => s.file
          }

          let blobResult = switch sourceFile {
          | Blob(b) => Ok(b)
          | File(f) => Ok(UiHelpers.fileToBlob(File(f)))
          | Url(url) =>
            let initial = await fetchSceneUrlBlob(~url, ~authToken=finalToken)
            switch initial {
            | Ok(_) => initial
            | Error(msg) =>
              let usingDevToken = switch finalToken {
              | Some(t) => t == "dev-token"
              | None => false
              }
              if Constants.isDebugBuild() && !usingDevToken && isUnauthorizedHttpError(msg) {
                await fetchSceneUrlBlob(~url, ~authToken=Some("dev-token"))
              } else {
                initial
              }
            }
          }

          switch blobResult {
          | Ok(fileBlob) =>
            FormData.appendWithFilename(
              formData,
              `scene_${Belt.Int.toString(idx)}`,
              fileBlob,
              s.name,
            )
            await appendScenes(rest, idx + 1)
          | Error(msg) => Error("Scene packaging failed for '" ++ s.name ++ "': " ++ msg)
          }
        }
      }
    }
    switch await appendScenes(Belt.List.fromArray(scenes), 0) {
    | Ok() => ()
    | Error(msg) => JsError.throwWithMessage(msg)
    }

    /* 5. Send via XHR */
    currentPhase := "UPLOAD"
    Logger.info(~module_="Exporter", ~message="UPLOAD_START", ())
    let backendUrl = Constants.backendUrl

    let rec uploadWithRetry = async (retryCount, token) => {
      try {
        let result = await uploadAndProcessRaw(formData, progress, backendUrl, ~signal, ~token)
        CircuitBreaker.recordSuccess(AuthenticatedClient.circuitBreaker)
        result
      } catch {
      | exn =>
        let msg = normalizeThrowableMessage(exn)
        let isOffline = String.includes(msg, "NetworkOffline")
        let isAbort = String.includes(msg, "AbortError")
        let isUnauthorized = isUnauthorizedHttpError(msg)

        let usingDevToken = switch token {
        | Some(t) => t == "dev-token"
        | None => false
        }
        let shouldRetryWithDevToken =
          Constants.isDebugBuild() && !usingDevToken && isUnauthorized

        if shouldRetryWithDevToken {
          Logger.warn(
            ~module_="Exporter",
            ~message="EXPORT_RETRY_WITH_DEV_TOKEN",
            ~data=Some({"reason": "401 Unauthorized", "hadAuthToken": token != None}),
            (),
          )
          await uploadWithRetry(0, Some("dev-token"))
        } else if retryCount < 2 && !isOffline && !isAbort && !isUnauthorized {
          Logger.warn(
            ~module_="Exporter",
            ~message="EXPORT_RETRY",
            ~data=Some(Logger.castToJson({"attempt": retryCount + 1, "error": msg})),
            (),
          )
          progress(0.0, 100.0, "Retrying export upload...")
          let _ = await Promise.make((resolve, _) => {
            let _ = ReBindings.Window.setTimeout(() => resolve(.), 2000)
          })
          await uploadWithRetry(retryCount + 1, token)
        } else {
          CircuitBreaker.recordFailure(AuthenticatedClient.circuitBreaker)
          JsError.throwWithMessage(msg)
        }
      }
    }

    let zipBlob = await uploadWithRetry(0, finalToken)

    progress(100.0, 100.0, "Saving...")
    let filename = `Export_RMX_${safeName}_v${version}.zip`
    Logger.endOperation(
      ~module_="Exporter",
      ~operation="EXPORT",
      ~data=Some({"filename": filename, "durationMs": Date.now() -. exportStartTime}),
      (),
    )
    Logger.info(
      ~module_="Exporter",
      ~message="DOWNLOAD_TRIGGERED",
      ~data=Some({"filename": filename}),
      (),
    )
    DownloadSystem.saveBlob(zipBlob, filename)
    Ok()
  } catch {
  | exn => {
      let (msgFromLogger, stack) = Logger.getErrorDetails(exn)
      let msg = normalizeThrowableMessage(exn)
      let normalizedStack = if stack != "" {
        stack
      } else {
        msgFromLogger
      }

      if String.includes(msg, "AbortError") {
        Logger.info(~module_="Exporter", ~message="EXPORT_CANCELLED", ())
        progress(0.0, 0.0, "Cancelled")
        Error("CANCELLED")
      } else {
        let payload = extractHttpErrorBody(msg)
        let finalMsg = switch JsonCombinators.Json.parse(payload) {
        | Ok(json) =>
          switch JsonCombinators.Json.decode(json, apiErrorDecoder) {
          | Ok(err) => err.details->Option.getOr(err.error)
          | Error(_) => payload
          }
        | Error(_) => payload
        }

        Logger.error(
          ~module_="Exporter",
          ~message="EXPORT_FAILED",
          ~data={"error": finalMsg, "stack": normalizedStack, "phase": currentPhase.contents},
          (),
        )
        // ... dispatch notification ...
        progress(0.0, 0.0, "Failed")
        Error(finalMsg)
      }
    }
  }
}
