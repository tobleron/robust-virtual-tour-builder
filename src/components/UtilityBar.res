/* src/components/UtilityBar.res */
open EventBus

@react.component
let make = React.memo((~scenesLoaded, ~isLinking, ~simActive, ~currentJourneyId) => {
  let dispatch = AppContext.useAppDispatch()

  let handleFabClick = React.useMemo1(() =>
    e => {
      JsxEvent.Mouse.stopPropagation(e)

      if isLinking {
        ViewerState.state.linkingStartPoint = Nullable.null
        dispatch(Actions.StopLinking)
        EventBus.dispatch(ShowNotification("Link Mode: OFF", #Warning))
      } else {
        let cx = JsxEvent.Mouse.clientX(e)
        let cy = JsxEvent.Mouse.clientY(e)
        ViewerState.state.linkingStartPoint = Nullable.make({
          "x": Belt.Int.toFloat(cx),
          "y": Belt.Int.toFloat(cy),
        })

        let v = Nullable.toOption(ReBindings.Viewer.instance)
        switch v {
        | Some(_viewer) =>
          dispatch(Actions.StartLinking(None))
          EventBus.dispatch(ShowNotification("ESC to cancel, Enter to save link.", #Info))
        | None => EventBus.dispatch(ShowNotification("Viewer not initialized", #Error))
        }
      }
    }
  , [isLinking])

  let handleSimClick = React.useMemo2(() =>
    e => {
      JsxEvent.Mouse.stopPropagation(e)
      if simActive {
        dispatch(Actions.StopAutoPilot)
        SceneSwitcher.cancelNavigation()
        dispatch(Actions.SetActiveScene(0, 0.0, 0.0, None))

        // Force hide snapshot overlay and release locks for maximum robustness
        switch ReBindings.Dom.getElementById("viewer-snapshot-overlay") {
        | Nullable.Value(el) =>
          ReBindings.Dom.ClassList.remove(ReBindings.Dom.classList(el), "snapshot-visible")
        | _ => ()
        }
        ViewerState.state.isSwapping = false
        ViewerState.state.isSceneLoading = false
      } else {
        dispatch(Actions.StartAutoPilot(currentJourneyId, false))
        EventBus.dispatch(ShowNotification("ESC to stop tour preview.", #Info))
      }
    }
  , (simActive, currentJourneyId))

  let utilBarClass =
    "absolute top-6 left-6 z-[5002] flex flex-col gap-2 transition-all duration-300 " ++ if (
      !scenesLoaded
    ) {
      "grayscale opacity-60 pointer-events-none"
    } else {
      ""
    }

  <div id="viewer-utility-bar" className={utilBarClass}>
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
        className="w-[32px] h-[32px] rounded-full text-[20px] font-bold border border-transparent hover:border-[#0e2d52]"
        onClick={handleFabClick}
      >
        {if isLinking {
          <LucideIcons.X size=20 strokeWidth=3.0 />
        } else {
          <LucideIcons.Plus size=20 strokeWidth=3.0 />
        }}
      </Shadcn.Button>
    </Tooltip>

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
        className="w-[32px] h-[32px] rounded-full border border-transparent hover:border-[#0e2d52]"
        onClick={handleSimClick}
        disabled={isLinking}
      >
        {if simActive {
          <LucideIcons.Square size=18 strokeWidth=3.0 />
        } else {
          <LucideIcons.Play size=18 strokeWidth=3.0 />
        }}
      </Shadcn.Button>
    </Tooltip>

    <ViewerLabelMenu scenesLoaded isLinking />
  </div>
})
