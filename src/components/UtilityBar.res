/* src/components/UtilityBar.res */

@react.component
let make = React.memo((~scenesLoaded, ~isLinking, ~simActive, ~currentJourneyId) => {
  let dispatch = AppContext.useAppDispatch()

  let handleFabClick = React.useMemo1(() =>
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
    }
  , [isLinking])

  let handleSimClick = React.useMemo2(() =>
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
      } else {
        dispatch(Actions.StartAutoPilot(currentJourneyId, false))
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
      }
    }
  , (simActive, currentJourneyId))

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
        className="w-8 h-8 min-w-8 min-h-8 rounded-full font-semibold border border-transparent hover:border-[#0e2d52]"
        onClick={handleFabClick}
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
            className="w-8 h-8 min-w-8 min-h-8 rounded-full border border-transparent hover:border-[#0e2d52]"
            onClick={handleSimClick}
            disabled={isLinking && !simActive}
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

        <ViewerLabelMenu scenesLoaded isLinking />
      </>
    } else {
      React.null
    }}
  </>

  <>
    <div id="viewer-utility-bar" className={utilBarClass}> {renderUtilityButtons()} </div>
  </>
})
