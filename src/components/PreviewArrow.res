external makeStyle: {..} => ReactDOM.Style.t = "%identity"

module Logic = {
  let calculateNavParams = (hotspot: Types.hotspot) => {
    let navYaw = ref(0.0)
    let navPitch = ref(0.0)
    let navHfov = ref(90.0)

    if hotspot.isReturnLink == Some(true) {
      switch hotspot.returnViewFrame {
      | Some(r) =>
        navYaw := r.yaw
        navPitch := r.pitch
        navHfov := r.hfov
      | None => ()
      }
    } else {
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
  ~state: Types.state,
) => {
  // 1. Local state for instant feedback & animations
  let (localIsAF, setLocalIsAF) = React.useState(_ => initialAF)
  let (flickerRed, setFlickerRed) = React.useState(_ => false)
  let (flickerYellow, setFlickerYellow) = React.useState(_ => false)
  let (isSwapping, setIsSwapping) = React.useState(_ => false)
  let toggleInFlightRef = React.useRef(false)

  // 2. Button Swap Logic (Uses localIsAF for instant feedback)
  let (centerIcon, rightIcon) = if localIsAF {
    (
      <LucideIcons.ChevronsRight.make className="text-white" size=20 strokeWidth=3.0 />,
      <LucideIcons.ChevronUp.make className="text-white" size=18 strokeWidth=3.0 />,
    )
  } else {
    (
      <LucideIcons.ChevronUp.make className="text-white" size=20 strokeWidth=3.0 />,
      <LucideIcons.ChevronsRight.make className="text-white" size=18 strokeWidth=3.0 />,
    )
  }

  // 3. Handlers
  let handleMainClick = e => {
    e->JsxEvent.Mouse.stopPropagation
    let currentState = AppContext.getBridgeState()
    let activeScenes = SceneInventory.getActiveScenes(
      currentState.inventory,
      currentState.sceneOrder,
    )
    switch Belt.Array.get(activeScenes, sceneIndex) {
    | Some(currentScene) =>
      switch Belt.Array.get(currentScene.hotspots, hotspotIndex) {
      | Some(hotspot) =>
        let targetIdx = HotspotTarget.resolveSceneIndex(activeScenes, hotspot)
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

  let handleRightClick = e => {
    e->JsxEvent.Mouse.stopPropagation
    if toggleInFlightRef.current {
      ()
    } else {
      toggleInFlightRef.current = true
      let newVal = !localIsAF
      setFlickerYellow(_ => true)
      let _ = setTimeout(() => {
        setFlickerYellow(_ => false)
        setIsSwapping(_ => true)
        setLocalIsAF(_ => newVal)
        dispatch(
          Actions.UpdateHotspotMetadata(
            sceneIndex,
            hotspotIndex,
            Logger.castToJson({"isAutoForward": newVal}),
          ),
        )
        let _ = setTimeout(() => EventBus.dispatch(ForceHotspotSync), 0)
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
        let _ = setTimeout(() => {
          setIsSwapping(_ => false)
          toggleInFlightRef.current = false
        }, 600)
      }, 800)
    }
  }

  React.useEffect1(() => {
    let currentState = AppContext.getBridgeState()
    let activeScenes = SceneInventory.getActiveScenes(
      currentState.inventory,
      currentState.sceneOrder,
    )
    let nextIsAF = switch Belt.Array.get(activeScenes, sceneIndex) {
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
    None
  }, [state.structuralRevision])

  let handleDeleteClick = e => {
    e->JsxEvent.Mouse.stopPropagation
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

  let centerBaseColor = if localIsAF {
    "bg-[#059669]"
  } else {
    "bg-[#ea580c]"
  }
  let centerHoverColor = if localIsAF {
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
    className="absolute top-0 left-0 z-[6000] group pointer-events-auto origin-center"
    style={makeStyle({
      "--open-delay": `${Constants.hotspotMenuOpenDelay->Int.toString}ms`,
      "--exit-delay": `${Constants.hotspotMenuExitDelay->Int.toString}ms`,
      "--sweep-duration": localIsAF ? "1.5s" : "4s",
    })}
  >
    <div className="relative flex items-center justify-center w-8 h-8">
      // CENTER BUTTON
      <div
        className={`absolute inset-0 ${centerBaseColor} ${centerHoverColor} rounded-md shadow-lg flex items-center justify-center z-20 cursor-pointer transition-colors overflow-hidden ${swapClass}`}
        onClick={handleMainClick}
      >
        <div
          className="absolute inset-0 bg-gradient-to-b from-transparent via-white/25 to-transparent pointer-events-none animate-diagonal-sweep scale-[2]"
        />
        {centerIcon}
      </div>

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

      // BOTTOM BUTTON (Delete)
      <div
        className={`absolute inset-0 bg-[#ea580c] rounded-md shadow-lg flex items-center justify-center z-10 cursor-pointer hover:bg-red-600
                   transition-all duration-300 ease-out 
                   delay-[var(--exit-delay)] group-hover:delay-[var(--open-delay)]
                   opacity-0 translate-y-0
                   group-hover:opacity-100 group-hover:translate-y-[110%]
                   ${flickerRed ? "animate-flicker-red" : ""}`}
        onClick={handleDeleteClick}
      >
        <LucideIcons.Trash2.make className="text-white" size=14 strokeWidth=3.0 />
      </div>
    </div>
  </div>
}
