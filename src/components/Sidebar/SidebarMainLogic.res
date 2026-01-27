/* src/components/Sidebar/SidebarMainLogic.res */

open ReBindings

let updateProgress = (pct, msg, active, phase) => {
  EventBus.dispatch(
    UpdateProcessing({
      "active": active,
      "progress": pct,
      "message": msg,
      "phase": phase,
      "error": false,
    }),
  )
}

let handleUpload = async filesOpt => {
  switch filesOpt {
  | Some(files) if FileList.length(files) > 0 =>
    let fileArray = JsHelpers.from(files)

    try {
      let result: UploadProcessorTypes.processResult = await UploadProcessor.processUploads(
        fileArray,
        Some(
          (pct, msg, isProc, phase) => {
            updateProgress(pct, msg, isProc, phase)
          },
        ),
      )

      let qualityResults = result.qualityResults
      let report = result.report

      UploadReport.show(report, qualityResults)
    } catch {
    | JsExn(obj) =>
      let msg = switch JsExn.message(obj) {
      | Some(m) => m
      | None => "Unknown error"
      }
      EventBus.dispatch(ShowNotification("Upload failed: " ++ msg, #Error))
      updateProgress(0.0, "Error: " ++ msg, false, "")
    | _ => ()
    }
  | _ => ()
  }
}

let handleLoadProject = async (filesOpt, dispatch, sceneCount, target) => {
  switch filesOpt {
  | Some(files) if FileList.length(files) > 0 =>
    SessionStore.clearState()
    updateProgress(0.0, "Loading Project...", true, "Loading")
    try {
      switch FileList.item(files, 0) {
      | Some(file) =>
        Logger.startOperation(
          ~module_="Sidebar",
          ~operation="PROJECT_LOAD",
          ~data={
            "filename": File.name(file),
            "size": File.size(file),
          },
          (),
        )
        let projectDataResult = await ProjectManager.loadProject(file, ~onProgress=(
          pct,
          _t,
          msg,
        ) => {
          updateProgress(pct->Int.toFloat, msg, true, "Loading")
        })

        switch projectDataResult {
        | Ok((sessionId, projectData)) => {
            dispatch(Actions.SetSessionId(sessionId))
            dispatch(Actions.LoadProject(projectData))
            UploadReport.showFromProjectData(projectData)

            Logger.endOperation(
              ~module_="Sidebar",
              ~operation="PROJECT_LOAD",
              ~data={
                "sceneCount": sceneCount,
              },
              (),
            )

            EventBus.dispatch(ShowNotification("Project loaded", #Success))
            updateProgress(100.0, "Loaded", false, "")
          }
        | Error(msg) => {
            Logger.error(
              ~module_="Sidebar",
              ~message="PROJECT_LOAD_FAILED",
              ~data={"error": msg},
              (),
            )
            EventBus.dispatch(ShowNotification("Load failed: " ++ msg, #Error))
            updateProgress(0.0, "Error", false, "")
          }
        }
      | None => ()
      }
    } catch {
    | JsExn(obj) =>
      let msg = switch JsExn.message(obj) {
      | Some(m) => m
      | None => "Unknown error"
      }
      Logger.error(
        ~module_="Sidebar",
        ~message="PROJECT_LOAD_FAILED",
        ~data={"error": msg},
        (),
      )
      EventBus.dispatch(ShowNotification("Load failed: " ++ msg, #Error))
      updateProgress(0.0, "Error", false, "")
    | _ =>
      Logger.error(
        ~module_="Sidebar",
        ~message="PROJECT_LOAD_FAILED",
        ~data={"error": "Unknown"},
        (),
      )
      EventBus.dispatch(ShowNotification("Load failed", #Error))
      updateProgress(0.0, "Error", false, "")
    }
    target->Dom.setValue("")
  | _ => ()
  }
}

let handleSave = async () => {
  updateProgress(0.0, "Saving...", true, "Saving")
  try {
    let currentState = GlobalStateBridge.getState()
    let _ = await ProjectManager.saveProject(currentState, ~onProgress=(
      pct,
      _,
      msg,
    ) => updateProgress(pct->Int.toFloat, msg, true, "Saving"))
    EventBus.dispatch(ShowNotification("Project saved", #Success))
    updateProgress(100.0, "Saved", false, "")
  } catch {
  | _ => updateProgress(0.0, "Error", false, "")
  }
}

let handleExport = async scenes => {
  updateProgress(0.0, "Exporting...", true, "Export")
  try {
    let exportResult = await Exporter.exportTour(
      scenes,
      Some((pct, _, msg) => updateProgress(pct, msg, true, "Export")),
    )
    switch exportResult {
    | Ok() => {
        EventBus.dispatch(ShowNotification("Export complete", #Success))
        updateProgress(100.0, "Done", false, "")
      }
    | Error(msg) => {
        EventBus.dispatch(ShowNotification("Export failed: " ++ msg, #Error))
        updateProgress(0.0, "Error", false, "")
      }
    }
  } catch {
  | _ => updateProgress(0.0, "Error", false, "")
  }
}
