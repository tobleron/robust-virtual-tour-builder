// @efficiency-role: ui-component

@scope(("window", "location")) @val external reload: unit => unit = "reload"

@react.component
let make = React.memo(() => {
  let sceneSlice = AppContext.useSceneSlice()
  let uiSlice = AppContext.useUiSlice()
  let dispatch = AppContext.useAppDispatch()
  let getState = AppContext.getBridgeState

  let (procState, fileInputRef) = UseSidebarProcessing.useSidebarProcessing()
  let projectFileInputRef = React.useRef(Nullable.null)

  let (localTourName, setLocalTourName) = React.useState(() => sceneSlice.tourName)
  let expectedTourName = React.useRef(sceneSlice.tourName)

  React.useEffect2(() => {
    let actual = sceneSlice.tourName
    let local = localTourName
    let expected = expectedTourName.current

    if local == expected && actual != expected {
      Logger.debug(
        ~module_="Sidebar",
        ~message="SYNC_TOUR_NAME_FROM_STATE",
        ~data=Some({"actual": actual, "local": local, "expected": expected}),
        (),
      )
      setLocalTourName(_ => actual)
      expectedTourName.current = actual
    }
    None
  }, (sceneSlice.tourName, localTourName))

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

  React.useEffect0(() => {
    Logger.initialized(~module_="Sidebar")
    None
  })

  let totalHotspots =
    sceneSlice.scenes->Belt.Array.reduce(0, (acc, s) => acc + Array.length(s.hotspots))
  let teaserReady = totalHotspots >= 3
  let exportReady = totalHotspots > 0

  <div
    id="sidebar"
    className="relative w-[340px] min-w-[340px] bg-slate-50 flex flex-col z-[15000] shrink-0 h-full overflow-hidden font-ui"
  >
    <div className="relative w-full flex flex-col z-30 text-white shrink-0 sidebar-branding-header">
      <SidebarBranding />

      <SidebarActions
        exportReady
        teaserReady
        isLinking={uiSlice.isLinking}
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
        onSave={(~signal, ~onCancel) => {
          Logger.info(~module_="Sidebar", ~message="FORCE_STOP_LINKING_ON_SAVE", ())
          dispatch(Actions.StopLinking)
          SidebarLogic.handleSave(~getState, ~signal, ~onCancel, ~dispatch)
        }}
        onLoad={(~signal as _, ~onCancel as _) => {
          switch Nullable.toOption(projectFileInputRef.current) {
          | Some(el) => ReBindings.Dom.click(el)
          | None => ()
          }
          Promise.resolve()
        }}
        onAbout={() => {
          EventBus.dispatch(
            ShowModal({
              title: "About Builder",
              description: None,
              icon: Some("info"),
              content: Some(<SidebarAbout />),
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
        onExport={(~signal, ~onCancel) => {
          SidebarLogic.handleExport(
            sceneSlice.scenes,
            ~tourName=sceneSlice.tourName,
            ~dispatch,
            ~signal,
            ~onCancel,
          )
        }}
        onTeaser={() => {
          Teaser.startAutoTeaser("fast", false, "mp4", false, ~getState, ~dispatch)->ignore
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
          SidebarLogic.handleUpload(ReBindings.Dom.getFiles(target), ~getState, ~dispatch)->ignore
        }}
      />
      <input
        type_="file"
        ref={ReactDOM.Ref.domRef(projectFileInputRef)}
        accept=".vt.zip,.zip"
        className="hidden"
        onChange={e => {
          let target = JsxEvent.Form.target(e)->ReBindings.Dom.unsafeToElement
          SidebarLogic.handleLoadProject(
            ReBindings.Dom.getFiles(target),
            ~getState,
            ~dispatch,
            Array.length(sceneSlice.scenes),
            target,
          )->ignore
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
