open Types
open ReBindings

module InnerApp = {
  module HeadlessWindow = {
    type t
    @val external window: t = "window"
    @set external setLoadProject: (t, JSON.t => unit) => unit = "__VTB_LOAD_PROJECT__"
    @set external setSessionId: (t, string => unit) => unit = "__VTB_SET_SESSION_ID__"
  }

  @val external bootProjectData: option<JSON.t> = "window.__VTB_BOOT_PROJECT_DATA__"
  @val external bootProjectSessionId: option<string> = "window.__VTB_BOOT_PROJECT_SESSION_ID__"
  @val external setTimeoutMs: (unit => unit, int) => int = "setTimeout"
  @val external clearTimeoutMs: int => unit = "clearTimeout"
  @val @scope("document") external documentVisibilityState: string = "visibilityState"

  let localAssetSyncSignature = (state: state): string => {
    let sceneMarkers = SceneInventory.getActiveScenes(
      state.inventory,
      state.sceneOrder,
    )->Belt.Array.keepMap(scene =>
      switch scene.file {
      | File(_) | Blob(_) => Some(scene.id ++ ":" ++ scene.name)
      | Url(_) => None
      }
    )
    let logoMarker = switch state.logo {
    | Some(File(_)) | Some(Blob(_)) => "logo_upload"
    | _ => ""
    }
    let allMarkers = if logoMarker == "" {
      sceneMarkers
    } else {
      Belt.Array.concat(sceneMarkers, [logoMarker])
    }
    allMarkers->Array.join("|")
  }

  type cadencePolicy = {
    idleDelayMs: int,
    burstDelayMs: int,
    maxStalenessMs: int,
    burstThreshold: int,
  }

  let cadencePolicy = cadence =>
    switch cadence {
    | PersistencePreferences.Conservative => {
        idleDelayMs: 6500,
        burstDelayMs: 2600,
        maxStalenessMs: 90000,
        burstThreshold: 7,
      }
    | PersistencePreferences.Balanced => {
        idleDelayMs: 4000,
        burstDelayMs: 1800,
        maxStalenessMs: 45000,
        burstThreshold: 5,
      }
    | PersistencePreferences.Frequent => {
        idleDelayMs: 2500,
        burstDelayMs: 1200,
        maxStalenessMs: 20000,
        burstThreshold: 4,
      }
    }

  let canSyncToServer = () =>
    switch Dom.Storage2.localStorage->Dom.Storage2.getItem("auth_token") {
    | Some(token) => token != ""
    | None => Constants.isDebugBuild()
    }

  let intMax = (a: int, b: int) =>
    if a > b {
      a
    } else {
      b
    }
  let intMin = (a: int, b: int) =>
    if a < b {
      a
    } else {
      b
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
    let isProjectLoading = switch state.appMode {
    | SystemBlocking(ProjectLoading(_)) => true
    | _ => false
    }
    let snapshotTimeoutRef = React.useRef(None)
    let lastSnapshotRevisionRef = React.useRef(-1)
    let lastAssetSyncSignatureRef = React.useRef("")
    let latestStateRef = React.useRef(state)
    let dirtySinceMsRef = React.useRef(0.0)
    let lastChangeAtMsRef = React.useRef(0.0)
    let lastServerSyncAtMsRef = React.useRef(0.0)
    let burstChangeCountRef = React.useRef(0)
    let syncInFlightRef = React.useRef(false)
    let syncRefs: AppAutosave.syncRefs = {
      snapshotTimeoutRef,
      lastSnapshotRevisionRef,
      lastAssetSyncSignatureRef,
      latestStateRef,
      dirtySinceMsRef,
      lastChangeAtMsRef,
      lastServerSyncAtMsRef,
      burstChangeCountRef,
      syncInFlightRef,
    }

    latestStateRef.current = state

    AppEffects.useSystemLockLogging(~isSystemLocked)
    AppEffects.useBodyModeClasses(~isExporting, ~isProjectLoading)
    AppEffects.useInitComplete(~dispatch)
    AppEffects.useBootProject(~bootProjectData, ~bootProjectSessionId, ~dispatch)
    AppAutosave.useScheduledServerAutosave(
      ~state,
      ~isProjectLoading,
      ~dispatch,
      ~refs=syncRefs,
      ~cadencePolicy=cadence => (cadencePolicy(cadence) :> AppAutosave.cadencePolicy),
      ~canSyncToServer,
      ~localAssetSyncSignature,
    )
    AppAutosave.useFlushServerAutosave(
      ~isProjectLoading,
      ~dispatch,
      ~refs=syncRefs,
      ~canSyncToServer,
      ~localAssetSyncSignature,
    )
    AppEffects.useExposeState(~state)
    AppEffects.useExposeLifecycleBridges()

    React.useEffect1(() => {
      let loadProjectFn = data => dispatch(Actions.LoadProject(data))
      HeadlessWindow.setLoadProject(HeadlessWindow.window, loadProjectFn)
      None
    }, [dispatch])

    React.useEffect1(() => {
      let setSessionIdFn = id => dispatch(Actions.SetSessionId(id))
      HeadlessWindow.setSessionId(HeadlessWindow.window, setSessionIdFn)
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

      <AppErrorBoundary
        featureName="Sidebar" fallback={<FeatureCrashFallback featureName="Sidebar" />}
      >
        <Sidebar />
      </AppErrorBoundary>

      <AppErrorBoundary
        featureName="ViewerSurface" fallback={<FeatureCrashFallback featureName="Viewer Surface" />}
      >
        <main
          id="viewer-container"
          role="main"
          className={`viewer-main-container relative w-full h-full overflow-hidden select-none touch-none ${state.isLinking
              ? "linking-mode"
              : ""} ${state.movingHotspot != None ? "moving-hotspot" : ""}`}
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

          {if Array.length(SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)) == 0 {
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
      </AppErrorBoundary>

      /* Logic Controllers */
      <Navigation.Controller />
      <AppErrorBoundary featureName="ViewerManager" fallback={React.null}>
        <ViewerManager />
      </AppErrorBoundary>
      <AppErrorBoundary featureName="Simulation" fallback={React.null}>
        <Simulation />
      </AppErrorBoundary>
      <AppErrorBoundary featureName="ThumbnailProjectSystem" fallback={React.null}>
        <ThumbnailProjectSystem />
      </AppErrorBoundary>
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
