/* src/components/PreviewArrow.res */

@react.component
let make = (
  ~sceneIndex: int,
  ~hotspotIndex: int,
  ~dispatch: Actions.action => unit,
  ~elementId: string,
  ~isTargetAutoForward as initialAF: bool,
  ~scenes: array<Types.scene>,
  ~state: Types.state,
) => {
  // 1. Reactive calculation of Target Scene (use passed scenes)
  let targetSceneRef = React.useMemo3(() => {
    switch Belt.Array.get(scenes, sceneIndex) {
    | Some(scene) =>
      switch Belt.Array.get(scene.hotspots, hotspotIndex) {
      | Some(h) => Belt.Array.getBy(scenes, s => s.name == h.target)
      | None => None
      }
    | None => None
    }
  }, (scenes, sceneIndex, hotspotIndex))

  // 2. Local state for instant feedback & animations
  let (localIsAF, setLocalIsAF) = React.useState(_ => initialAF)
  let (flickerRed, setFlickerRed) = React.useState(_ => false)
  let (flickerYellow, setFlickerYellow) = React.useState(_ => false)
  let (isSwapping, setIsSwapping) = React.useState(_ => false)

  // 3. Sync with global state if it changes externally
  React.useEffect1(() => {
    switch targetSceneRef {
    | Some(ts) => setLocalIsAF(_ => ts.isAutoForward)
    | None => ()
    }
    None
  }, [targetSceneRef])

  // 4. Button Swap Logic (Uses localIsAF for instant feedback)
  let (centerIcon, rightIcon) = if localIsAF {
    (
      <LucideIcons.ChevronsUp.make className="text-white" size=20 strokeWidth=3.0 />,
      <LucideIcons.ChevronUp.make className="text-white" size=18 strokeWidth=3.0 />,
    )
  } else {
    (
      <LucideIcons.ChevronUp.make className="text-white" size=20 strokeWidth=3.0 />,
      <LucideIcons.ChevronsUp.make className="text-white" size=18 strokeWidth=3.0 />,
    )
  }

  // 3. Handlers
  let handleMainClick = e => {
    e->JsxEvent.Mouse.stopPropagation
    switch Belt.Array.get(state.scenes, sceneIndex) {
    | Some(currentScene) =>
      switch Belt.Array.get(currentScene.hotspots, hotspotIndex) {
      | Some(hotspot) =>
        let targetIdx = Belt.Array.getIndexBy(scenes, s => s.name == hotspot.target)
        switch targetIdx {
        | Some(tIdx) =>
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

          Navigation.navigateToScene(
            dispatch,
            state,
            tIdx,
            sceneIndex,
            hotspotIndex,
            ~targetYaw=navYaw.contents,
            ~targetPitch=navPitch.contents,
            ~targetHfov=navHfov.contents,
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
    switch targetSceneRef {
    | Some(ts) =>
      let tIdx = Belt.Array.getIndexBy(scenes, s => s.name == ts.name)
      switch tIdx {
      | Some(idx) =>
        // Start Yellow Flicker
        setFlickerYellow(_ => true)
        let _ = setTimeout(() => {
          setFlickerYellow(_ => false)
          // Start Swap Animation & Logic
          setIsSwapping(_ => true)
          let newVal = !localIsAF
          setLocalIsAF(_ => newVal)
          dispatch(Actions.UpdateSceneMetadata(idx, Logger.castToJson({"isAutoForward": newVal})))
          EventBus.dispatch(
            EventBus.ShowNotification(
              newVal ? "Auto-Forward Enabled" : "Normal Forward Set",
              #Info,
            ),
          )
          let _ = setTimeout(() => setIsSwapping(_ => false), 600)
        }, 800)
      | None => ()
      }
    | None => ()
    }
  }

  let handleDeleteClick = e => {
    e->JsxEvent.Mouse.stopPropagation
    // Start Red Flicker
    setFlickerRed(_ => true)
    let _ = setTimeout(() => {
      setFlickerRed(_ => false)
      dispatch(Actions.RemoveHotspot(sceneIndex, hotspotIndex))
      EventBus.dispatch(EventBus.ShowNotification("Hotspot Removed", #Info))
    }, 800)
  }

  let baseColor = "bg-[#ea580c]"
  let hoverColor = "hover:bg-[#f97316]"
  let makeStyle: {..} => ReactDOM.Style.t = externalObj => Obj.magic(externalObj)

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
        className={`absolute inset-0 ${baseColor} ${hoverColor} rounded-md shadow-lg flex items-center justify-center z-20 cursor-pointer transition-colors overflow-hidden ${swapClass}`}
        onClick={handleMainClick}
      >
        <div
          className="absolute inset-0 bg-gradient-to-b from-transparent via-white/25 to-transparent pointer-events-none animate-diagonal-sweep scale-[2]"
        />
        {centerIcon}
      </div>

      // RIGHT BUTTON (Toggle)
      <div
        className={`absolute inset-0 ${baseColor} ${hoverColor} rounded-md shadow-lg flex items-center justify-center z-10 cursor-pointer 
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
