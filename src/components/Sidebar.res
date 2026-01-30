// @efficiency-role: ui-component

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
    let timerId = ReBindings.Window.setTimeout(
      () => {
        if localTourName != sceneSlice.tourName {
          expectedTourName.current = localTourName
          dispatch(Actions.SetTourName(localTourName))
        }
      },
      300,
    )
    Some(() => ReBindings.Window.clearTimeout(timerId))
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
            ReBindings.Window.clearTimeout(timerId)
            hideTimerRef.current = Nullable.null
          | None => ()
          }

          setProcState(_ => payload)

          if payload["progress"] >= 100.0 && payload["active"] {
            let timerId = ReBindings.Window.setTimeout(
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
          | Some(el) => ReBindings.Dom.click(el)
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
                    {React.string(`Version: ${Version.version}`)}
                  </p>
                  <p className="text-slate-200 font-mono text-[10px]">
                    {React.string(`Build: ${Version.buildInfo}`)}
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
          let _ = SidebarLogic.handleExport(sceneSlice.scenes)
        }}
        onTeaser={() => {
          let _ = Teaser.startAutoTeaser("fast", false, "mp4", false)
        }}
      />

      <input
        type_="file"
        ref={ReactDOM.Ref.domRef(fileInputRef)}
        multiple=true
        accept="image/jpeg,image/png,image/webp"
        className="hidden"
        onChange={e => {
          let target = JsxEvent.Form.target(e)->ReBindings.Dom.unsafeToElement
          let _ = SidebarLogic.handleUpload(ReBindings.Dom.getFiles(target))
        }}
      />
      <input
        type_="file"
        ref={ReactDOM.Ref.domRef(projectFileInputRef)}
        accept=".vt.zip,.zip"
        className="hidden"
        onChange={e => {
          let target = JsxEvent.Form.target(e)->ReBindings.Dom.unsafeToElement
          let _ = SidebarLogic.handleLoadProject(
            ReBindings.Dom.getFiles(target),
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
        | Some(el) => ReBindings.Dom.click(el)
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
