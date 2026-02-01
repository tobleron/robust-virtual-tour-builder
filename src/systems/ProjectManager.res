/* src/systems/ProjectManager.res - Consolidated Project Manager System */

open ReBindings
open Types

// --- TYPES ---

type onProgress = (int, int, string) => unit
type apiError = string

// --- INTERNAL LOGIC ---

module Logic = {
  external asJson: unknown => JSON.t = "%identity"

  let validationReportWrapperDecoder = JsonCombinators.Json.Decode.object(field => {
    field.required("validationReport", JsonParsers.Shared.validationReport)
  })

  let validateProjectStructure = (data: JSON.t): result<JSON.t, apiError> => {
    switch JsonCombinators.Json.decode(data, JsonParsers.Domain.project) {
    | Ok(_) => Ok(data)
    | Error(e) => Error("Invalid project structure: " ++ e)
    }
  }

  let createSavePackage = (state: state, ~onProgress: option<onProgress>=?): Promise.t<
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

    let jsonStr = switch JSON.stringifyAny(project) {
    | Some(s) => s
    | None => "{}"
    }
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
        Fetch.requestInit(~method="POST", ~body=formData, ()),
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
        let tokenQuery = switch token {
        | Some(t) => "?token=" ++ t
        | None => ""
        }

        let validScenes = Belt.Array.map(pd.scenes, scene => {
          let fileUrl =
            Constants.backendUrl ++
            "/api/project/" ++
            sessionId ++
            "/file/" ++
            encodeURIComponent(scene.name) ++
            tokenQuery

          {...scene, file: Url(fileUrl), originalFile: Some(Url(fileUrl))}
        })

        let loadedProject: Types.project = {
          ...pd,
          scenes: validScenes,
        }

        // Encode back to JSON ensuring Types.file is serialized as string, not variant object
        let safeEncodeFile = (f: Types.file) => {
          switch f {
          | Url(u) => JsonCombinators.Json.Encode.string(u)
          | _ => JsonCombinators.Json.Encode.string("")
          }
        }

        let encodeField = (key, encoder, value) => {
          Some((key, encoder(value)))
        }

        let encodeOpt = (key, encoder, valueOpt) => {
          switch valueOpt {
          | Some(v) => Some((key, encoder(v)))
          | None => None
          }
        }

        let safeEncodeHotspot = (h: Types.hotspot) => {
          JsonCombinators.Json.Encode.object(
            Belt.Array.keepMap(
              [
                encodeField("linkId", JsonCombinators.Json.Encode.string, h.linkId),
                encodeField("yaw", JsonCombinators.Json.Encode.float, h.yaw),
                encodeField("pitch", JsonCombinators.Json.Encode.float, h.pitch),
                encodeField("target", JsonCombinators.Json.Encode.string, h.target),
                encodeOpt("targetYaw", JsonCombinators.Json.Encode.float, h.targetYaw),
                encodeOpt("targetPitch", JsonCombinators.Json.Encode.float, h.targetPitch),
                encodeOpt("targetHfov", JsonCombinators.Json.Encode.float, h.targetHfov),
                encodeOpt("startYaw", JsonCombinators.Json.Encode.float, h.startYaw),
                encodeOpt("startPitch", JsonCombinators.Json.Encode.float, h.startPitch),
                encodeOpt("startHfov", JsonCombinators.Json.Encode.float, h.startHfov),
                encodeOpt("isReturnLink", JsonCombinators.Json.Encode.bool, h.isReturnLink),
                encodeOpt("viewFrame", JsonParsers.Encoders.viewFrame, h.viewFrame),
                encodeOpt("returnViewFrame", JsonParsers.Encoders.viewFrame, h.returnViewFrame),
                encodeOpt(
                  "waypoints",
                  JsonCombinators.Json.Encode.array(JsonParsers.Encoders.viewFrame),
                  h.waypoints,
                ),
                encodeOpt("displayPitch", JsonCombinators.Json.Encode.float, h.displayPitch),
                encodeOpt("transition", JsonCombinators.Json.Encode.string, h.transition),
                encodeOpt(
                  "duration",
                  i => JsonCombinators.Json.Encode.float(Belt.Int.toFloat(i)),
                  h.duration,
                ),
              ],
              x => x,
            ),
          )
        }

