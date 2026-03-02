// @efficiency-role: ui-component

@scope(("window", "location")) @val external reload: unit => unit = "reload"

@react.component
let make = React.memo(() => {
  let sceneSlice = AppContext.useSceneSlice()
  let uiSlice = AppContext.useUiSlice()
  let canUpload = Capability.useCapability(CanUpload)
  let dispatch = AppContext.useAppDispatch()
  let getState = AppContext.getBridgeState

  let fileInputRef = React.useRef(Nullable.null)
  let projectFileInputRef = React.useRef(Nullable.null)

  let (localTourName, setLocalTourName) = UseSidebarProcessing.useTourNameSync(sceneSlice, dispatch)
  let procState = UseSidebarProcessing.useProcessingState(fileInputRef)

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
          // Unconditionally stop linking to ensure visual artifacts (yellow lines) are cleared
          Logger.info(~module_="Sidebar", ~message="FORCE_STOP_LINKING_ON_SAVE", ())
          dispatch(Actions.StopLinking)
          UseSidebarProcessing.handleSave(~getState, ~signal, ~onCancel, ~dispatch)
        }}
        onLoad={(~signal as _, ~onCancel as _) => {
          switch Nullable.toOption(projectFileInputRef.current) {
          | Some(el) => ReBindings.Dom.click(el)
          | None => ()
          }
          Promise.resolve()
        }}
        onSettings={() => {
          EventBus.dispatch(
            ShowModal({
              title: "Settings",
              description: None,
              icon: Some("info"),
              content: Some(<SidebarSettings />),
              onClose: None,
              allowClose: Some(true),
              className: Some("modal-blue modal-settings-panel"),
              buttons: [],
            }),
          )
        }}
        onExport={(~signal, ~onCancel) => {
          let state = getState()
          SidebarLogic.handleExport(
            sceneSlice.scenes,
            ~tourName=state.tourName,
            ~projectData=ProjectSystem.encodeProjectFromState(state),
            ~dispatch,
            ~signal,
            ~onCancel,
          )
        }}
        onTeaser={(~format, ~styleId, ~signal, ~onCancel) => {
          // Seed the progress bar cancel callback so clicking "Cancel" aborts the signal.
          SidebarLogic.updateProgress(
            ~dispatch,
            ~onCancel,
            0.0,
            "Preparing teaser...",
            true,
            "Teaser",
          )
          FeatureLoaders.startTeaserLazy(
            format,
            Some(styleId),
            getState,
            dispatch,
            Some(signal),
            Some(onCancel),
          )
        }}
      />

      <input
        type_="file"
        ref={ReactDOM.Ref.domRef(fileInputRef)}
        multiple=true
        accept="image/jpeg,image/png,image/webp"
        className="hidden"
        id="sidebar-image-upload"
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
        id="sidebar-project-upload"
        onChange={e => {
          let target = JsxEvent.Form.target(e)->ReBindings.Dom.unsafeToElement
          SidebarLogic.handleLoadProject(
            ReBindings.Dom.getFiles(target),
            ~getState,
            ~dispatch, // This now uses queue-aware dispatch!
            Array.length(sceneSlice.scenes),
            target,
          )->ignore
        }}
      />
    </div>

    <SidebarProjectInfo
      localTourName
      disabled={!canUpload || sceneSlice.discoveringTitleCount > 0}
      onTourNameChange={e => {
        let val = JsxEvent.Form.target(e)["value"]
        setLocalTourName(_ => val)
      }}
      onUploadClick={() => {
        if canUpload {
          switch Nullable.toOption(fileInputRef.current) {
          | Some(el) => ReBindings.Dom.click(el)
          | None => ()
          }
        } else {
          Logger.debug(~module_="Sidebar", ~message="UPLOAD_TRIGGER_REJECTED_LOCK_HELD", ())
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
