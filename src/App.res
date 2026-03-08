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
    let sceneMarkers =
      SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
      ->Belt.Array.keepMap(scene =>
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

  let intMax = (a: int, b: int) => if a > b { a } else { b }
  let intMin = (a: int, b: int) => if a < b { a } else { b }

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

    latestStateRef.current = state

    React.useEffect1(() => {
      Logger.debug(
        ~module_="App",
        ~message="SYSTEM_LOCKED_STATUS: " ++ (isSystemLocked ? "LOCKED" : "UNLOCKED"),
        (),
      )
      None
    }, [isSystemLocked])

    React.useEffect2(() => {
      let bodyClasses = Dom.classList(Dom.documentBody)
      if isExporting {
        bodyClasses->Dom.ClassList.add("export-mode")
      } else {
        bodyClasses->Dom.ClassList.remove("export-mode")
      }
      if isProjectLoading {
        bodyClasses->Dom.ClassList.add("project-load-mode")
      } else {
        bodyClasses->Dom.ClassList.remove("project-load-mode")
      }
      None
    }, (isExporting, isProjectLoading))

    React.useEffect0(() => {
      Logger.debug(~module_="App", ~message="InnerApp Mounted - DISPATCHING_INIT_COMPLETE", ())
      dispatch(DispatchAppFsmEvent(InitializeComplete))
      None
    })

    React.useEffect1(() => {
      switch bootProjectData {
      | Some(projectData) =>
        let sessionIdOpt = bootProjectSessionId
        sessionIdOpt->Option.forEach(id => dispatch(Actions.SetSessionId(id)))
        dispatch(Actions.LoadProject(projectData))
        let _ = %raw(
          "((w) => { w.__VTB_BOOT_PROJECT_DATA__ = undefined; w.__VTB_BOOT_PROJECT_SESSION_ID__ = undefined; })(window)"
        )
      | None => ()
      }
      None
    }, [dispatch])

    React.useEffect2(() => {
      let prefs = PersistencePreferences.get()
      let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
      let canUseServerAutosave = switch prefs.autosaveMode {
      | PersistencePreferences.Hybrid => true
      | PersistencePreferences.Off | PersistencePreferences.LocalOnly => false
      }
      let shouldSync =
        canUseServerAutosave &&
        canSyncToServer() &&
        Array.length(activeScenes) > 0 &&
        !isProjectLoading

      let scheduleSync = (delayMs: int) => {
        switch snapshotTimeoutRef.current {
        | Some(id) => clearTimeoutMs(id)
        | None => ()
        }
        let timeoutId = setTimeoutMs(() => {
          let syncState = latestStateRef.current
          let latestScenes = SceneInventory.getActiveScenes(syncState.inventory, syncState.sceneOrder)
          if syncInFlightRef.current || Array.length(latestScenes) == 0 {
            ()
          } else if syncState.structuralRevision > lastSnapshotRevisionRef.current {
            syncInFlightRef.current = true
            let projectData = ProjectSystem.encodeProjectFromState(syncState)
            let syncPromise = switch syncState.sessionId {
            | Some(id) => Api.ProjectApi.syncSnapshot(~sessionId=id, ~projectData, ~origin=Auto)
            | None => Api.ProjectApi.syncSnapshot(~projectData, ~origin=Auto)
            }
            syncPromise
            ->Promise.then(result => {
              switch result {
              | Ok(syncResult) =>
                lastSnapshotRevisionRef.current = syncState.structuralRevision
                lastServerSyncAtMsRef.current = Date.now()
                dirtySinceMsRef.current = 0.0
                burstChangeCountRef.current = 0
                let assetSignature = localAssetSyncSignature(syncState)
                if assetSignature != "" && assetSignature != lastAssetSyncSignatureRef.current {
                  Api.ProjectApi.syncSnapshotAssets(~sessionId=syncResult.sessionId, ~state=syncState)
                  ->Promise.then(assetResult => {
                    switch assetResult {
                    | Ok(_) => lastAssetSyncSignatureRef.current = assetSignature
                    | Error(_) => ()
                    }
                    Promise.resolve()
                  })
                  ->ignore
                }
                switch syncState.sessionId {
                | Some(_) => ()
                | None => dispatch(Actions.SetSessionId(syncResult.sessionId))
                }
              | Error(_) => ()
              }
              syncInFlightRef.current = false
              Promise.resolve()
            })
            ->Promise.catch(_ => {
              syncInFlightRef.current = false
              Promise.resolve()
            })
            ->ignore
          }
        }, delayMs)
        snapshotTimeoutRef.current = Some(timeoutId)
      }

      if !shouldSync {
        switch snapshotTimeoutRef.current {
        | Some(id) =>
          clearTimeoutMs(id)
          snapshotTimeoutRef.current = None
        | None => ()
        }
        None
      } else {
        let now = Date.now()
        if dirtySinceMsRef.current == 0.0 {
          dirtySinceMsRef.current = now
          burstChangeCountRef.current = 1
        } else if now -. lastChangeAtMsRef.current < 12000.0 {
          burstChangeCountRef.current = burstChangeCountRef.current + 1
        } else {
          burstChangeCountRef.current = 1
        }
        lastChangeAtMsRef.current = now

        let policy = cadencePolicy(prefs.snapshotCadence)
        let burstDelay =
          if burstChangeCountRef.current >= policy.burstThreshold {
            policy.burstDelayMs
          } else {
            policy.idleDelayMs
          }
        let sinceLastSync = now -. lastServerSyncAtMsRef.current
        let cooldownRemaining = intMax(0, 800 - (sinceLastSync->Belt.Int.fromFloat))
        let maxStalenessRemaining = intMax(
          0,
          policy.maxStalenessMs - (now -. dirtySinceMsRef.current)->Belt.Int.fromFloat,
        )
        let baseDelay = intMax(cooldownRemaining, burstDelay)
        let finalDelay =
          if maxStalenessRemaining == 0 {
            250
          } else {
            intMin(baseDelay, maxStalenessRemaining)
          }
        scheduleSync(finalDelay)

        Some(() => ())
      }
    }, (state.structuralRevision, isProjectLoading))

    React.useEffect2(() => {
      let flushServerAutosave = (_event: Dom.event) => {
        let prefs = PersistencePreferences.get()
        let canUseServerAutosave = switch prefs.autosaveMode {
        | PersistencePreferences.Hybrid => true
        | PersistencePreferences.Off | PersistencePreferences.LocalOnly => false
        }
        let flushState = latestStateRef.current
        let activeScenes = SceneInventory.getActiveScenes(flushState.inventory, flushState.sceneOrder)
        if
          canUseServerAutosave &&
          canSyncToServer() &&
          !syncInFlightRef.current &&
          !isProjectLoading &&
          Array.length(activeScenes) > 0 &&
          flushState.structuralRevision > lastSnapshotRevisionRef.current
        {
          let projectData = ProjectSystem.encodeProjectFromState(flushState)
          let syncPromise = switch flushState.sessionId {
          | Some(id) => Api.ProjectApi.syncSnapshot(~sessionId=id, ~projectData, ~origin=Auto)
          | None => Api.ProjectApi.syncSnapshot(~projectData, ~origin=Auto)
          }
          syncInFlightRef.current = true
          syncPromise
          ->Promise.then(result => {
            switch result {
            | Ok(syncResult) =>
              lastSnapshotRevisionRef.current = flushState.structuralRevision
              lastServerSyncAtMsRef.current = Date.now()
              let assetSignature = localAssetSyncSignature(flushState)
              if assetSignature != "" && assetSignature != lastAssetSyncSignatureRef.current {
                Api.ProjectApi.syncSnapshotAssets(~sessionId=syncResult.sessionId, ~state=flushState)
                ->Promise.then(assetResult => {
                  switch assetResult {
                  | Ok(_) => lastAssetSyncSignatureRef.current = assetSignature
                  | Error(_) => ()
                  }
                  Promise.resolve()
                })
                ->ignore
              }
              switch flushState.sessionId {
              | Some(_) => ()
              | None => dispatch(Actions.SetSessionId(syncResult.sessionId))
              }
            | Error(_) => ()
            }
            syncInFlightRef.current = false
            Promise.resolve()
          })
          ->Promise.catch(_ => {
            syncInFlightRef.current = false
            Promise.resolve()
          })
          ->ignore
        }
      }

      let onVisibilityChange = (_event: Dom.event) => {
        if documentVisibilityState == "hidden" {
          flushServerAutosave(_event)
        }
      }

      DomBindings.Window.addEventListener("pagehide", flushServerAutosave)
      DomBindings.Window.addEventListener("visibilitychange", onVisibilityChange)

      Some(() => {
        DomBindings.Window.removeEventListener("pagehide", flushServerAutosave)
        DomBindings.Window.removeEventListener("visibilitychange", onVisibilityChange)
      })
    }, (isProjectLoading, dispatch))

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
