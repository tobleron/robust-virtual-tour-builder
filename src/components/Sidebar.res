/* src/components/Sidebar.res - Consolidated Sidebar Module */

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

module SidebarLogic = {
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
              EventBus.dispatch(ShowNotification("Load failed: " ++ msg, #Error))
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

  /* handleSave and handleExport are moved or updated elsewhere if needed */

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
}

module SidebarBranding = {
  @react.component
  let make = React.memo(() => {
    React.useEffect0(() => {
      Logger.initialized(~module_="SidebarBranding")
      None
    })

    <div className="flex flex-col items-center px-6 pt-6 pb-6">
      <div className="flex items-center justify-center gap-3 mb-1">
        <h1 className="font-heading font-semibold text-white tracking-widest uppercase text-[27px]">
          {React.string("ROBUST")}
        </h1>
        <LucideIcons.Home className="text-white text-[45px]" size=45 />
      </div>
      <div className="font-normal text-white tracking-[0.25em] text-[13px] uppercase">
        {React.string("Virtual Tour Builder")}
      </div>
      <div
        className="flex items-center gap-2 text-white mt-1 sidebar-version-line font-normal font-mono"
      >
        <span className="text-[10px] tracking-wider">
          {React.string("V " ++ VersionData.version)}
        </span>
        <span className="text-[10px]"> {React.string("\u2022")} </span>
        <span className="text-[10px]"> {React.string(VersionData.buildInfo)} </span>
      </div>
    </div>
  })
}

module SidebarActions = {
  @react.component
  let make = React.memo((
    ~onNew,
    ~onSave,
    ~onLoad,
    ~onAbout,
    ~onExport,
    ~onTeaser,
    ~exportReady,
    ~teaserReady,
  ) => {
    React.useEffect0(() => {
      Logger.initialized(~module_="SidebarActions")
      None
    })

    <div className="px-5 pb-6">
      <div className="grid grid-cols-4 gap-2 mb-3">
        {[
          ("file-plus", "New", onNew),
          ("save", "Save", onSave),
          ("folder-open", "Load", onLoad),
          ("info", "About", onAbout),
        ]
        ->Belt.Array.mapWithIndex((i, (icon, label, onClick)) =>
          <button
            key={Int.toString(i)}
            className="sidebar-action-btn-square hover-lift active-push group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/50"
            onClick={_ => onClick()}
            ariaLabel={label}
          >
            {switch icon {
            | "file-plus" => <LucideIcons.FilePlus size=20 strokeWidth=1.0 />
            | "save" => <LucideIcons.Save size=20 strokeWidth=1.0 />
            | "folder-open" => <LucideIcons.FolderOpen size=20 strokeWidth=1.0 />
            | "info" => <LucideIcons.Info size=20 strokeWidth=1.0 />
            | _ => React.null
            }}
            <span> {React.string(label)} </span>
          </button>
        )
        ->React.array}
      </div>

      <div className="grid grid-cols-2 gap-2">
        <button
          className="sidebar-action-btn-wide hover-lift active-push group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/50"
          disabled={!exportReady}
          onClick={_ => onExport()}
          ariaLabel="Export Tour"
        >
          <LucideIcons.Download
            className="text-white transition-all duration-300" size=20 strokeWidth=1.0
          />
          <span> {React.string("Export")} </span>
        </button>

        <button
          className="sidebar-action-btn-wide hover-lift active-push group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/50"
          disabled={!teaserReady}
          onClick={_ => onTeaser()}
          ariaLabel="Create Teaser"
        >
          <LucideIcons.Film
            className="text-white transition-all duration-300" size=20 strokeWidth=1.0
          />
          <span> {React.string("Teaser")} </span>
        </button>
      </div>
    </div>
  })
}

module SidebarProjectInfo = {
  @react.component
  let make = React.memo((~localTourName, ~onTourNameChange, ~onUploadClick) => {
    React.useEffect0(() => {
      Logger.initialized(~module_="SidebarProjectInfo")
      None
    })

    <div className="flex flex-col bg-white border-b border-slate-200 shrink-0 z-20">
      <div className="flex items-stretch gap-3 p-4 pb-2">
        <button
          className="w-14 h-auto min-h-14 flex flex-col items-center justify-center gap-1 rounded-xl transition-all hover:brightness-110 hover:shadow-lg hover-lift active-push group overflow-hidden relative focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:outline-none sidebar-upload-btn shrink-0 text-white"
          onClick={_ => onUploadClick()}
        >
          <div
            className="absolute inset-0 bg-gradient-to-b from-transparent via-white/10 to-transparent translate-x-[-150%] translate-y-[-150%] rotate-45 group-hover:translate-x-[150%] group-hover:translate-y-[150%] transition-transform duration-1000"
          />
          <LucideIcons.Camera className="text-white" size=24 strokeWidth=2.0 />
          <span
            className="text-[10px] font-semibold tracking-widest uppercase writing-vertical-lr hidden"
          >
            {React.string("Add")}
          </span>
        </button>

        <div className="flex-1 flex flex-col justify-center gap-1.5">
          <label className="sidebar-project-label" htmlFor="project-name-input">
            {React.string("Project Name")}
          </label>
          <input
            id="project-name-input"
            type_="text"
            className="sidebar-project-input"
            placeholder="New Tour..."
            value={localTourName}
            onChange={onTourNameChange}
          />
        </div>
      </div>
    </div>
  })
}

module SidebarProcessing = {
  external makeStyle: {..} => ReactDOM.Style.t = "%identity"

  @react.component
  let make = React.memo((~procState: SidebarTypes.processingPayload) => {
    React.useEffect0(() => {
      Logger.initialized(~module_="SidebarProcessing")
      None
    })

    if procState["active"] {
      <div
        className="mx-4 mb-3 bg-slate-50 border border-slate-200 rounded-xl p-3 shadow-sm animate-fade-in"
        role="status"
        ariaLive=#polite
      >
        <div className="flex items-center justify-between mb-2">
          <div className="flex items-center gap-2">
            <div className="spinner !w-3 !h-3 !border-2" />
            <div className="font-semibold text-slate-700 text-[10px] uppercase tracking-widest">
              {React.string(procState["phase"] == "" ? "Processing" : procState["phase"])}
            </div>
          </div>
          <div className="font-heading font-semibold text-primary text-[11px]">
            {React.string(Float.toFixed(procState["progress"], ~digits=0) ++ "%")}
          </div>
        </div>
        <div className="bg-slate-200 h-1.5 rounded-full overflow-hidden relative">
          <div
            className="h-full transition-all duration-300 rounded-full sidebar-progress-fill"
            style={makeStyle({"width": Float.toFixed(procState["progress"], ~digits=0) ++ "%"})}
          />
        </div>
        {
          let parts = String.split(procState["message"], "|")
          let leftPart = Belt.Array.get(parts, 0)->Option.getOr(procState["message"])
          let rightPart = Belt.Array.get(parts, 1)->Option.getOr("")

          <div
            className="text-[10px] text-slate-500 mt-2 font-semibold uppercase tracking-tight flex items-center justify-between gap-2"
          >
            <div className="flex items-center gap-2 min-w-0">
              <span className="w-1 h-1 bg-success rounded-full animate-pulse shrink-0" />
              <span className="truncate"> {React.string(leftPart)} </span>
            </div>
            {if rightPart != "" {
              <span className="text-slate-400 truncate max-w-[50%]"> {React.string(rightPart)} </span>
            } else {
              React.null
            }}
          </div>
        }
      </div>
    } else {
      React.null
    }
  })
}

open ReBindings
open SidebarLogic

@scope(("window", "location")) @val external reload: unit => unit = "reload"

@react.component
let make = React.memo(() => {
  let state = AppContext.useAppState()
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
    Logger.initialized(~module_="Sidebar")

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

  let totalHotspots =
    sceneSlice.scenes->Belt.Array.reduce(0, (acc, s) => acc + Array.length(s.hotspots))
  let teaserReady = totalHotspots >= 3
  let exportReady = totalHotspots > 0

  let handleSave = async (state: Types.state) => {
    SidebarLogic.updateProgress(0.0, "Saving...", true, "Save")
    try {
      let _ = await ProjectManager.saveProject(state, ~onProgress=(pct, _t, msg) => {
        SidebarLogic.updateProgress(pct->Int.toFloat, msg, true, "Save")
      })
      SidebarLogic.updateProgress(100.0, "Saved", false, "")
    } catch {
    | _ => SidebarLogic.updateProgress(0.0, "Error", false, "")
    }
  }

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
                    class_: "bg-red-500/20 text-white hover:bg-red-500/40",
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
          let _ = handleSave(state)
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
          let _ = handleExport(sceneSlice.scenes)
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
          let target = JsxEvent.Form.target(e)->Dom.unsafeToElement
          let _ = handleUpload(Dom.getFiles(target))
        }}
      />
      <input
        type_="file"
        ref={ReactDOM.Ref.domRef(projectFileInputRef)}
        accept=".vt.zip,.zip"
        className="hidden"
        onChange={e => {
          let target = JsxEvent.Form.target(e)->Dom.unsafeToElement
          let _ = handleLoadProject(
            Dom.getFiles(target),
            dispatch,
            Array.length(sceneSlice.scenes),
            target,
          )
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
