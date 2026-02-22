open Types
open ReBindings

module InnerApp = {
  module HeadlessWindow = {
    type t
    @val external window: t = "window"
    @set external setLoadProject: (t, JSON.t => unit) => unit = "__VTB_LOAD_PROJECT__"
  }

  @react.component
  let make = () => {
    PerfUtils.useRenderBudget("InnerApp")
    let state = AppContext.useAppState()
    let dispatch = AppContext.useAppDispatch()
    let isSystemLocked = Capability.useIsSystemLocked()
    let isExporting = switch state.appMode {
    | SystemBlocking(Exporting(_)) => true
    | _ => false
    }

    React.useEffect1(() => {
      Logger.info(
        ~module_="App",
        ~message="SYSTEM_LOCKED_STATUS: " ++ (isSystemLocked ? "LOCKED" : "UNLOCKED"),
        (),
      )
      None
    }, [isSystemLocked])

    React.useEffect1(() => {
      let bodyClasses = Dom.classList(Dom.documentBody)
      if isExporting {
        bodyClasses->Dom.ClassList.add("export-mode")
      } else {
        bodyClasses->Dom.ClassList.remove("export-mode")
      }
      None
    }, [isExporting])

    React.useEffect0(() => {
      Logger.info(~module_="App", ~message="InnerApp Mounted - DISPATCHING_INIT_COMPLETE", ())
      dispatch(DispatchAppFsmEvent(InitializeComplete))
      None
    })

    React.useEffect1(() => {
      let _ = %raw("((s) => { window.__RE_STATE__ = s })(state)")
      None
    }, [state])

    React.useEffect0(() => {
      let _ = %raw("(isBusyFn, evaluateFn) => { 
        window.OperationLifecycle = { 
          isBusy: (opts) => {
            const t = opts ? opts.type : undefined;
            const s = opts ? opts.scope : undefined;
            return isBusyFn(t, s, undefined);
          }
        };
        window.Capability = { 
          evaluate: (opts) => {
             return evaluateFn(opts.capability, opts.appMode, opts.operations);
          }
        };
      }")(OperationLifecycle.isBusy, Capability.Policy.evaluate)
      None
    })

    React.useEffect1(() => {
      let loadProjectFn = data => dispatch(Actions.LoadProject(data))
      HeadlessWindow.setLoadProject(HeadlessWindow.window, loadProjectFn)
      None
    }, [dispatch])

    <div className="flex h-screen w-screen overflow-hidden bg-slate-900">
      <OfflineBanner />
      {if isSystemLocked {
        <div className="interaction-lock-overlay">
          <div className="spinner" />
        </div>
      } else {
        React.null
      }}

      <Sidebar />

      <main
        id="viewer-container"
        role="main"
        className={`viewer-main-container relative w-full h-full overflow-hidden select-none touch-none ${state.isLinking
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

          <div id="viewer-scene-elements-layer">
            <ViewerSceneElements />
          </div>

          /* Viewer UI Layer */
          <div id="viewer-ui-layer">
            <ViewerUI />
            <VisualPipeline />
          </div>
        </div>

        {if Belt.Array.length(state.scenes) == 0 {
          <div id="placeholder-text" className="viewer-placeholder" ariaLive=#polite>
            <h3> {React.string("Ready to build.")} </h3>
          </div>
        } else {
          React.null
        }}

        /* Modal & Notification Containers */
        <div id="modal-container">
          <ModalContext />
          <RecoveryCheck />
          <CriticalErrorMonitor />
        </div>
      </main>

      /* Logic Controllers */
      <Navigation.Controller />
      <ViewerManager />
      <Simulation />
      <ThumbnailProjectSystem />
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
