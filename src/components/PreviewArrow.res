external makeStyle: {..} => ReactDOM.Style.t = "%identity"

module Logic = {
  let calculateNavParams = (hotspot: Types.hotspot) => {
    let navYaw = ref(0.0)
    let navPitch = ref(0.0)
    let navHfov = ref(90.0)

    // Return links deprecated - use targetYaw/targetPitch for all links
    switch hotspot.targetYaw {
    | Some(ty) =>
      navYaw := ty
      navPitch :=
        switch hotspot.targetPitch {
        | Some(p) => p
        | None => 0.0
        }
      navHfov :=
        switch hotspot.targetHfov {
        | Some(h) => h
        | None => 90.0
        }
    | None =>
      switch hotspot.viewFrame {
      | Some(vf) =>
        navYaw := vf.yaw
        navPitch := vf.pitch
        navHfov := vf.hfov
      | None => ()
      }
    }
    (navYaw.contents, navPitch.contents, navHfov.contents)
  }
}

@react.component
let make = (
  ~sceneIndex: int,
  ~hotspotIndex: int,
  ~dispatch: Actions.action => unit,
  ~elementId: string,
  ~isTargetAutoForward as initialAF: bool,
  ~scenes as _scenes: array<Types.scene>,
  ~state as _stateProp: Types.state,
) => {
  let state = AppContext.useAppState()
  // 1. Local state for instant feedback & animations
  let (localIsAF, setLocalIsAF) = React.useState(_ => initialAF)
  let (flickerRed, setFlickerRed) = React.useState(_ => false)
  let (flickerYellow, setFlickerYellow) = React.useState(_ => false)
  let (isSwapping, setIsSwapping) = React.useState(_ => false)
  let (flickerMove, setFlickerMove) = React.useState(_ => false)
  let toggleInFlightRef = React.useRef(false)

  let isMovingThis = switch state.movingHotspot {
  | Some(mh) => mh.sceneIndex == sceneIndex && mh.hotspotIndex == hotspotIndex
  | None => false
  }

  // Detect completion of move to trigger blink
  let prevIsMovingThis = React.useRef(false)
  React.useEffect1(() => {
    if prevIsMovingThis.current && !isMovingThis {
      // Move was just committed or cancelled
      // We only want to blink if it was committed, but for now let's blink anyway
      setFlickerMove(_ => true)
      let _ = setTimeout(() => setFlickerMove(_ => false), 800)
    }
    prevIsMovingThis.current = isMovingThis
    None
  }, [isMovingThis])

  // 2. Button Swap Logic (Uses localIsAF for instant feedback)
  let (centerIcon, rightIcon) = if isMovingThis {
    (
      <LucideIcons.Move.make className="text-white" size=20 strokeWidth={3.0} />,
      <LucideIcons.ChevronUp.make className="text-white" size=18 strokeWidth={3.0} />,
    )
  } else if localIsAF {
    (
      <LucideIcons.ChevronsRight.make className="text-white" size=20 strokeWidth={3.0} />,
      <LucideIcons.ChevronUp.make className="text-white" size=18 strokeWidth={3.0} />,
    )
  } else {
    (
      <LucideIcons.ChevronUp.make className="text-white" size=20 strokeWidth={3.0} />,
      <LucideIcons.ChevronsRight.make className="text-white" size=18 strokeWidth={3.0} />,
    )
  }

  // 3. Handlers
  let handleMainClick = e => {
    e->JsxEvent.Mouse.stopPropagation
    if isMovingThis {
      // Cancel move
      dispatch(StopMovingHotspot)
    } else {
      let currentState = AppContext.getBridgeState()
      let activeScenesForClick = SceneInventory.getActiveScenes(
        currentState.inventory,
        currentState.sceneOrder,
      )
      switch Belt.Array.get(activeScenesForClick, sceneIndex) {
      | Some(currentScene) =>
        switch Belt.Array.get(currentScene.hotspots, hotspotIndex) {
        | Some(hotspot) =>
          let targetIdx = HotspotTarget.resolveSceneIndex(activeScenesForClick, hotspot)
          switch targetIdx {
          | Some(tIdx) =>
            let (ny, np, nh) = Logic.calculateNavParams(hotspot)

            SceneSwitcher.navigateToScene(
              dispatch,
              currentState,
              tIdx,
              sceneIndex,
              hotspotIndex,
              ~targetYaw=ny,
              ~targetPitch=np,
              ~targetHfov=nh,
              (),
            )
          | None => ()
          }
        | None => ()
        }
      | None => ()
      }
    }
  }

  let handleRightClick = e => {
    e->JsxEvent.Mouse.stopPropagation
    let currentState = AppContext.getBridgeState()
    let isMovingAny = currentState.movingHotspot != None

    if isMovingAny {
      ()
    } else if toggleInFlightRef.current {
      ()
    } else {
      toggleInFlightRef.current = true
      let newVal = !localIsAF

      // 1. Stylistic Feedback: Start blink on the CURRENT icon
      setFlickerYellow(_ => true)

      // 2. Immediate Data Update (Robustness)
      dispatch(
        Actions.UpdateHotspotMetadata(
          sceneIndex,
          hotspotIndex,
          Logger.castToJson({"isAutoForward": newVal}),
        ),
      )

      // 3. Notification (Instant)
      NotificationManager.dispatch({
        id: "",
        importance: Info,
        context: Operation("preview_arrow"),
        message: newVal ? "Auto-Forward Enabled" : "Normal Forward Set",
        details: None,
        action: None,
        duration: NotificationTypes.defaultTimeoutMs(Info),
        dismissible: true,
        createdAt: Date.now(),
      })

      // 4. Sequence: Wait for blinks to complete, THEN swap the icon
      let _ = setTimeout(() => {
        setFlickerYellow(_ => false)
        setIsSwapping(_ => true)
        setLocalIsAF(_ => newVal) // Swap icon now

        let _ = setTimeout(() => {
          setIsSwapping(_ => false)
          toggleInFlightRef.current = false // Re-enable external syncs
        }, 400)
      }, 800)
    }
  }

  React.useEffect1(() => {
    // Only sync from external state if we are not actively toggling locally
    if !toggleInFlightRef.current {
      let currentState = AppContext.getBridgeState()
      let activeScenesForSync = SceneInventory.getActiveScenes(
        currentState.inventory,
        currentState.sceneOrder,
      )
      let nextIsAF = switch Belt.Array.get(activeScenesForSync, sceneIndex) {
      | Some(scene) =>
        switch Belt.Array.get(scene.hotspots, hotspotIndex) {
        | Some(hotspot) =>
          switch hotspot.isAutoForward {
          | Some(b) => b
          | None => false
          }
        | None => localIsAF
        }
      | None => localIsAF
      }
      setLocalIsAF(_ => nextIsAF)
    }
    None
  }, [state.structuralRevision])

  let handleDeleteClick = e => {
    e->JsxEvent.Mouse.stopPropagation
    let currentState = AppContext.getBridgeState()
    let isMovingAny = currentState.movingHotspot != None

    if isMovingAny {
      ()
    } else {
      // Start Red Flicker
      setFlickerRed(_ => true)
      let _ = setTimeout(() => {
        setFlickerRed(_ => false)
        dispatch(Actions.RemoveHotspot(sceneIndex, hotspotIndex))
        NotificationManager.dispatch({
          id: "",
          importance: Info,
          context: Operation("preview_arrow"),
          message: "Hotspot Removed",
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Info),
          dismissible: true,
          createdAt: Date.now(),
        })
      }, 800)
    }
  }

  let handleMoveClick = e => {
    e->JsxEvent.Mouse.stopPropagation
    let currentState = AppContext.getBridgeState()
    let isMovingThisActual = switch currentState.movingHotspot {
    | Some(mh) => mh.sceneIndex == sceneIndex && mh.hotspotIndex == hotspotIndex
    | None => false
    }

    if isMovingThisActual {
      dispatch(StopMovingHotspot)
    } else {
      dispatch(StartMovingHotspot(sceneIndex, hotspotIndex))
      NotificationManager.dispatch({
        id: "hotspot-move-mode",
        importance: Info,
        context: Operation("preview_arrow"),
        message: "Move Mode Active",
        details: Some("Click anywhere on the panorama to place the link. ESC to cancel."),
        action: None,
        duration: 5000,
        dismissible: true,
        createdAt: Date.now(),
      })
    }
  }

  let centerBaseColor = if isMovingThis {
    "bg-yellow-600"
  } else if localIsAF {
    "bg-[#059669]"
  } else {
    "bg-[#ea580c]"
  }

  let centerHoverColor = if isMovingThis {
    "hover:bg-yellow-500"
  } else if localIsAF {
    "hover:bg-[#10b981]"
  } else {
    "hover:bg-[#f97316]"
  }

  let rightBaseColor = if !localIsAF {
    "bg-[#059669]"
  } else {
    "bg-[#ea580c]"
  }
  let rightHoverColor = if !localIsAF {
    "hover:bg-[#10b981]"
  } else {
    "hover:bg-[#f97316]"
  }

  let swapClass = isSwapping ? "animate-swap-icon" : ""

  <div
    id=elementId
    className={`absolute top-0 left-0 z-[6000] ${isMovingThis
        ? "pointer-events-none"
        : "group pointer-events-auto"} origin-center transition-opacity duration-300 -translate-x-1/2 -translate-y-1/2`}
    style={makeStyle({
      "--open-delay": `${Constants.hotspotMenuOpenDelay->Int.toString}ms`,
      "--exit-delay": `${Constants.hotspotMenuExitDelay->Int.toString}ms`,
      "--sweep-duration": localIsAF ? "1.5s" : "4s",
    })}
  >
    <div
      className={`relative flex items-center justify-center w-8 h-8 ${isMovingThis
          ? "pointer-events-none"
          : ""}`}
    >
      // CENTER BUTTON
      <div
        className={`absolute inset-0 ${centerBaseColor} ${centerHoverColor} rounded-md shadow-lg flex items-center justify-center z-20 transition-colors overflow-hidden ${swapClass} ${flickerMove
            ? "animate-flicker-yellow-flat"
            : ""} ${isMovingThis ? "pointer-events-none" : "cursor-pointer"}`}
        onClick={handleMainClick}
      >
        {!isMovingThis
          ? <div
              className="absolute inset-0 bg-gradient-to-b from-transparent via-white/25 to-transparent pointer-events-none animate-diagonal-sweep scale-[2]"
            />
          : React.null}
        {centerIcon}
      </div>

      {!isMovingThis
        ? <>
            // RIGHT BUTTON (Toggle)
            <div
              className={`absolute inset-0 ${rightBaseColor} ${rightHoverColor} rounded-md shadow-lg flex items-center justify-center z-10 cursor-pointer 
                         transition-all duration-300 ease-out 
                         delay-[var(--exit-delay)] group-hover:delay-[var(--open-delay)]
                         opacity-0 translate-x-0
                         group-hover:opacity-100 group-hover:translate-x-[110%]
                         ${flickerYellow ? "animate-flicker-yellow" : ""} ${swapClass}`}
              onClick={handleRightClick}
            >
              {rightIcon}
            </div>
            // BOTTOM BUTTON (Move)
            <div
              className={`absolute inset-0 ${isMovingThis
                  ? "bg-yellow-500"
                  : "bg-yellow-600 hover:bg-yellow-500"} rounded-md shadow-lg flex items-center justify-center z-10 cursor-pointer 
                         transition-all duration-300 ease-out 
                         delay-[var(--exit-delay)] group-hover:delay-[var(--open-delay)]
                         opacity-0 translate-y-0
                         group-hover:opacity-100 group-hover:translate-y-[110%]`}
              onClick={handleMoveClick}
              title={isMovingThis ? "Cancel Move" : "Move Hotspot"}
            >
              {isMovingThis
                ? <LucideIcons.X.make className="text-white" size={14} strokeWidth={3.0} />
                : <LucideIcons.Move.make className="text-white" size={14} strokeWidth={3.0} />}
            </div>
            // FAR BOTTOM BUTTON (Delete)
            <div
              className={`absolute inset-0 bg-[#ea580c] rounded-md shadow-lg flex items-center justify-center z-10 cursor-pointer hover:bg-red-600
                         transition-all duration-300 ease-out 
                         delay-[var(--exit-delay)] group-hover:delay-[var(--open-delay)]
                         opacity-0 translate-y-0
                         group-hover:opacity-100 group-hover:translate-y-[220%]
                         ${flickerRed ? "animate-flicker-red" : ""}`}
              onClick={handleDeleteClick}
              title="Delete Hotspot"
            >
              <LucideIcons.Trash2.make className="text-white" size=14 strokeWidth=3.0 />
            </div>
          </>
        : React.null}
    </div>
  </div>
}
