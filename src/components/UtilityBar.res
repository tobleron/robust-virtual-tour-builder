/* src/components/UtilityBar.res */

let clearLocalClientCache: unit => Promise.t<unit> = %raw(`() => (async () => {
  try { localStorage.clear(); } catch (_) {}
  try { sessionStorage.clear(); } catch (_) {}

  try {
    if ("caches" in window) {
      const keys = await caches.keys();
      await Promise.all(keys.map((k) => caches.delete(k)));
    }
  } catch (_) {}

  try {
    if (indexedDB && typeof indexedDB.databases === "function") {
      const dbs = await indexedDB.databases();
      for (const db of dbs) {
        if (db && db.name) indexedDB.deleteDatabase(db.name);
      }
    }
  } catch (_) {}

  try {
    if ("serviceWorker" in navigator) {
      const regs = await navigator.serviceWorker.getRegistrations();
      await Promise.all(regs.map((r) => r.unregister()));
    }
  } catch (_) {}
})()`)

let hardReload: unit => unit = %raw(`() => window.location.reload()`)

@react.component
let make = React.memo((~scenesLoaded, ~isLinking, ~simActive, ~currentJourneyId) => {
  let dispatch = AppContext.useAppDispatch()
  let canEditHotspots = Capability.useCapability(CanEditHotspots)
  let canStartSimulation = Capability.useCapability(CanStartSimulation)

  let handleFabClick = React.useMemo2(() =>
    e => {
      JsxEvent.Mouse.stopPropagation(e)

      if isLinking {
        ViewerState.state := {...ViewerState.state.contents, linkingStartPoint: Nullable.null}
        dispatch(Actions.StopLinking)
        NotificationManager.dispatch({
          id: "",
          importance: Warning,
          context: Operation("utility_bar"),
          message: "Link Mode: OFF",
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Warning),
          dismissible: true,
          createdAt: Date.now(),
        })
      } else if canEditHotspots {
        let currentState = AppContext.getBridgeState()
        let hasExistingHotspotLink = switch Belt.Array.get(
          currentState.scenes,
          currentState.activeIndex,
        ) {
        | Some(scene) => Belt.Array.length(scene.hotspots) > 0
        | None => false
        }

        if hasExistingHotspotLink {
          NotificationManager.dispatch({
            id: "",
            importance: Warning,
            context: Operation("utility_bar"),
            message: "Scene already has hotspot link!",
            details: None,
            action: None,
            duration: NotificationTypes.defaultTimeoutMs(Warning),
            dismissible: true,
            createdAt: Date.now(),
          })
        } else {
          let cx = JsxEvent.Mouse.clientX(e)
          let cy = JsxEvent.Mouse.clientY(e)
          ViewerState.state := {
              ...ViewerState.state.contents,
              linkingStartPoint: Nullable.make({
                "x": Belt.Int.toFloat(cx),
                "y": Belt.Int.toFloat(cy),
              }),
            }

          let v = Nullable.toOption(ViewerSystem.getActiveViewer())
          switch v {
          | Some(_viewer) =>
            dispatch(Actions.StartLinking(None))

            NotificationManager.dispatch({
              id: "linking-info",
              importance: Info,
              context: Operation("utility_bar"),
              message: "Linking mode ON",
              details: None,
              action: None,
              duration: NotificationTypes.defaultTimeoutMs(Info),
              dismissible: true,
              createdAt: Date.now(),
            })
          | None =>
            NotificationManager.dispatch({
              id: "viewer-not-found",
              importance: Error,
              context: Operation("utility_bar"),
              message: "Viewer not initialized",
              details: None,
              action: None,
              duration: NotificationTypes.defaultTimeoutMs(Error),
              dismissible: true,
              createdAt: Date.now(),
            })
          }
        }
      } else {
        Logger.debug(~module_="UtilityBar", ~message="START_LINKING_REJECTED_LOCK_HELD", ())
      }
    }
  , (isLinking, canEditHotspots))

  let handleSimClick = React.useMemo3(() =>
    e => {
      JsxEvent.Mouse.stopPropagation(e)
      if simActive {
        dispatch(Actions.StopAutoPilot)
        Scene.Switcher.cancelNavigation()
        dispatch(Actions.SetActiveScene(0, 0.0, 0.0, None))

        // Force hide snapshot overlay and abort any active navigation
        switch ReBindings.Dom.getElementById("viewer-snapshot-overlay") {
        | Nullable.Value(el) =>
          ReBindings.Dom.ClassList.remove(ReBindings.Dom.classList(el), "snapshot-visible")
        | _ => ()
        }
        // Abort any active Supervisor navigation task
        switch NavigationSupervisor.getCurrentTask() {
        | Some(t) => NavigationSupervisor.abort(t.token.id)
        | None => ()
        }
        dispatch(Actions.DispatchNavigationFsmEvent(Reset))
      } else if canStartSimulation {
        dispatch(
          Batch([
            Actions.SetActiveScene(0, 0.0, 0.0, None),
            Actions.StartAutoPilot(currentJourneyId, false),
          ]),
        )
        NotificationManager.dispatch({
          id: "",
          importance: Info,
          context: Operation("utility_bar"),
          message: "ESC to stop tour preview.",
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Info),
          dismissible: true,
          createdAt: Date.now(),
        })
      } else {
        Logger.debug(~module_="UtilityBar", ~message="SIMULATION_START_REJECTED_LOCK_HELD", ())
      }
    }
  , (simActive, currentJourneyId, canStartSimulation))

  let handleResetCacheClick = React.useMemo0(() =>
    e => {
      JsxEvent.Mouse.stopPropagation(e)
      clearLocalClientCache()
      ->Promise.then(_ => {
        let _ = ReBindings.Window.setTimeout(() => hardReload(), 120)
        Promise.resolve()
      })
      ->Promise.catch(err => {
        let (msg, _) = Logger.getErrorDetails(err)
        NotificationManager.dispatch({
          id: "",
          importance: Error,
          context: Operation("utility_bar"),
          message: "Failed to clear cache: " ++ msg,
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Error),
          dismissible: true,
          createdAt: Date.now(),
        })
        Promise.resolve()
      })
      ->ignore
    }
  )

  let utilBarClass =
    "absolute top-6 left-5 z-[5002] flex flex-col gap-2 transition-all duration-300 " ++ if (
      !scenesLoaded
    ) {
      "grayscale opacity-60 pointer-events-none"
    } else {
      ""
    }

  let renderUtilityButtons = () => <>
    <Tooltip
      alignment=#Right
      content={if isLinking {
        "Close link mode"
      } else {
        "Add link to scene"
      }}
      disabled={isLinking}
    >
      <Shadcn.Button
        size="icon"
        variant={if !scenesLoaded {
          "secondary"
        } else if isLinking {
          "accent"
        } else {
          "destructive"
        }}
        className={"w-8 h-8 min-w-8 min-h-8 rounded-full cursor-pointer font-semibold border border-transparent hover:border-[#0e2d52]" ++ if (
          !scenesLoaded
        ) {
          " disabled:opacity-100"
        } else {
          ""
        }}
        onClick={handleFabClick}
        disabled={!scenesLoaded || (!isLinking && !canEditHotspots)}
        ariaLabel={if isLinking {
          "Close Link Mode"
        } else {
          "Add Link"
        }}
      >
        {if isLinking {
          <LucideIcons.X size=20 strokeWidth=3.0 />
        } else {
          <LucideIcons.Plus size=20 strokeWidth=3.0 />
        }}
      </Shadcn.Button>
    </Tooltip>

    {if !isLinking {
      <>
        <Tooltip
          alignment=#Right
          content={if simActive {
            "Stop tour preview"
          } else {
            "Tour preview"
          }}
          disabled={isLinking}
        >
          <Shadcn.Button
            size="icon"
            variant={if !scenesLoaded {
              "secondary"
            } else {
              "destructive"
            }}
            className={"w-8 h-8 min-w-8 min-h-8 rounded-full cursor-pointer border border-transparent hover:border-[#0e2d52]" ++ if (
              !scenesLoaded
            ) {
              " disabled:opacity-100"
            } else {
              ""
            }}
            onClick={handleSimClick}
            disabled={(isLinking && !simActive) || (!simActive && !canStartSimulation)}
            ariaLabel={if simActive {
              "Stop Tour Preview"
            } else {
              "Tour Preview"
            }}
          >
            {if simActive {
              <LucideIcons.Square size=18 strokeWidth=3.0 />
            } else {
              <LucideIcons.Play size=18 strokeWidth=3.0 />
            }}
          </Shadcn.Button>
        </Tooltip>

        <ViewerLabelMenu scenesLoaded isLinking simActive />

        <Tooltip alignment=#Right content="Reset local cache (temporary)">
          <Shadcn.Button
            size="icon"
            variant="secondary"
            className="w-8 h-8 min-w-8 min-h-8 rounded-full cursor-pointer border border-transparent hover:border-[#0e2d52]"
            onClick={handleResetCacheClick}
            ariaLabel="Reset Cache"
          >
            <LucideIcons.Trash2 size=14 strokeWidth=2.5 />
          </Shadcn.Button>
        </Tooltip>
      </>
    } else {
      React.null
    }}
  </>

  <>
    <div id="viewer-utility-bar" className={utilBarClass}> {renderUtilityButtons()} </div>
  </>
})
