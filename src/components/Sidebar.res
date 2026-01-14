/* src/components/Sidebar.res */

// Bindings
@module("../version.js") external version: string = "VERSION"
@module("../version.js") external buildInfo: string = "BUILD_INFO"
@module("../constants.js") external autoHideDelay: int = "PROGRESS_BAR_AUTO_HIDE_DELAY"
@scope(("window", "location")) @val external reload: unit => unit = "reload"

module ProjectManager = {
  @module("../systems/ProjectManager.js")
  external saveProject: (Types.state, (float, float, string) => unit) => promise<unit> =
    "saveProject"
  @module("../systems/ProjectManager.js")
  external loadProject: ('file, (float, float, string, bool) => unit) => promise<JSON.t> =
    "loadProject"
}

module TeaserSystem = {
  @module("../systems/TeaserSystem.js")
  external startAutoTeaser: (string, bool, string, bool) => unit = "startAutoTeaser"
}

// Local helper for style objects
external makeStyle: {..} => ReactDOM.Style.t = "%identity"

@react.component
let make = () => {
  let state = AppContext.useAppState()
  let dispatch = AppContext.useAppDispatch()

  // Processing UI state
  let (procState, setProcState) = React.useState(_ =>
    {
      "active": false,
      "progress": 0.0,
      "message": "System Ready",
      "phase": "",
      "error": false,
    }
  )

  // Inputs refs
  let fileInputRef = React.useRef(Nullable.null)
  let projectFileInputRef = React.useRef(Nullable.null)
  let hideTimerRef = React.useRef(Nullable.null)

  let updateProgress = (pct, msg, active, phase) => {
    // Clear any existing hide timer
    switch Nullable.toOption(hideTimerRef.current) {
    | Some(timerId) =>
      clearTimeout(timerId)
      hideTimerRef.current = Nullable.null
    | None => ()
    }

    setProcState(_ =>
      {
        "active": active,
        "progress": pct,
        "message": msg,
        "phase": phase,
        "error": false,
      }
    )

    // If progress is complete, start auto-hide timer
    if pct >= 100.0 && active {
      let timerId = setTimeout(() => {
        setProcState(prev => {
          let next = Object.assign(Object.make(), prev)
          next["active"] = false
          next
        })
        hideTimerRef.current = Nullable.null
      }, autoHideDelay)
      hideTimerRef.current = Nullable.fromOption(Some(timerId))
    }
  }

  // Handlers
  let handleUpload = async e => {
    let target = JsxEvent.Form.target(e)
    let files = target["files"]
    if files["length"] > 0 {
      // Conversion from FileList to Array needed?
      // External binding expects array. `Array.from(files)` in JS.
      // We can assume strict binding or do `Array.from` via binding.
      // Let's assume files is array-like and binding handles it or we bind Array.from
      // `UploadProcessor.processUploads` takes array.
      // Quick hack: Use `Array.from` binding

      // Legacy binding removed, using ReScript module directly
      let fileArray = (Obj.magic(files): array<UploadProcessor.file>)

      try {
        let result = await UploadProcessor.processUploads(
          fileArray,
          Some(
            (pct, msg, isProc, phase) => {
              updateProgress(pct, msg, isProc, phase)
            },
          ),
        )

        let resObj = (Obj.magic(result): {"qualityResults": JSON.t})

        // Dispatch the result to the store
        // Assuming result structure matches what AddScenes expects (array of scene data)
        // Scenes are dispatched by UploadProcessor
        // UploadReport.showExpects array<qualityItem>
        let qualityResults = (Obj.magic(resObj)["qualityResults"]: array<UploadReport.qualityItem>)
        UploadReport.show(state.lastUploadReport, qualityResults)
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
    }
  }

  // ... other handlers (Teaser, Export, etc.) mostly open modals via ModalManager

  // Computed
  let totalHotspots = state.scenes->Belt.Array.reduce(0, (acc, s) => acc + Array.length(s.hotspots))
  let teaserReady = totalHotspots >= 3
  let exportReady = totalHotspots > 0

  // Render
  <div
    className="relative w-[320px] min-w-[320px] bg-white flex flex-col z-[15000] shrink-0 h-full overflow-hidden font-ui shadow-2xl"
  >
    /* Branding Header */
    <div
      className="relative w-full flex flex-col z-30 text-white shrink-0"
      style={makeStyle({
        "borderTop": "2px solid #dc3545",
        "background": "linear-gradient(to bottom, #001a38 0%, #002a70 50%, #003da5 100%)",
      })}
    >
      <div
        className="flex flex-col items-center px-5 pb-4" style={makeStyle({"paddingTop": "23px"})}
      >
        <span
          className="material-icons text-white drop-shadow-lg mb-0.5 mt-1"
          style={makeStyle({"fontSize": "36px"})}
        >
          {React.string("home")}
        </span>
        <h1
          className="font-black text-white tracking-tight drop-shadow-sm text-center"
          style={makeStyle({"fontSize": "24px"})}
        >
          {React.string("Virtual Tour Builder")}
        </h1>
        <div className="flex items-center gap-2 text-white/50">
          <span className="text-[11px] font-bold"> {React.string("v" ++ version)} </span>
          <span className="text-[11px]"> {React.string("•")} </span>
          <span className="text-[11px] font-medium"> {React.string(buildInfo)} </span>
        </div>
      </div>

      <div style={makeStyle({"padding": "0 16px 14px 16px"})}>
        // Grid 4x1 for main actions
        <div className="sidebar-btn-grid-4">
          <button
            className="sidebar-action-btn-square"
            title="New Project"
            onClick={_ => {
              if Array.length(state.scenes) > 0 {
                EventBus.dispatch(ShowModal({
                  title: "Create New Project?",
                  description: Some(
                    "Are you sure you want to discard the current project? All unsaved progress will be lost.",
                  ),
                  icon: Some("warning"),
                  contentHtml: None,
                  onClose: None,
                  allowClose: Some(true),
                  buttons: [
                    {
                      label: "Cancel",
                      class_: "bg-slate-100 text-slate-700 hover:bg-slate-200",
                      onClick: () => (),
                      autoClose: Some(true),
                    },
                    {
                      label: "Discard & New",
                      class_: "bg-red-500 text-white hover:bg-red-600",
                      onClick: () => reload(),
                      autoClose: Some(true),
                    },
                  ],
                }))
              } else {
                Logger.info(~module_="Sidebar", ~message="PROJECT_NEW", ())
                reload()
              }
            }}
          >
            <span className="material-icons"> {React.string("note_add")} </span>
            <span> {React.string("New")} </span>
          </button>

          <button
            className="sidebar-action-btn-square"
            title="Save Project"
            onClick={_ => {
              let _ = (
                async () => {
                  updateProgress(0.0, "Saving Project...", true, "Saving")
                  Logger.info(~module_="Sidebar", ~message="PROJECT_SAVE", ~data={
                    "sceneCount": Array.length(state.scenes),
                    "tourName": state.tourName
                  }, ())
                  try {
                    let _ = await ProjectManager.saveProject(state, (pct, _total, msg) => {
                      updateProgress(pct, msg, true, "Saving")
                    })
                    EventBus.dispatch(ShowNotification("Project saved successfully", #Success))
                    updateProgress(100.0, "Saved", false, "")
                  } catch {
                  | _ =>
                    Logger.error(~module_="Sidebar", ~message="PROJECT_SAVE_FAILED", ())
                    EventBus.dispatch(ShowNotification("Save failed", #Error))
                    updateProgress(0.0, "Error", false, "")
                  }
                }
              )()
            }}
          >
            <span className="material-icons"> {React.string("save")} </span>
            <span> {React.string("Save")} </span>
          </button>

          <button
            className="sidebar-action-btn-square"
            title="Load Project"
            onClick={_ => {
              // Trigger hidden file input
              let input = projectFileInputRef.current
              switch Nullable.toOption(input) {
              | Some(el) =>
                let domEl = (Obj.magic(el): {"click": unit => unit})
                domEl["click"]()
              | None => ()
              }
            }}
          >
            <span className="material-icons"> {React.string("folder_open")} </span>
            <span> {React.string("Load")} </span>
          </button>

          <button
            className="sidebar-action-btn-square group"
            title="About"
            onClick={_ => {
              EventBus.dispatch(ShowModal({
                title: "About Virtual Tour Builder",
                description: Some(`Version: ${version}<br>Build: ${buildInfo}`),
                icon: Some("info"),
                contentHtml: None,
                onClose: None,
                allowClose: Some(true),
                buttons: [
                  {
                    label: "Close",
                    class_: "bg-slate-100 text-slate-700",
                    onClick: () => (),
                    autoClose: Some(true),
                  },
                ],
              }))
            }}
          >
            <span className="material-icons group-hover:scale-110 transition-transform">
              {React.string("info")}
            </span>
            <span> {React.string("About")} </span>
          </button>
        </div>

        // Grid 2x1 for secondary actions
        <div className="sidebar-btn-grid-2">
          <button
            className="sidebar-action-btn-wide"
            disabled={!exportReady}
            title="Export Tour"
            style={if !exportReady {
              makeStyle({"opacity": "0.4"})
            } else {
              makeStyle(Object.make())
            }}
            onClick={_ => {
              let _ = (
                async () => {
                  updateProgress(0.0, "Initializing Export...", true, "Exporting")
                  try {
                    let _ = await Exporter.exportTour(
                      state.scenes,
                      Some((pct, _total, msg) => updateProgress(pct, msg, true, "Exporting")),
                    )
                    EventBus.dispatch(ShowNotification("Export complete!", #Success))
                    updateProgress(100.0, "Done", false, "")
                  } catch {
                  | _ =>
                    EventBus.dispatch(ShowNotification("Export failed", #Error))
                    updateProgress(0.0, "Error", false, "")
                  }
                }
              )()
            }}
          >
            <span className="material-icons" style={makeStyle({"color": "#10b981"})}>
              {React.string("ios_share")}
            </span>
            <span> {React.string("Export")} </span>
          </button>

          <button
            className="sidebar-action-btn-wide"
            disabled={!teaserReady}
            title={if teaserReady {
              "Auto-generate teaser video"
            } else {
              "Need at least 3 scenes"
            }}
            style={if !teaserReady {
              makeStyle({"opacity": "0.4"})
            } else {
              makeStyle(Object.make())
            }}
            onClick={_ => {
              TeaserSystem.startAutoTeaser(state.tourName, false, "mp4", false)
            }}
          >
            <span className="material-icons" style={makeStyle({"color": "#f97316"})}>
              {React.string("movie_creation")}
            </span>
            <span> {React.string("Teaser")} </span>
          </button>
        </div>
      </div>

      /* Hidden Inputs */
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
          let _ = (
            async () => {
              let target = JsxEvent.Form.target(e)
              let files = target["files"]
              if files["length"] > 0 {
                updateProgress(0.0, "Loading Project...", true, "Loading")
                try {
                  let file = files["0"]
                  Logger.startOperation(~module_="Sidebar", ~operation="PROJECT_LOAD", ~data={
                    "filename": Obj.magic(file)["name"],
                    "size": Obj.magic(file)["size"]
                  }, ())
                  let projectData = await ProjectManager.loadProject(file, (
                    pct,
                    _t,
                    msg,
                    active,
                  ) => {
                    updateProgress(pct, msg, active, "Loading")
                  })

                  dispatch(Actions.LoadProject(projectData))
                  
                  Logger.endOperation(~module_="Sidebar", ~operation="PROJECT_LOAD", ~data={
                    "sceneCount": Array.length(state.scenes)
                  }, ())

                  EventBus.dispatch(ShowNotification("Project loaded", #Success))
                  updateProgress(100.0, "Loaded", false, "")
                } catch {
                | JsExn(obj) =>
                  let msg = switch JsExn.message(obj) {
                  | Some(m) => m
                  | None => "Unknown error"
                  }
                  Logger.error(~module_="Sidebar", ~message="PROJECT_LOAD_FAILED", ~data={"error": msg}, ())
                  EventBus.dispatch(ShowNotification("Load failed: " ++ msg, #Error))
                  updateProgress(0.0, "Error", false, "")
                | _ =>
                  Logger.error(~module_="Sidebar", ~message="PROJECT_LOAD_FAILED", ~data={"error": "Unknown"}, ())
                  EventBus.dispatch(ShowNotification("Load failed", #Error))
                  updateProgress(0.0, "Error", false, "")
                }
                // Reset input
                target["value"] = ""
              }
            }
          )()
        }}
      />
    </div>

    /* Project Name & Upload Section - FIXED at top, outside scrollable area */
    <div className="flex flex-col bg-slate-50 border-b border-slate-200 shadow-sm shrink-0 z-20">
      <div className="p-4 pt-5 pb-3">
        <div className="flex items-center justify-between mb-1.5 px-1">
          <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest">
            {React.string("Project Name")}
          </label>
          <span className="text-[9px] font-bold text-remax-blue/60 uppercase">
            {React.string("Draft Mode")}
          </span>
        </div>
        <input
          type_="text"
          id="tour-name-input"
          className="w-full px-3 h-10 bg-white border border-slate-200 rounded-lg font-ui font-medium text-[14px] text-slate-700 focus:outline-none focus:ring-2 focus:ring-remax-blue/10 focus:border-remax-blue transition-all truncate shadow-sm placeholder:text-slate-300"
          placeholder="Tour Name..."
          value={state.tourName}
          onChange={e => {
            let val = JsxEvent.Form.target(e)["value"]
            dispatch(Actions.SetTourName(val))
          }}
        />
      </div>

      <div
        className="px-4 pb-4"
        style={makeStyle({
          "display": if procState["active"] {
            "none"
          } else {
            "block"
          },
        })}
      >
        <label
          id="upload-label"
          className="w-full h-10 bg-white border border-slate-200 rounded-lg flex items-center justify-center gap-2.5 cursor-pointer transition-all hover:bg-remax-blue hover:text-white hover:border-remax-blue hover:shadow-lg hover:shadow-remax-blue/20 group active:scale-95 shadow-sm overflow-hidden"
          onClick={_ => {
            let input = fileInputRef.current
            switch Nullable.toOption(input) {
            | Some(el) => Obj.magic(el)["click"]()
            | None => ()
            }
          }}
        >
          <div
            className="w-6 h-6 rounded-full bg-remax-blue/10 flex items-center justify-center group-hover:bg-white/20 transition-colors"
          >
            <span
              className="material-icons text-[15px] text-remax-blue group-hover:text-white transition-colors"
            >
              {React.string("cloud_upload")}
            </span>
          </div>
          <strong
            className="text-[11px] font-bold tracking-tight text-slate-600 group-hover:text-white"
          >
            {React.string("Upload 360 Images")}
          </strong>
        </label>
      </div>
    </div>

    /* Sidebar Content Area - Scrollable */
    <div
      className="sidebar-content flex-1 overflow-y-auto overflow-x-hidden hide-scrollbar flex flex-col bg-white"
    >
      /* Processing UI Card - Inside scrollable area */

      {if procState["active"] {
        <div
          className="m-4 bg-white border border-slate-100 rounded-xl p-4 shadow-xl ring-1 ring-remax-blue/5 animate-fade-in shrink-0"
        >
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-2">
              <div
                className="w-3 h-3 border-2 border-slate-100 border-t-remax-blue rounded-full animate-spin"
              >
              </div>
              <div className="font-bold text-remax-blue text-[10px] uppercase tracking-wide">
                {React.string(procState["phase"] == "" ? "Processing" : procState["phase"])}
              </div>
            </div>
            <div className="font-black text-remax-blue text-xs font-heading">
              {React.string(Float.toString(procState["progress"]) ++ "%")}
            </div>
          </div>
          <div className="bg-slate-100 h-1.5 rounded-full overflow-hidden relative">
            <div
              className="h-full bg-remax-blue transition-all duration-300 rounded-full relative"
              style={makeStyle({"width": Float.toString(procState["progress"]) ++ "%"})}
            >
              <div
                className="absolute inset-0 bg-gradient-to-r from-transparent via-white/30 to-transparent animate-shimmer bg-[length:200%_auto]"
              >
              </div>
            </div>
          </div>
          <div
            className="text-[9px] text-slate-400 mt-2 font-bold uppercase tracking-tighter flex items-center gap-1.5"
          >
            <span className="w-1 h-1 bg-success rounded-full animate-pulse"></span>
            <span className="truncate"> {React.string(procState["message"])} </span>
          </div>
        </div>
      } else {
        React.null
      }}

      <div id="scene-list-container" className="p-3 pt-4 flex-1">
        <SceneList />
      </div>
    </div>
  </div>
}