        let safeEncodeScene = (s: Types.scene) => {
          JsonCombinators.Json.Encode.object(
            Belt.Array.keepMap(
              [
                encodeField("id", JsonCombinators.Json.Encode.string, s.id),
                encodeField("name", JsonCombinators.Json.Encode.string, s.name),
                encodeField("file", safeEncodeFile, s.file),
                encodeOpt("tinyFile", safeEncodeFile, s.tinyFile),
                encodeOpt("originalFile", safeEncodeFile, s.originalFile),
                encodeField(
                  "hotspots",
                  JsonCombinators.Json.Encode.array(safeEncodeHotspot),
                  s.hotspots,
                ),
                encodeField("category", JsonCombinators.Json.Encode.string, s.category),
                encodeField("floor", JsonCombinators.Json.Encode.string, s.floor),
                encodeField("label", JsonCombinators.Json.Encode.string, s.label),
                encodeOpt("quality", JsonParsers.Encoders.value, s.quality),
                encodeOpt("colorGroup", JsonCombinators.Json.Encode.string, s.colorGroup),
                encodeField(
                  "_metadataSource",
                  JsonCombinators.Json.Encode.string,
                  s._metadataSource,
                ),
                encodeField("categorySet", JsonCombinators.Json.Encode.bool, s.categorySet),
                encodeField("labelSet", JsonCombinators.Json.Encode.bool, s.labelSet),
                encodeField("isAutoForward", JsonCombinators.Json.Encode.bool, s.isAutoForward),
              ],
              x => x,
            ),
          )
        }

        let json = JsonCombinators.Json.Encode.object(
          Belt.Array.keepMap(
            [
              encodeField("tourName", JsonCombinators.Json.Encode.string, loadedProject.tourName),
              encodeField(
                "scenes",
                JsonCombinators.Json.Encode.array(safeEncodeScene),
                loadedProject.scenes,
              ),
              encodeField(
                "lastUsedCategory",
                JsonCombinators.Json.Encode.string,
                loadedProject.lastUsedCategory,
              ),
              encodeOpt("exifReport", JsonParsers.Encoders.value, loadedProject.exifReport),
              encodeOpt("sessionId", JsonCombinators.Json.Encode.string, loadedProject.sessionId),
              encodeField(
                "deletedSceneIds",
                JsonCombinators.Json.Encode.array(JsonCombinators.Json.Encode.string),
                loadedProject.deletedSceneIds,
              ),
              encodeField(
                "timeline",
                JsonCombinators.Json.Encode.array(JsonParsers.Encoders.timelineItem),
                loadedProject.timeline,
              ),
            ],
            x => x,
          ),
        )

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
        Promise.resolve(Ok((sessionId, json)))
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

let saveProject = (state: state, ~onProgress: option<onProgress>=?) => {
  if Array.length(state.scenes) == 0 {
    Promise.resolve(false)
  } else {
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
      ->Promise.catch(_ => Promise.resolve(None))
    } else {
      Promise.resolve(None)
    }

    let saveStartTime = Date.now()
    handlePromise->Promise.then(fileHandle => {
      Logic.createSavePackage(state, ~onProgress?)->Promise.then(resultRes => {
        switch resultRes {
        | Ok(blob) =>
          if useFileHandle {
            switch fileHandle {
            | Some(h) =>
              DownloadSystem.writeFileToHandle(h, blob)->Promise.then(() => Promise.resolve(true))
            | None =>
              DownloadSystem.saveBlob(blob, filename)
              Promise.resolve(true)
            }
          } else {
            DownloadSystem.saveBlob(blob, filename)
            Promise.resolve(true)
          }->Promise.then(
            success => {
              if success {
                Logger.endOperation(
                  ~module_="ProjectManager",
                  ~operation="PROJECT_SAVE",
                  ~data=Some({"durationMs": Date.now() -. saveStartTime}),
                  (),
                )
              }
              Promise.resolve(success)
            },
          )
        | Error(_) => Promise.resolve(false)
        }
      })
    })
  }
}

let loadProject = (zipFile: File.t, ~onProgress: option<onProgress>=?): Promise.t<
  BackendApi.apiResult<(string, JSON.t)>,
> => {
  Logic.loadProjectZip(zipFile, ~onProgress?)
}
