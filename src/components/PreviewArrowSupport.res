open Types

let canProceed = (~capability: Capability.capability, ~context: string): bool => {
  let currentState = AppContext.getBridgeState()
  let allowed = Capability.Policy.evaluate(
    ~capability,
    ~appMode=currentState.appMode,
    OperationLifecycle.getOperations(),
  )
  if !allowed {
    NotificationManager.dispatch({
      id: "",
      importance: Warning,
      context: Operation(context),
      message: "Please wait for current operation to finish",
      details: None,
      action: None,
      duration: NotificationTypes.defaultTimeoutMs(Warning),
      dismissible: true,
      createdAt: Date.now(),
    })
  }
  allowed
}

let handleMainClick = (
  e,
  ~sceneIndex: int,
  ~hotspotIndex: int,
  ~dispatch: Actions.action => unit,
  ~isMovingThis: bool,
): unit => {
  e->JsxEvent.Mouse.stopPropagation
  if !canProceed(~capability=CanNavigate, ~context="preview_arrow_navigate") {
    ()
  } else if isMovingThis {
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
          let (ny, np, nh) = PreviewArrowNav.calculateNavParams(hotspot)
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

let handleRightClick = (
  e,
  ~sceneIndex: int,
  ~hotspotIndex: int,
  ~localIsAF: bool,
  ~toggleInFlightRef: React.ref<bool>,
  ~setFlickerYellow: (bool => bool) => unit,
  ~setIsSwapping: (bool => bool) => unit,
  ~setLocalIsAF: (bool => bool) => unit,
  ~dispatch: Actions.action => unit,
): unit => {
  e->JsxEvent.Mouse.stopPropagation
  if !canProceed(~capability=CanEditHotspots, ~context="preview_arrow") {
    ()
  } else {
    let currentState = AppContext.getBridgeState()
    let isMovingAny = currentState.movingHotspot != None

    if isMovingAny || toggleInFlightRef.current {
      ()
    } else {
      let activeScenesForGuard = SceneInventory.getActiveScenes(
        currentState.inventory,
        currentState.sceneOrder,
      )
      let canEnableAutoForward = HotspotHelpers.canEnableAutoForward(
        activeScenesForGuard,
        sceneIndex,
        hotspotIndex,
      )

      let newVal = !localIsAF
      if newVal && !canEnableAutoForward {
        NotificationManager.dispatch({
          id: "autoforward-validation-error",
          importance: Error,
          context: Operation("hotspot_action"),
          message: "Only one auto-forward link per scene",
          details: Some(
            "Disable auto-forward on the existing link first, then enable it on this link.",
          ),
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Error),
          dismissible: true,
          createdAt: Date.now(),
        })
      } else {
        toggleInFlightRef.current = true
        setFlickerYellow(_ => true)

        dispatch(
          Actions.UpdateHotspotMetadata(
            sceneIndex,
            hotspotIndex,
            Logger.castToJson({"isAutoForward": newVal}),
          ),
        )

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
          setFlickerYellow(_ => false)
          setIsSwapping(_ => true)
          let _ = setTimeout(() => {
            setLocalIsAF(_ => newVal)
            let _ = setTimeout(
              () => {
                setIsSwapping(_ => false)
                toggleInFlightRef.current = false
              },
              40,
            )
          }, 920)
        }, 800)
      }
    }
  }
}

let handleDeleteClick = (
  e,
  ~sceneIndex: int,
  ~hotspotIndex: int,
  ~dispatch: Actions.action => unit,
  ~setFlickerRed: (bool => bool) => unit,
  ~setIsDeleteCollapsing: (bool => bool) => unit,
  ~setIsDeleting: (bool => bool) => unit,
): unit => {
  e->JsxEvent.Mouse.stopPropagation
  if !canProceed(~capability=CanMutateProject, ~context="preview_arrow") {
    ()
  } else {
    let currentState = AppContext.getBridgeState()
    let isMovingAny = currentState.movingHotspot != None

    if isMovingAny {
      ()
    } else {
      setFlickerRed(_ => true)
      let _ = setTimeout(() => {
        setFlickerRed(_ => false)
        let _ = setTimeout(() => {
          setIsDeleteCollapsing(_ => true)
          let _ = setTimeout(
            () => {
              setIsDeleting(_ => true)
              let _ = setTimeout(
                () => {
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
                },
                320,
              )
            },
            320,
          )
        }, 40)
      }, 800)
    }
  }
}

let handleMoveClick = (
  e,
  ~sceneIndex: int,
  ~hotspotIndex: int,
  ~dispatch: Actions.action => unit,
): unit => {
  e->JsxEvent.Mouse.stopPropagation
  if !canProceed(~capability=CanMutateProject, ~context="preview_arrow") {
    ()
  } else {
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
}

let handleRetargetClick = (e, ~sceneIndex: int, ~hotspotIndex: int): unit => {
  e->JsxEvent.Mouse.stopPropagation
  if !canProceed(~capability=CanMutateProject, ~context="preview_arrow") {
    ()
  } else {
    let currentState = AppContext.getBridgeState()
    let activeScenes = SceneInventory.getActiveScenes(
      currentState.inventory,
      currentState.sceneOrder,
    )
    switch Belt.Array.get(activeScenes, sceneIndex) {
    | Some(scene) =>
      switch Belt.Array.get(scene.hotspots, hotspotIndex) {
      | Some(h) =>
        let draft: Types.linkDraft = {
          pitch: h.pitch,
          yaw: h.yaw,
          camPitch: h.viewFrame->Option.map(vf => vf.pitch)->Option.getOr(h.pitch),
          camYaw: h.viewFrame->Option.map(vf => vf.yaw)->Option.getOr(h.yaw),
          camHfov: h.viewFrame->Option.map(vf => vf.hfov)->Option.getOr(90.0),
          intermediatePoints: None,
          retargetHotspot: Some({
            sceneIndex,
            hotspotIndex,
            sceneId: Some(scene.id),
            hotspotLinkId: Some(h.linkId),
          }),
        }
        EventBus.dispatch(TriggerRetargetModal(draft))
      | None => ()
      }
    | None => ()
    }
  }
}
