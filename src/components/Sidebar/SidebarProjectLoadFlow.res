open SidebarBase
open ReBindings

@get external value: 'a => string = "value"
@set external set_value: ('a, string) => unit = "value"

let handleLoadProject = async (
  filesOpt,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
  ~sceneCount: int,
  target,
) => {
  switch filesOpt {
  | Some(files) if FileList.length(files) > 0 =>
    Logger.info(
      ~module_="SidebarLogic",
      ~message="PROJECT_LOAD_HANDLER_INVOKED",
      ~data=Some(
        Logger.castToJson({
          "fileCount": FileList.length(files),
          "sceneCount": sceneCount,
        }),
      ),
      (),
    )
    SessionStore.clearState()
    try {
      switch FileList.item(files, 0) {
      | Some(file) =>
        let controller = BrowserBindings.AbortController.make()
        let signal = BrowserBindings.AbortController.signal(controller)
        let loadSettled = ref(false)
        let finalizeStageStarted = ref(false)
        dispatch(Actions.DispatchAppFsmEvent(StartProjectLoad({name: File.name(file)})))

        let opId = OperationLifecycle.start(
          ~type_=ProjectLoad,
          ~scope=Blocking,
          ~phase="Project Load",
          ~meta=Logger.castToJson({
            "filename": File.name(file),
            "size": File.size(file),
          }),
          (),
        )
        let abort = () => SidebarProjectLoadLifecycle.abortRequest(~signal, controller)
        let fail = msg =>
          SidebarProjectLoadLifecycle.finalizeFailure(~dispatch, ~opId, ~loadSettled, ~msg)
        let onCancel = () =>
          SidebarProjectLoadLifecycle.handleCancel(
            ~dispatch,
            ~opId,
            ~loadSettled,
            ~finalizeStageStarted,
            ~abortRequest=abort,
          )

        OperationLifecycle.registerCancel(opId, onCancel)
        updateProgress(~dispatch, ~onCancel, 0.0, "Loading project...", true, "Project Load")

        Logger.startOperation(
          ~module_="Sidebar",
          ~operation="PROJECT_LOAD",
          ~data={"filename": File.name(file), "size": File.size(file)},
          (),
        )

        let timeoutId = ReBindings.Window.setTimeout(() => {
          abort()
          fail("Project load timed out. Please retry.")
        }, 120000)

        try {
          let projectDataResult = await ProjectManager.loadProject(
            file,
            ~signal,
            ~onProgress=(pct, _t, msg) => {
              if !loadSettled.contents {
                updateProgress(~dispatch, pct->Int.toFloat, msg, true, "Project Load")
              }
            },
            ~opId,
          )

          ReBindings.Window.clearTimeout(timeoutId)

          if !loadSettled.contents {
            switch projectDataResult {
            | Ok((sessionId, projectData)) => {
                ViewerSystem.resetState()
                if OperationLifecycle.isActive(opId) {
                  OperationLifecycle.progress(
                    opId,
                    88.0,
                    ~message="Applying project state...",
                    ~phase="Project Load",
                    (),
                  )
                }
                dispatch(Actions.SetSessionId(sessionId))
                dispatch(Actions.LoadProject(projectData))
                UploadReport.showFromProjectData(projectData, ~getState, ~dispatch)

                finalizeStageStarted := true
                if !loadSettled.contents {
                  loadSettled := true
                  switch await SidebarProjectLoadReadiness.waitForProjectReady(~getState, ~opId) {
                  | Ok(_) => SidebarProjectLoadLifecycle.completeReady(~dispatch, ~opId)
                  | Error(waitMsg) =>
                    SidebarProjectLoadLifecycle.completeReadyWarning(~dispatch, ~opId, ~waitMsg)
                  }
                }
              }
            | Error(msg) =>
              Logger.info(
                ~module_="SidebarLogic",
                ~message="PROJECT_LOAD_FAILED_DISPATCHING_NOTIF",
                ~data=Some({"error": msg}),
                (),
              )
              fail(msg)
            }
          }
        } catch {
        | JsExn(exn) =>
          ReBindings.Window.clearTimeout(timeoutId)
          fail(exn->JsExn.message->Option.getOr("Unexpected project load error"))
        | _ =>
          ReBindings.Window.clearTimeout(timeoutId)
          fail("Unexpected project load error")
        }
      | None => ()
      }
    } catch {
    | _ => updateProgress(~dispatch, 0.0, "Error", false, "")
    }
    set_value(target, "")
  | _ => ()
  }
}
