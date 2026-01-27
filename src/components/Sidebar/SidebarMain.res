/* src/components/Sidebar/SidebarMain.res */

open ReBindings

let autoHideDelay = Constants.progressBarAutoHideDelay
@scope(("window", "location")) @val external reload: unit => unit = "reload"

@react.component
let make = React.memo(() => {
  let sceneSlice = AppContext.useSceneSlice()
  let dispatch = AppContext.useAppDispatch()

  let fileInputRef = React.useRef(Nullable.null)
  let projectFileInputRef = React.useRef(Nullable.null)

  let (procState, setProcState) = React.useState(_ =>
    {
      "active": false,
      "progress": 0.0,
      "message": "",
      "phase": "",
      "error": false,
    }
  )

  let (localTourName, setLocalTourName) = React.useState(() => sceneSlice.tourName)
  let expectedTourName = React.useRef(sceneSlice.tourName)

  React.useEffect1(() => {
    if sceneSlice.tourName != expectedTourName.current {
      setLocalTourName(_ => sceneSlice.tourName)
      expectedTourName.current = sceneSlice.tourName
    }
    None
  }, [sceneSlice.tourName])

  React.useEffect1(() => {
    let timerId = setTimeout(
      () => {
        if localTourName != sceneSlice.tourName {
          expectedTourName.current = localTourName
          dispatch(Actions.SetTourName(localTourName))
        }
      },
      300,
    )
    Some(() => clearTimeout(timerId))
  }, [localTourName])

  let hideTimerRef = React.useRef(Nullable.null)

  React.useEffect0(() => {
    Logger.initialized(~module_="SidebarMain")
    
    let unsubscribe = EventBus.subscribe(
      event => {
        switch event {
        | UpdateProcessing(payload) =>
          switch Nullable.toOption(hideTimerRef.current) {
          | Some(timerId) =>
            clearTimeout(timerId)
            hideTimerRef.current = Nullable.null
          | None => ()
          }

          setProcState(_ => payload)

          if payload["progress"] >= 100.0 && payload["active"] {
            let timerId = setTimeout(
              () => {
                setProcState(
                  prev => {
                    let next = Object.assign(Object.make(), prev)
                    next["active"] = false
                    next
                  },
                )
                hideTimerRef.current = Nullable.null
              },
              3000,
            )
            hideTimerRef.current = Nullable.fromOption(Some(timerId))
          }
        | _ => ()
        }
      },
    )
    Some(unsubscribe)
  })

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

  let handleUpload = async e => {
    let target = JsxEvent.Form.target(e)->Dom.unsafeToElement
    let filesOpt = Dom.getFiles(target)

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

  let handleLoadProject = async e => {
    let target = JsxEvent.Form.target(e)->Dom.unsafeToElement
    let filesOpt = Dom.getFiles(target)

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
                  "sceneCount": Array.length(sceneSlice.scenes),
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

  let totalHotspots =
    sceneSlice.scenes->Belt.Array.reduce(0, (acc, s) => acc + Array.length(s.hotspots))
  let teaserReady = totalHotspots >= 3
  let exportReady = totalHotspots > 0

  <div
    className="relative w-[340px] min-w-[340px] bg-slate-50 flex flex-col z-[15000] shrink-0 h-full overflow-hidden font-ui"
  >
    <div className="relative w-full flex flex-col z-30 text-white shrink-0 sidebar-branding-header">
      <SidebarBranding />

      <SidebarActions
        exportReady
        teaserReady
        onNew={() => {
          if Array.length(sceneSlice.scenes) > 0 {
            EventBus.dispatch(
              ShowModal({
                title: "Create New Project?",
                description: Some(
                  "Are you sure you want to discard the current project? All progress will be lost.",
                ),
                icon: Some("warning"),
                content: None,
                onClose: None,
                allowClose: Some(true),
                className: Some("modal-blue"),
                buttons: [
                  {
                    label: "Cancel",
                    class_: "bg-slate-100/10 text-white hover:bg-white/20",
                    onClick: () => (),
                    autoClose: Some(true),
                  },
                  {
                    label: "Discard & New",
                    class_: "bg-danger text-white",
                    onClick: () => {
                      SessionStore.clearState()
                      reload()
                    },
                    autoClose: Some(true),
                  },
                ],
              }),
            )
          } else {
            SessionStore.clearState()
            reload()
          }
        }}
        onSave={() => {
          let _ = (
            async () => {
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
          )()
        }}
        onLoad={() => {
          switch Nullable.toOption(projectFileInputRef.current) {
          | Some(el) => Dom.click(el)
          | None => ()
          }
        }}
        onAbout={() => {
          EventBus.dispatch(
            ShowModal({
              title: "About Builder",
              description: None,
              icon: Some("info"),
              content: Some(
                <div className="flex flex-col gap-1 mt-2">
                  <p className="text-white font-semibold font-mono text-[11px]">
                    {React.string(`Version: ${VersionData.version}`)}
                  </p>
                  <p className="text-slate-200 font-mono text-[10px]">
                    {React.string(`Build: ${VersionData.buildInfo}`)}
                  </p>
                </div>,
              ),
              onClose: None,
              allowClose: Some(true),
              className: Some("modal-blue"),
              buttons: [
                {
                  label: "Close",
                  class_: "bg-slate-100/10 text-white hover:bg-white/20",
                  onClick: () => (),
                  autoClose: Some(true),
                },
              ],
            }),
          )
        }}
        onExport={() => {
          let _ = (
            async () => {
              updateProgress(0.0, "Exporting...", true, "Export")
              try {
                let exportResult = await Exporter.exportTour(
                  sceneSlice.scenes,
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
              Promise.resolve()
            }
          )()
        }}
        onTeaser={() => {
          let _ = TeaserManager.startAutoTeaser(sceneSlice.tourName, false, "mp4", false)
        }}
      />

      <input
        type_="file"
        ref={ReactDOM.Ref.domRef(fileInputRef)}
        multiple=true
        accept="image/jpeg,image/png,image/webp"
        className="hidden"
        onChange={e => {
          let _ = handleUpload(e)
        }}
      />
      <input
        type_="file"
        ref={ReactDOM.Ref.domRef(projectFileInputRef)}
        accept=".vt.zip,.zip"
        className="hidden"
        onChange={e => {
          let _ = handleLoadProject(e)
        }}
      />
    </div>

    <SidebarProjectInfo
      localTourName
      onTourNameChange={e => {
        let val = JsxEvent.Form.target(e)["value"]
        setLocalTourName(_ => val)
      }}
      onUploadClick={() => {
        switch Nullable.toOption(fileInputRef.current) {
        | Some(el) => Dom.click(el)
        | None => ()
        }
      }}
    />

    <SidebarProcessing procState />

    <div
      className="sidebar-content flex-1 overflow-y-auto overflow-x-hidden custom-scrollbar flex flex-col bg-slate-50/50"
    >
      <div className="p-1 flex-1">
        <SceneList />
      </div>
    </div>
  </div>
})
