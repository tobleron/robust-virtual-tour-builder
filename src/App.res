module InnerApp = {
  @react.component
  let make = () => {
    let state = AppContext.useAppState()
    let isSystemLocked = AppContext.useIsSystemLocked()

    React.useEffect1(() => {
      Logger.info(
        ~module_="App",
        ~message="SYSTEM_LOCKED_STATUS: " ++ (isSystemLocked ? "LOCKED" : "UNLOCKED"),
        (),
      )
      None
    }, [isSystemLocked])

    React.useEffect0(() => {
      Logger.info(~module_="App", ~message="InnerApp Mounted - DISPATCHING_INIT_COMPLETE", ())
      GlobalStateBridge.dispatch(DispatchAppFsmEvent(InitializeComplete))
      None
    })

    React.useEffect1(() => {
      let _ = %raw("((s) => { window.__RE_STATE__ = s })(state)")
      None
    }, [state])

    <div className="flex h-screen w-screen overflow-hidden bg-slate-900">
      {if isSystemLocked {
        <div className="interaction-lock-overlay" />
      } else {
        React.null
      }}

      <Sidebar />

      <main
        id="viewer-container"
        role="main"
        className={`viewer-main-container relative w-full h-full bg-black overflow-hidden select-none touch-none ${state.isLinking
            ? "linking-mode"
            : ""}`}
      >
        <div id="viewer-stage" className="relative w-full h-full">
          /* Panorama Layers */
          <div
            id="panorama-a"
            className="panorama-layer active"
            role="img"
            ariaLabel="Primary Panorama Viewer"
          />
          <div
            id="panorama-b"
            className="panorama-layer"
            role="img"
            ariaLabel="Secondary Panorama Viewer"
          />

          <div id="cursor-guide" ariaHidden=true />

          /* Viewer UI Layer */
          <div id="viewer-ui-layer">
            <ViewerUI />
          </div>
        </div>

        <VisualPipelineComponent />

        {if Belt.Array.length(state.scenes) == 0 {
          <div id="placeholder-text" className="viewer-placeholder" ariaLive=#polite>
            <h3> {React.string("Ready to build.")} </h3>
          </div>
        } else {
          React.null
        }}
      </main>

      /* Modal & Notification Containers */
      <div id="modal-container">
        <ModalContext />
        <NotificationContext />
        <NotificationLayer />
        <NotificationCenter />

        <RecoveryCheck />
        <CriticalErrorMonitor />
      </div>

      /* Logic Controllers */
      <Navigation.Controller />
      <ViewerManager />
      <Simulation />
    </div>
  }
}

@react.component
let make = (~initialState=?, ()) => {
  <AppContext.Provider ?initialState>
    <AppErrorBoundary>
      <Shadcn.Tooltip.Provider delayDuration=Constants.tooltipDelayDuration>
        <InnerApp />
      </Shadcn.Tooltip.Provider>
    </AppErrorBoundary>
  </AppContext.Provider>
}
