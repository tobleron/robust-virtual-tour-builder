/* src/components/Sidebar.res */

open ReBindings

// Bindings
// VersionData is accessed natively
let autoHideDelay = Constants.progressBarAutoHideDelay
@scope(("window", "location")) @val external reload: unit => unit = "reload"

// Local helper for style objects
external makeStyle: {..} => ReactDOM.Style.t = "%identity"

@react.component
let make = () => {
  let state = AppContext.useAppState()
  let dispatch = AppContext.useAppDispatch()

  // Inputs refs
  let fileInputRef = React.useRef(Nullable.null)
  let projectFileInputRef = React.useRef(Nullable.null)

  // Processing UI state
  let (procState, setProcState) = React.useState(_ =>
    {
      "active": false,
      "progress": 0.0,
      "message": "",
      "phase": "",
      "error": false,
    }
  )
  let hideTimerRef = React.useRef(Nullable.null)

  // Subscribe to processing updates
  React.useEffect0(() => {
    let unsubscribe = EventBus.subscribe(event => {
      switch event {
      | UpdateProcessing(payload) =>
        // Clear any existing hide timer
        switch Nullable.toOption(hideTimerRef.current) {
        | Some(timerId) =>
          clearTimeout(timerId)
          hideTimerRef.current = Nullable.null
        | None => ()
        }

        setProcState(_ => payload)

        // If progress is complete, start auto-hide timer
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
    })
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

  // Handlers
  let handleUpload = async e => {
    let target = JsxEvent.Form.target(e)
    let files = target["files"]
    if files["length"] > 0 {
      let fileArray = JsHelpers.from(files)

      try {
        let result = await UploadProcessor.processUploads(
          fileArray,
          Some(
            (pct, msg, isProc, phase) => {
              updateProgress(pct, msg, isProc, phase)
            },
          ),
        )

        let qualityResults: array<UploadReport.qualityItem> = (
          Obj.magic(result): {"qualityResults": array<UploadReport.qualityItem>}
        )["qualityResults"]

        let report: Types.uploadReport = (
          Obj.magic(result): {"report": Types.uploadReport}
        )["report"]

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
    }
  }

  // Computed
  let totalHotspots = state.scenes->Belt.Array.reduce(0, (acc, s) => acc + Array.length(s.hotspots))
  let teaserReady = totalHotspots >= 3
  let exportReady = totalHotspots > 0

  // Render
  <div
    className="relative w-[340px] min-w-[340px] bg-slate-50 flex flex-col z-[15000] shrink-0 h-full overflow-hidden font-ui shadow-2xl"
  >
    /* Branding Header */
    <div
      className="relative w-full flex flex-col z-30 text-white shrink-0 border-t-2 border-danger sidebar-branding-header"
    >
      <div className="flex flex-col items-center px-6 pt-6 pb-6">
        <div className="flex items-center justify-center gap-3 mb-1">
          <h1
            className="font-heading font-black text-white tracking-widest uppercase text-[27px] drop-shadow-lg"
          >
            {React.string("ROBUST")}
          </h1>
          <LucideIcons.Home className="text-white drop-shadow-lg text-[45px]" size=45 />
        </div>
        <div
          className="font-normal text-white tracking-[0.25em] text-[13px] uppercase drop-shadow-sm"
        >
          {React.string("Virtual Tour Builder")}
        </div>
        <div className="flex items-center gap-2 text-white mt-1 sidebar-version-line">
          <span className="text-[9px] font-mono tracking-wider">
            {React.string("V " ++ VersionData.version)}
          </span>
          <span className="text-[9px]"> {React.string("\u2022")} </span>
          <span className="text-[9px] font-mono">
            {React.string(VersionData.buildInfo)}
          </span>
        </div>
      </div>

      <div className="px-5 pb-6">
        // Grid 4x1 for main actions
        <div className="grid grid-cols-4 gap-2 mb-3">
          {[
            (
              "file-plus",
              "New",
              () => {
                if Array.length(state.scenes) > 0 {
                  EventBus.dispatch(
                    ShowModal({
                      title: "Create New Project?",
                      description: Some(
                        "Are you sure you want to discard the current project? All progress will be lost.",
                      ),
                      icon: Some("warning"),
                      contentHtml: None,
                      onClose: None,
                      allowClose: Some(true),
                      buttons: [
                        {
                          label: "Cancel",
                          class_: "bg-slate-100 text-slate-700",
                          onClick: () => (),
                          autoClose: Some(true),
                        },
                        {
                          label: "Discard & New",
                          class_: "bg-danger text-white",
                          onClick: () => reload(),
                          autoClose: Some(true),
                        },
                      ],
                    }),
                  )
                } else {
                  reload()
                }
              },
            ),
            (
              "save",
              "Save",
              () => {
                let _ = (
                  async () => {
                    updateProgress(0.0, "Saving...", true, "Saving")
                    try {
                      let _ = await ProjectManager.saveProject(state, ~onProgress=(pct, _, msg) =>
                        updateProgress(pct->Int.toFloat, msg, true, "Saving")
                      )
                      EventBus.dispatch(ShowNotification("Project saved", #Success))
                      updateProgress(100.0, "Saved", false, "")
                    } catch {
                    | _ => updateProgress(0.0, "Error", false, "")
                    }
                  }
                )()
              },
            ),
            (
              "folder-open",
              "Load",
              () => {
                switch Nullable.toOption(projectFileInputRef.current) {
                | Some(el) => Dom.click(el)
                | None => ()
                }
              },
            ),
            (
              "info",
              "About",
              () => {
                EventBus.dispatch(
                  ShowModal({
                    title: "About Builder",
                    description: Some(
                      `Version: ${VersionData.version}<br>Build: ${VersionData.buildInfo}`,
                    ),
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
                  }),
                )
              },
            ),
          ]
          ->Belt.Array.mapWithIndex((i, (icon, label, onClick)) =>
            <button
              key={Int.toString(i)}
              className="sidebar-action-btn-square hover-lift active-push group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/50"
              onClick={_ => onClick()}
              ariaLabel={label}
            >
              {switch icon {
              | "file-plus" => <LucideIcons.FilePlus />
              | "save" => <LucideIcons.Save />
              | "folder-open" | "folder_open" => <LucideIcons.FolderOpen />
              | "info" => <LucideIcons.Info />
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
            onClick={_ => {
              let _ = (
                async () => {
                  updateProgress(0.0, "Exporting...", true, "Export")
                  try {
                    let exportResult = await Exporter.exportTour(
                      state.scenes,
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
            ariaLabel="Export Tour"
          >
            <LucideIcons.Share2
              className="text-lg text-white group-hover:scale-110 transition-transform"
            />
            <span> {React.string("Export")} </span>
          </button>

          <button
            className="sidebar-action-btn-wide hover-lift active-push group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/50"
            disabled={!teaserReady}
            onClick={_ => {
              let _ = TeaserManager.startAutoTeaser(state.tourName, false, "mp4", false)
            }}
            ariaLabel="Create Teaser"
          >
            <LucideIcons.Film
              className="text-lg text-white group-hover:scale-110 transition-transform"
            />
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
                  | Ok(projectData) => {
                      dispatch(Actions.LoadProject(projectData))

                      Logger.endOperation(
                        ~module_="Sidebar",
                        ~operation="PROJECT_LOAD",
                        ~data={
                          "sceneCount": Array.length(state.scenes),
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
                // Reset input
                target["value"] = ""
              }
            }
          )()
        }}
      />
    </div>

    /* Project Name & Upload Section */
    <div className="flex flex-col bg-white border-b border-slate-200 shadow-sm shrink-0 z-20">
      <div className="p-4 pb-3">
        <div className="flex items-center justify-between mb-2 px-1">
          <label
            className="text-[10px] font-black text-slate-600 uppercase tracking-widest"
            htmlFor="project-name-input"
          >
            {React.string("Project Name")}
          </label>
          <div
            className="flex items-center gap-1.5 px-2 py-0.5 rounded-full bg-slate-100 border border-slate-200"
          >
            <div className="w-1 h-1 rounded-full bg-blue-500 animate-pulse" />
            <span className="text-[9px] font-bold text-slate-500 uppercase tracking-tight">
              {React.string("Draft")}
            </span>
          </div>
        </div>
        <input
          id="project-name-input"
          type_="text"
          className="sidebar-project-input"
          placeholder="New Tour..."
          value={state.tourName}
          onChange={e => dispatch(Actions.SetTourName(JsxEvent.Form.target(e)["value"]))}
        />
      </div>

      /* Sidebar Processing UI (Below Project Name) */
      {if procState["active"] {
        <div
          className="mx-4 mb-4 bg-slate-50 border border-slate-200 rounded-xl p-3 shadow-sm animate-fade-in"
          role="status"
          ariaLive=#polite
        >
          <div className="flex items-center justify-between mb-2">
            <div className="flex items-center gap-2">
              <div className="spinner !w-3 !h-3 !border-2" />
              <div className="font-bold text-slate-700 text-[10px] uppercase tracking-widest">
                {React.string(procState["phase"] == "" ? "Processing" : procState["phase"])}
              </div>
            </div>
            <div className="font-heading font-black text-primary text-[11px]">
              {React.string(Float.toFixed(procState["progress"], ~digits=0) ++ "%")}
            </div>
          </div>
          <div className="bg-slate-200 h-1.5 rounded-full overflow-hidden relative">
            <div
              className="h-full transition-all duration-300 rounded-full sidebar-progress-fill"
              // EXCEPTION: Dynamic progress percentage (CSS_ARCHITECTURE.md §3.1)
              // Value updates continuously during upload/processing
              style={makeStyle({"width": Float.toFixed(procState["progress"], ~digits=0) ++ "%"})}
            />
          </div>
          <div
            className="text-[9px] text-slate-500 mt-2 font-bold uppercase tracking-tight flex items-center gap-2"
          >
            <span className="w-1 h-1 bg-success rounded-full animate-pulse" />
            <span className="truncate"> {React.string(procState["message"])} </span>
          </div>
        </div>
      } else {
        React.null
      }}

      <div className="px-4 pb-4">
        <button
          className="w-full h-10 text-white rounded-xl flex items-center justify-center gap-2 transition-all hover:brightness-110 hover:shadow-xl hover-lift active-push group overflow-hidden relative focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:outline-none sidebar-upload-btn"
          onClick={_ => {
            switch Nullable.toOption(fileInputRef.current) {
            | Some(el) => Dom.click(el)
            | None => ()
            }
          }}
        >
          <div
            className="absolute inset-0 bg-gradient-to-r from-transparent via-white/10 to-transparent translate-x-[-100%] group-hover:translate-x-[100%] transition-transform duration-700"
          />
          <LucideIcons.Camera className="text-[20px]" size=20 />
          <strong className="text-[11px] font-bold tracking-widest uppercase">
            {React.string("Add 360 Scenes")}
          </strong>
        </button>
      </div>
    </div>

    /* Sidebar Content Area - Scrollable */
    <div
      className="sidebar-content flex-1 overflow-y-auto overflow-x-hidden custom-scrollbar flex flex-col bg-slate-50/50"
    >
      <div className="p-1 flex-1">
        <SceneList />
      </div>
    </div>
  </div>
}
