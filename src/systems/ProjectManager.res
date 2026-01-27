/* src/systems/ProjectManager.res - Facade for ProjectManager */

open ReBindings
open Types
include ProjectManagerTypes
include ProjectManagerLogic

let saveProject = (state: state, ~onProgress: option<onProgress>=?) =>
  if Array.length(state.scenes) == 0 {
    Logger.warn(
      ~module_="ProjectManager",
      ~message="SAVE_ABORTED",
      ~data=Some({"reason": "No scenes"}),
      (),
    )
    Promise.resolve(false)
  } else {
    let tourName = if state.tourName == "" {
      "Virtual_Tour"
    } else {
      state.tourName
    }
    let safeName = String.replaceRegExp(tourName, /[^a-z0-9]/gi, "_")
    let safeName = String.toLowerCase(safeName)
    let dateParts = String.split(Date.toISOString(Date.make()), "T")
    let dateStr = Belt.Array.get(dateParts, 0)->Option.getOr("unknown_date")
    let filename =
      "Saved_RMX_" ++ safeName ++ "_v" ++ VersionData.version ++ "_" ++ dateStr ++ ".vt.zip"

    let useFileHandle = %raw(`typeof window.showSaveFilePicker !== 'undefined'`)

    let handlePromise = if useFileHandle {
      DownloadSystem.getFileHandle(filename, "application/zip")
      ->Promise.then(h => Promise.resolve(Some(h)))
      ->Promise.catch(_ => Promise.resolve(None))
    } else {
      Promise.resolve(None)
    }

    Logger.startOperation(
      ~module_="ProjectManager",
      ~operation="PROJECT_SAVE",
      ~data=Some({"tourName": tourName, "sceneCount": Array.length(state.scenes)}),
      (),
    )
    let saveStartTime = Date.now()

    handlePromise->Promise.then(fileHandle => {
      createSavePackage(state, ~onProgress?)->Promise.then(result => {
        switch result {
        | Ok(blob) =>
          Logger.info(
            ~module_="ProjectManager",
            ~message="PACKAGE_CREATED",
            ~data=Some({"size": Blob.size(blob)}),
            (),
          )

          if useFileHandle {
            switch fileHandle {
            | Some(h) =>
              DownloadSystem.writeFileToHandle(h, blob)->Promise.then(() => Promise.resolve(true))
            | None =>
              let _ = DownloadSystem.saveBlob(blob, filename)
              Promise.resolve(true)
            }
          } else {
            let _ = DownloadSystem.saveBlob(blob, filename)
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
        | Error(msg) =>
          Logger.error(
            ~module_="ProjectManager",
            ~message="PROJECT_SAVE_FAILED",
            ~data={"error": msg},
            (),
          )
          Promise.resolve(false)
        }
      })
    })
  }

let loadProject = (zipFile: File.t, ~onProgress: option<onProgress>=?): Promise.t<
  BackendApi.apiResult<(string, JSON.t)>,
> => {
  Logger.initialized(~module_="ProjectManager")
  loadProjectZip(zipFile, ~onProgress?)->Promise.then(result => {
    switch result {
    | Ok(data) => Promise.resolve(Ok(data))
    | Error(msg) => Promise.resolve(Error(msg))
    }
  })
}
