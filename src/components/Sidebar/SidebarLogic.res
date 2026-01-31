// @efficiency-role: ui-component

external asDynamic: 'a => {..} = "%identity"

module SidebarTypes = {
  type procState = {
    active: bool,
    progress: float,
    message: string,
    phase: string,
    error: bool,
  }

  type file = ReBindings.File.t

  type processingPayload = {
    "active": bool,
    "progress": float,
    "message": string,
    "phase": string,
    "error": bool,
  }
}

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

let performUpload = async files => {
  let fileArray = JsHelpers.from(files)

  try {
    let result: UploadTypes.processResult = await UploadProcessor.processUploads(
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
    let data = Some(
      Logger.castToJson({
        "error": msg,
        "stack": JsExn.stack(obj)->Option.getOr(""),
      }),
    )
    EventBus.dispatch(ShowNotification("Upload failed: " ++ msg, #Error, data))
    updateProgress(0.0, "Error: " ++ msg, false, "")
  | _ => ()
  }
}

let handleUpload = async filesOpt => {
  switch filesOpt {
  | Some(files) if FileList.length(files) > 0 => await performUpload(files)
  | _ => ()
  }
}

let handleLoadProject = async (filesOpt, dispatch, _sceneCount, target) => {
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
              ~data={"success": true},
              (),
            )
            updateProgress(100.0, "Done", false, "")
          }
        | Error(msg) => {
            EventBus.dispatch(
              ShowNotification(
                "Load failed: " ++ msg,
                #Error,
                Some(Logger.castToJson({"error": msg})),
              ),
            )
            updateProgress(0.0, "Error: " ++ msg, false, "")
            Logger.endOperation(
              ~module_="Sidebar",
              ~operation="PROJECT_LOAD",
              ~data={"success": false, "error": msg},
              (),
            )
          }
        }
      | None => ()
      }
    } catch {
    | _ => updateProgress(0.0, "Error", false, "")
    }
    asDynamic(target)["value"] = ""
  | _ => ()
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
        EventBus.dispatch(ShowNotification("Export complete", #Success, None))
        updateProgress(100.0, "Done", false, "")
      }
    | Error(msg) => {
        EventBus.dispatch(
          ShowNotification(
            "Export failed: " ++ msg,
            #Error,
            Some(Logger.castToJson({"error": msg})),
          ),
        )
        updateProgress(0.0, "Error: " ++ msg, false, "")
      }
    }
  } catch {
  | _ => updateProgress(0.0, "Error", false, "")
  }
}
