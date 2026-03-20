external makeStyle: {..} => ReactDOM.Style.t = "%identity"

module Logic = {
  let calculateNavParams = (hotspot: Types.hotspot) => PreviewArrowNav.calculateNavParams(hotspot)
}

@react.component
let make = (
  ~sceneIndex: int,
  ~hotspotIndex: int,
  ~dispatch: Actions.action => unit,
  ~elementId: string,
  ~isTargetAutoForward as initialAF: bool,
  ~sequenceLabel: option<int>,
  ~isReturnNode: bool,
  ~scenes as _scenes: array<Types.scene>,
  ~state as _stateProp: Types.state,
  ~isDrawerOpen=false,
  ~onDrawerEnter=?,
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
  let centerContent = if isMovingThis {
    <LucideIcons.Move.make className="text-white" size=20 strokeWidth={3.0} />
  } else if isReturnNode {
    <span className="hs-hotspot-face-text is-return"> {React.string("R")} </span>
  } else {
    switch sequenceLabel {
    | Some(sequenceNo) =>
      <span className="hs-hotspot-face-text"> {React.string(Int.toString(sequenceNo))} </span>
    | None =>
      if localIsAF {
        <LucideIcons.ChevronsRight.make className="text-white" size=20 strokeWidth={3.0} />
      } else {
        <LucideIcons.ChevronUp.make className="text-white" size=20 strokeWidth={3.0} />
      }
    }
  }

  let rightIcon = if isMovingThis {
    <LucideIcons.ChevronUp.make className="text-white" size=18 strokeWidth={3.0} />
  } else if localIsAF {
    <LucideIcons.ChevronUp.make className="text-white" size=18 strokeWidth={3.0} />
  } else {
    <LucideIcons.ChevronsRight.make className="text-white" size=18 strokeWidth={3.0} />
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

  let centerStateClass = if isMovingThis {
    "is-moving"
  } else if localIsAF {
    "is-autoforward"
  } else {
    "is-manual"
  }

  let rightStateClass = if !localIsAF {
    "is-autoforward-target"
  } else {
    "is-manual-target"
  }

  let swapClass = isSwapping ? "animate-swap-icon" : ""
  let keepDrawerOpen = () =>
    switch onDrawerEnter {
    | Some(fn) => fn()
    | None => ()
    }

  <div
    id=elementId
    className={`absolute top-0 left-0 z-[6000] ${isMovingThis
        ? "pointer-events-none"
        : "group pointer-events-auto"} ${isDrawerOpen
        ? "hs-hotspot-drawer-open"
        : ""} origin-center transition-opacity duration-300 -translate-x-1/2 -translate-y-1/2`}
    style={makeStyle({
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
        className={`hs-hotspot-control hs-hotspot-control--center absolute inset-0 rounded-md flex items-center justify-center z-20 overflow-hidden ${centerStateClass} ${swapClass} ${flickerMove
            ? "animate-flicker-yellow-flat"
            : ""} ${isMovingThis ? "pointer-events-none" : "cursor-pointer"}`}
        onClick={e =>
          PreviewArrowSupport.handleMainClick(
            e,
            ~sceneIndex,
            ~hotspotIndex,
            ~dispatch,
            ~isMovingThis,
          )}
      >
        {!isMovingThis
          ? <div
              className="absolute inset-0 bg-gradient-to-b from-transparent via-white/25 to-transparent pointer-events-none animate-diagonal-sweep scale-[2]"
            />
          : React.null}
        {centerContent}
      </div>

      {!isMovingThis
        ? <>
            // RIGHT BUTTON (Toggle)
            <div
              className={`hs-hotspot-control hs-hotspot-control--secondary hs-hotspot-control--toggle absolute inset-0 rounded-md flex items-center justify-center z-10 cursor-pointer 
                         transition-all duration-300 ease-out 
                         opacity-0 translate-x-0
                         group-hover:opacity-100 group-hover:translate-x-[105%]
                         ${rightStateClass} ${flickerYellow ? "animate-flicker-yellow" : ""} ${swapClass}`}
              onMouseEnter={_ => keepDrawerOpen()}
              onClick={e =>
                PreviewArrowSupport.handleRightClick(
                  e,
                  ~sceneIndex,
                  ~hotspotIndex,
                  ~localIsAF,
                  ~toggleInFlightRef,
                  ~setFlickerYellow,
                  ~setIsSwapping,
                  ~setLocalIsAF,
                  ~dispatch,
                )}
            >
              {rightIcon}
            </div>
            // BOTTOM BUTTON (Move)
            <div
              className={`hs-hotspot-control hs-hotspot-control--secondary hs-hotspot-control--move absolute inset-0 rounded-md flex items-center justify-center z-10 cursor-pointer 
                         transition-all duration-300 ease-out 
                         opacity-0 translate-y-0
                         group-hover:opacity-100 group-hover:translate-y-[105%] ${isMovingThis ? "is-moving" : ""}`}
              onMouseEnter={_ => keepDrawerOpen()}
              onClick={e =>
                PreviewArrowSupport.handleMoveClick(e, ~sceneIndex, ~hotspotIndex, ~dispatch)}
              title={isMovingThis ? "Cancel Move" : "Move Hotspot"}
            >
              {isMovingThis
                ? <LucideIcons.X.make className="text-white" size={14} strokeWidth={3.0} />
                : <LucideIcons.Move.make className="text-white" size={14} strokeWidth={3.0} />}
            </div>
            // RETARGET BUTTON (#)
            <div
              className={`hs-hotspot-control hs-hotspot-control--secondary hs-hotspot-control--retarget absolute inset-0 rounded-md flex items-center justify-center z-10 cursor-pointer 
                         transition-all duration-300 ease-out 
                         opacity-0 translate-y-0
                         group-hover:opacity-100 group-hover:translate-y-[210%]`}
              onMouseEnter={_ => keepDrawerOpen()}
              onClick={e => PreviewArrowSupport.handleRetargetClick(e, ~sceneIndex, ~hotspotIndex)}
              title="Change Target Scene"
            >
              <span className="text-white font-black text-[16px] leading-none mb-0.5">
                {React.string("#")}
              </span>
            </div>
            // LEFT BUTTON (Delete)
            <div
              className={`hs-hotspot-control hs-hotspot-control--secondary hs-hotspot-control--delete absolute inset-0 rounded-md flex items-center justify-center z-10 cursor-pointer
                         transition-all duration-300 ease-out 
                         opacity-0 translate-x-0
                         group-hover:opacity-100 group-hover:translate-x-[-105%]
                         ${flickerRed ? "animate-flicker-red" : ""}`}
              onMouseEnter={_ => keepDrawerOpen()}
              onClick={e =>
                PreviewArrowSupport.handleDeleteClick(
                  e,
                  ~sceneIndex,
                  ~hotspotIndex,
                  ~dispatch,
                  ~setFlickerRed,
                )}
              title="Delete Hotspot"
            >
              <LucideIcons.Trash2.make className="text-white" size=14 strokeWidth=3.0 />
            </div>
          </>
        : React.null}
    </div>
  </div>
}
