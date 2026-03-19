/* src/components/UtilityBar.res */

@react.component
let make = React.memo((~scenesLoaded, ~isLinking, ~simActive, ~currentJourneyId, ~isTeasing) => {
  let dispatch = AppContext.useAppDispatch()
  let canEditHotspots = Capability.useCapability(CanEditHotspots)
  let canStartSimulation = Capability.useCapability(CanStartSimulation)
  let isSystemLocked = Capability.useIsSystemLocked()

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

  let state = AppContext.useAppState()
  let isMovingHotspot = switch state.movingHotspot {
  | Some(_) => true
  | None => false
  }

  let utilBarClass =
    "viewer-rail viewer-rail--utility" ++
    if isTeasing {
      " is-hidden"
    } else if !scenesLoaded || isSystemLocked || isMovingHotspot {
      " is-inactive"
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
        variant="ghost"
        className={
          "viewer-control viewer-control--orb viewer-control--utility viewer-control--link " ++
          if isLinking {
            "viewer-control--accent"
          } else {
            "viewer-control--danger"
          } ++
          if (simActive || isTeasing) && !isLinking {
            " viewer-control--dimmed"
          } else {
            ""
          }
        }
        onClick={handleFabClick}
        disabled={!scenesLoaded || isSystemLocked || (!isLinking && !canEditHotspots)}
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
        <div
          onMouseEnter={_ => {
            ChunkPrefetch.warmSimulation()
          }}
        >
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
              variant="ghost"
              className={
                "viewer-control viewer-control--orb viewer-control--utility viewer-control--preview viewer-control--danger" ++
                if isTeasing {
                  " viewer-control--dimmed"
                } else {
                  ""
                }
              }
              onClick={handleSimClick}
              disabled={!scenesLoaded ||
              isSystemLocked ||
              isLinking && !simActive ||
              (!simActive && !canStartSimulation)}
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
        </div>

        <ViewerLabelMenu scenesLoaded isLinking simActive isSystemLocked isTeasing />
      </>
    } else {
      React.null
    }}
  </>

  <>
    <div id="viewer-utility-bar" className={utilBarClass}> {renderUtilityButtons()} </div>
  </>
})
