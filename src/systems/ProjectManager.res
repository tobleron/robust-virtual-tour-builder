/* src/systems/ProjectManager.res - Consolidated Project Manager System */

open ReBindings
open Types

// --- TYPES ---

type onProgress = (int, int, string) => unit
type apiError = string

// --- INTERNAL LOGIC ---

module Logic = {
  external asJson: 'a => JSON.t = "%identity"

  let validationReportWrapperDecoder = JsonCombinators.Json.Decode.object(field => {
    field.required("validationReport", JsonParsers.Shared.validationReport)
  })

  let validateProjectStructure = (data: JSON.t): result<JSON.t, apiError> => {
    switch JsonCombinators.Json.decode(data, JsonParsers.Domain.project) {
    | Ok(_) => Ok(data)
    | Error(e) => Error("Invalid project structure: " ++ e)
    }
  }

  let createSavePackage = (state: state, ~signal=?, ~onProgress: option<onProgress>=?): Promise.t<
    result<Blob.t, apiError>,
  > => {
    let progress = (curr, total, msg) => {
      switch onProgress {
      | Some(cb) => cb(curr, total, msg)
      | None => ()
      }
    }
    progress(0, 100, "Preparing metadata...")

    let project: Types.project = {
      tourName: state.tourName,
      scenes: state.scenes,
      lastUsedCategory: state.lastUsedCategory,
      exifReport: state.exifReport,
      sessionId: state.sessionId,
      deletedSceneIds: state.deletedSceneIds,
      timeline: state.timeline,
    }

    let jsonStr = JsonCombinators.Json.stringify(JsonParsers.Encoders.project(project))
    let formData = FormData.newFormData()
    FormData.append(formData, "project_data", jsonStr)

    Belt.Array.forEachWithIndex(state.scenes, (_index, scene) => {
      switch scene.file {
      | File(f) => FormData.appendWithFilename(formData, "files", f, scene.name)
      | Blob(b) => FormData.appendWithFilename(formData, "files", b, scene.name)
      | Url(_) => ()
      }
    })
    state.sessionId->Option.forEach(id => FormData.append(formData, "session_id", id))

    progress(10, 100, "Uploading to backend...")
    RequestQueue.schedule(() => {
      Fetch.fetch(
        Constants.backendUrl ++ "/api/project/save",
        Fetch.requestInit(~method="POST", ~body=formData, ~signal?, ()),
      )
      ->Promise.then(BackendApi.handleResponse)
      ->Promise.then(resultRes => {
        switch resultRes {
        | Ok(res) => Fetch.blob(res)->Promise.then(blob => Promise.resolve(Ok(blob)))
        | Error(msg) => Promise.resolve(Error(msg))
        }
      })
    })
    ->Promise.then(blobResult => {
      switch blobResult {
      | Ok(blob) =>
        progress(100, 100, "Package created!")
        Promise.resolve(Ok(blob))
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(err => {
      let (msg, _) = Logger.getErrorDetails(err)
      Promise.resolve(Error(msg))
    })
  }

  let processLoadedProjectData = (
    resultSessionData: result<(string, JSON.t), apiError>,
    ~loadStartTime: float,
    ~onProgress: option<onProgress>=?,
  ): Promise.t<BackendApi.apiResult<(string, JSON.t)>> => {
    let progress = (curr, total, msg) => {
      switch onProgress {
      | Some(cb) => cb(curr, total, msg)
      | None => ()
      }
    }
    switch resultSessionData {
    | Ok((sessionId, projectData)) =>
      progress(70, 100, "Resolving scenes...")

      // Check validation report
      switch JsonCombinators.Json.decode(projectData, validationReportWrapperDecoder) {
      | Ok(r) =>
        if r.brokenLinksRemoved > 0 {
          EventBus.dispatch(
            ShowNotification(
              "Project loaded. " ++
              Belt.Int.toString(r.brokenLinksRemoved) ++ " broken link(s) removed.",
              #Warning,
              None,
            ),
          )
        }
        if Array.length(r.orphanedScenes) > 0 {
          EventBus.dispatch(
            ShowNotification(
              "Warning: " ++
              Belt.Int.toString(Array.length(r.orphanedScenes)) ++ " orphaned scene(s) detected.",
              #Warning,
              None,
            ),
          )
        }
        r.errors->Belt.Array.forEach(error =>
          EventBus.dispatch(ShowNotification("Error: " ++ error, #Error, None))
        )
      | Error(_) => ()
      }

      switch JsonCombinators.Json.decode(projectData, JsonParsers.Domain.project) {
      | Ok(pd) =>
        let token = Dom.Storage2.localStorage->Dom.Storage2.getItem("auth_token")
        let finalToken = switch token {
        | Some(t) => t
        | None => "dev-token" // Professional fallback for local development automation
        }
        let tokenQuery = "?token=" ++ finalToken

        let rebuildUrl = (f: Types.file) => {
          switch f {
          | Url(url) =>
            let isFullUrl = String.startsWith(url, "http")
            let isLegacyBackend = String.includes(url, "/api/project/")

            // Blob URLs from saved projects are invalid/dead in the new session.
            // We return Empty to force the scene-name fallback within validScenes loop.
            if String.startsWith(url, "blob:") {
              Types.Url("")
            } else if isLegacyBackend {
              // Extract filename from old backend URL and rebuild with current sessionId
              let parts = String.split(url, "/file/")
              switch Belt.Array.get(parts, 1) {
              | Some(afterFile) =>
                let filename =
                  String.split(afterFile, "?")->Belt.Array.get(0)->Option.getOr(afterFile)
                Types.Url(
                  Constants.backendUrl ++
                  "/api/project/" ++
                  sessionId ++
                  "/file/" ++
                  filename ++
                  tokenQuery,
                )
              | None => f
              }
            } else if isFullUrl {
              f
            } else if url != "" {
              // It's a relative path (e.g., "images/room1.jpg" or "room1.jpg")
              let filename = if String.includes(url, "/") {
                let parts = String.split(url, "/")
                Belt.Array.get(parts, Array.length(parts) - 1)->Option.getOr(url)
              } else {
                url
              }
              Types.Url(
                Constants.backendUrl ++
                "/api/project/" ++
                sessionId ++
                "/file/" ++
                encodeURIComponent(filename) ++
                tokenQuery,
              )
            } else {
              f
            }
          | _ => f
          }
        }

        let validScenes = Belt.Array.map(pd.scenes, scene => {
          // 1. Rebuild primary file URL
          let file = switch rebuildUrl(scene.file) {
          | Url(u) if u != "" && (String.startsWith(u, "http") || String.startsWith(u, "blob:")) =>
            Types.Url(u)
          | _ =>
            // Fallback: Use scene name as filename
            Types.Url(
              Constants.backendUrl ++
              "/api/project/" ++
              sessionId ++
              "/file/" ++
              encodeURIComponent(scene.name) ++
              tokenQuery,
            )
          }

          let originalFile = scene.originalFile->Option.flatMap(f => {
            switch rebuildUrl(f) {
            | Url("") => None
            | Url(u) => Some(Types.Url(u))
            | other => Some(other)
            }
          })

          let tinyFile = scene.tinyFile->Option.flatMap(f => {
            switch rebuildUrl(f) {
            | Url("") => None
            | Url(u) => Some(Types.Url(u))
            | other => Some(other)
            }
          })

          {...scene, file, originalFile, tinyFile}
        })

        let loadedProject: Types.project = {
          ...pd,
          scenes: validScenes,
        }

        progress(100, 100, "Project Loaded!")
        Logger.endOperation(
          ~module_="ProjectManager",
          ~operation="PROJECT_LOAD",
          ~data=Some({
            "sceneCount": Array.length(validScenes),
            "durationMs": Date.now() -. loadStartTime,
          }),
          (),
        )
        Promise.resolve(Ok((sessionId, JsonParsers.Encoders.project(loadedProject))))
      | Error(e) => Promise.resolve(Error("Failed to parse project data: " ++ e))
      }

    | Error(msg) => Promise.resolve(Error(msg))
    }
  }

  let loadProjectZip = (zipFile: File.t, ~onProgress: option<onProgress>=?) => {
    let progress = (curr, total, msg) => {
      switch onProgress {
      | Some(cb) => cb(curr, total, msg)
      | None => ()
      }
    }
    progress(0, 100, "Uploading project...")
    let loadStartTime = Date.now()
    Logger.startOperation(
      ~module_="ProjectManager",
      ~operation="PROJECT_LOAD",
      ~data=Some({"filename": File.name(zipFile), "size": File.size(zipFile)}),
      (),
    )

    BackendApi.importProject(zipFile)
    ->Promise.then(resultRes => {
      switch resultRes {
      | Ok(response) =>
        progress(50, 100, "Processing response...")
        validateProjectStructure(response.projectData)
        ->Belt.Result.map(pd => (response.sessionId, pd))
        ->Promise.resolve
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.then(resultSessionData =>
      processLoadedProjectData(resultSessionData, ~loadStartTime, ~onProgress?)
    )
  }
}

// --- FACADE ---

let saveProject = (state: state, ~signal=?, ~onProgress: option<onProgress>=?) => {
  if Array.length(state.scenes) == 0 {
    Promise.resolve(false)
  } else {
    let journalId = OperationJournal.startOperation(
      ~operation="SaveProject",
      ~context=Logic.asJson({
        "sceneCount": Array.length(state.scenes),
        "tourName": state.tourName,
      }),
      ~retryable=true,
    )

    let tourName = if state.tourName == "" {
      "Virtual_Tour"
    } else {
      state.tourName
    }
    let safeName = String.replaceRegExp(tourName, /[^a-z0-9]/gi, "_")->String.toLowerCase
    let dateParts = String.split(Date.toISOString(Date.make()), "T")
    let dateStr = Belt.Array.get(dateParts, 0)->Option.getOr("unknown_date")
    let filename =
      "Saved_RMX_" ++ safeName ++ "_v" ++ Version.version ++ "_" ++ dateStr ++ ".vt.zip"

    let useFileHandle = %raw(`typeof window.showSaveFilePicker !== 'undefined'`)
    let handlePromise = if useFileHandle {
      DownloadSystem.getFileHandle(filename, "application/zip")
      ->Promise.then(h => Promise.resolve(Some(h)))
      ->Promise.catch(exn => {
        let (msg, _) = Logger.getErrorDetails(exn)
        if String.includes(msg, "AbortError") {
          Promise.reject(exn)
        } else {
          Promise.resolve(None)
        }
      })
    } else {
      Promise.resolve(None)
    }

    let saveStartTime = Date.now()
    handlePromise
    ->Promise.then(fileHandle => {
      // Progress starts AFTER the file handle (confirmation) is received
      let progress = (curr, total, msg) => {
        switch onProgress {
        | Some(cb) => cb(curr, total, msg)
        | None => ()
        }
      }
      progress(0, 100, "Initializing save...")

      Logic.createSavePackage(state, ~signal?, ~onProgress?)->Promise.then(resultRes => {
        switch resultRes {
        | Ok(blob) =>
          if useFileHandle {
            switch fileHandle {
            | Some(h) =>
              DownloadSystem.writeFileToHandle(h, blob)->Promise.then(() => Promise.resolve(true))
            | None =>
              // This can only happen if useFileHandle was true but handle was skipped (not AbortError)
              DownloadSystem.saveBlob(blob, filename)
              Promise.resolve(true)
            }
          } else {
            DownloadSystem.saveBlob(blob, filename)
            Promise.resolve(true)
          }->Promise.then(
            success => {
              if success {
                OperationJournal.completeOperation(journalId)
                Logger.endOperation(
                  ~module_="ProjectManager",
                  ~operation="PROJECT_SAVE",
                  ~data=Some({"durationMs": Date.now() -. saveStartTime}),
                  (),
                )
              } else {
                OperationJournal.failOperation(journalId, "Save failed during file write")
              }
              Promise.resolve(success)
            },
          )
        | Error(msg) => {
          if String.includes(msg, "AbortError") {
            OperationJournal.updateStatus(journalId, Cancelled)
          } else {
            OperationJournal.failOperation(journalId, msg)
          }
          Promise.resolve(false)
        }
        }
      })
    })
    ->Promise.catch(exn => {
      let (msg, _) = Logger.getErrorDetails(exn)
      if String.includes(msg, "AbortError") {
        OperationJournal.updateStatus(journalId, Cancelled)
        Logger.info(~module_="ProjectManager", ~message="SAVE_CANCELLED_PICKER", ())
      } else {
        OperationJournal.failOperation(journalId, msg)
        Logger.error(~module_="ProjectManager", ~message="SAVE_FAILED", ~data={"error": msg}, ())
      }
      Promise.resolve(false)
    })
  }
}

let loadProject = (zipFile: File.t, ~onProgress: option<onProgress>=?): Promise.t<
  BackendApi.apiResult<(string, JSON.t)>,
> => {
  Logic.loadProjectZip(zipFile, ~onProgress?)
}
