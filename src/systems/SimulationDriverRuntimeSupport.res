// @efficiency-role: service-orchestrator

open Types
open Actions

@val external setTimeout: (unit => 'a, int) => int = "setTimeout"

let isStillInScene = (~scenes: array<scene>, ~state: state, ~sceneId: string): bool =>
  scenes->Belt.Array.get(state.activeIndex)->Option.map(ss => ss.id) == Some(sceneId)

let evaluateAdvanceDecision = (
  ~sceneId: string,
  ~state: state,
  ~completedSceneIdRef: React.ref<option<string>>,
  ~retryCountRef: React.ref<int>,
) => {
  let decision = SimulationAdvancement.evaluate({
    isFirstScene: state.simulation.visitedLinkIds->Belt.Array.length == 0,
    currentSceneId: Some(sceneId),
    completedSceneId: completedSceneIdRef.current,
    navigationStateIsIdle: state.navigationState.navigationFsm == IdleFsm,
    operationLifecycleIsBusy: OperationLifecycle.isBusy(~type_=Navigation, ()),
    retryCount: retryCountRef.current,
    maxRetries: 3,
  })

  Logger.info(
    ~module_="Simulation",
    ~message="=== SIM_CHECK_ADVANCE ===",
    ~data=Some({
      "isFirstScene": state.simulation.visitedLinkIds->Belt.Array.length == 0,
      "completionSceneId": completedSceneIdRef.current->Option.getOr("none"),
      "currentSceneId": sceneId,
      "shouldAdvance": switch decision {
      | Advance => true
      | _ => false
      },
      "decision": switch decision {
      | Advance => "Advance"
      | Retry(_) => "Retry"
      | Wait({reason}) => "Wait: " ++ reason
      | Stop({reason}) => "Stop: " ++ reason
      },
      "visitedCount": Belt.Array.length(state.simulation.visitedLinkIds),
    }),
    (),
  )

  decision
}

let logNextMoveResult = move => {
  Logger.info(
    ~module_="Simulation",
    ~message="=== GET_NEXT_MOVE_RESULT ===",
    ~data=Some({
      "moveType": switch move {
      | SimulationMainLogic.Move(_) => "Move"
      | SimulationMainLogic.Complete({reason}) => "Complete: " ++ reason
      | None => "None"
      },
    }),
    (),
  )
}

let handleAdvance = async (
  ~stateRef: React.ref<state>,
  ~dispatch: action => unit,
  ~navigationCompleteRef: React.ref<bool>,
  ~completedSceneIdRef: React.ref<option<string>>,
  ~cancel: ref<bool>,
  ~retryCountRef: React.ref<int>,
) => {
  retryCountRef.current = 0
  Logger.info(
    ~module_="Simulation",
    ~message="=== CALLING_GET_NEXT_MOVE ===",
    ~data=Some({"activeIndex": stateRef.current.activeIndex}),
    (),
  )
  let move = SimulationMainLogic.getNextMove(stateRef.current)
  logNextMoveResult(move)

  switch move {
  | SimulationMainLogic.Move({targetIndex, hotspotIndex, yaw, pitch, hfov, triggerActions}) =>
    navigationCompleteRef.current = false
    completedSceneIdRef.current = None
    triggerActions->Belt.Array.forEach(a => dispatch(a))
    Scene.Switcher.navigateToScene(
      dispatch,
      stateRef.current,
      targetIndex,
      stateRef.current.activeIndex,
      hotspotIndex,
      ~targetYaw=yaw,
      ~targetPitch=pitch,
      ~targetHfov=hfov,
      (),
    )
  | SimulationMainLogic.Complete({reason: _}) =>
    NotificationManager.dispatch({
      id: "",
      importance: Success,
      context: Operation("simulation"),
      message: "Simulation Complete",
      details: None,
      action: None,
      duration: NotificationTypes.defaultTimeoutMs(Success),
      dismissible: true,
      createdAt: Date.now(),
    })
    let _ = await Promise.make((resolve, _) => {
      let _ = setTimeout(resolve, Constants.Simulation.stepDelay)
    })
    if !cancel.contents {
      Scene.Switcher.cancelNavigation()
      dispatch(StopAutoPilot)
    }
  | None =>
    Scene.Switcher.cancelNavigation()
    dispatch(StopAutoPilot)
  }
}
