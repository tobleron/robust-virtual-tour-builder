open Types
open Actions

@val external setTimeout: (unit => 'a, int) => int = "setTimeout"

let stopSimulation = dispatch => {
  Scene.Switcher.cancelNavigation()
  dispatch(StopAutoPilot)
}

let scheduleAdvanceRetryReset = (~advancingForSceneId: React.ref<option<string>>, backoffMs) => {
  let _ = ReBindings.Window.setTimeout(() => {
    advancingForSceneId.current = None
  }, backoffMs)
}

let handleIncrementalRetry = (
  ~advancingForSceneId: React.ref<option<string>>,
  ~retryCountRef: React.ref<int>,
  ~dispatch: action => unit,
) => {
  advancingForSceneId.current = None
  retryCountRef.current = retryCountRef.current + 1

  let maxRetries = 3
  if retryCountRef.current <= maxRetries {
    let backoffMs = 100 * retryCountRef.current
    scheduleAdvanceRetryReset(~advancingForSceneId, backoffMs)
  } else {
    stopSimulation(dispatch)
  }
}

let resolveAdvanceDelay = (
  ~scenes: array<scene>,
  ~sceneId,
  ~skipAutoForwardGlobal,
  ~isFirstLink,
): int => {
  if skipAutoForwardGlobal {
    switch scenes->Belt.Array.getBy(ss => ss.id == sceneId) {
    | Some(scene) =>
      let hasAutoForwardLink = Belt.Array.some(scene.hotspots, h =>
        switch h.isAutoForward {
        | Some(true) => true
        | _ => false
        }
      )

      if hasAutoForwardLink || scene.isAutoForward {
        isFirstLink ? 3000 : 0
      } else {
        Constants.Simulation.stepDelay
      }
    | _ => Constants.Simulation.stepDelay
    }
  } else {
    Math.max(Constants.Simulation.stepDelay->Int.toFloat, 3000.0)->Float.toInt
  }
}

let runEffect = (
  ~simulation: simulationState,
  ~activeIndex,
  ~dispatch: action => unit,
  ~stateRef: React.ref<state>,
  ~runIdRef: React.ref<int>,
  ~advancingForSceneId: React.ref<option<string>>,
  ~navigationCompleteRef: React.ref<bool>,
  ~completedSceneIdRef: React.ref<option<string>>,
  ~retryCountRef: React.ref<int>,
  ~triggerValue,
) => {
  let cancel = ref(false)

  Logger.info(
    ~module_="Simulation",
    ~message="=== SIM_EFFECT_RUN ===",
    ~data=Some({
      "status": simulation.status == Running ? "Running" : "Stopped",
      "activeIndex": activeIndex,
      "advancingForSceneId": advancingForSceneId.current,
      "navigationComplete": navigationCompleteRef.current,
      "visitedLinkIds": stateRef.current.simulation.visitedLinkIds,
      "triggerRef": triggerValue,
    }),
    (),
  )

  if simulation.status == Running {
    runIdRef.current = runIdRef.current + 1
    let currentRunId = runIdRef.current

    let runTick = async () => {
      let isCurrentRun = () => !cancel.contents && runIdRef.current == currentRunId
      let s = stateRef.current
      let scenes = SceneInventory.getActiveScenes(s.inventory, s.sceneOrder)
      let currentSceneId = scenes->Belt.Array.get(s.activeIndex)->Option.map(ss => ss.id)

      switch currentSceneId {
      | None => ()
      | Some(sceneId) =>
        if advancingForSceneId.current != Some(sceneId) {
          advancingForSceneId.current = Some(sceneId)

          let sAfterInitial = stateRef.current
          let stillRunning =
            isCurrentRun() &&
            sAfterInitial.simulation.status == Running &&
            !sAfterInitial.simulation.stoppingOnArrival
          let stillInSameScene =
            scenes
            ->Belt.Array.get(sAfterInitial.activeIndex)
            ->Option.map(ss => ss.id) == Some(sceneId)

          if stillRunning && stillInSameScene {
            try {
              let waitResult = await SimulationNavigation.waitForViewerScene(
                stateRef.current.activeIndex,
                () => isCurrentRun() && stateRef.current.simulation.status == Running,
                ~currentRunId,
                ~getRunId=() => runIdRef.current,
                ~getState=() => stateRef.current,
                (),
              )

              let sAfterWait = stateRef.current
              let stillOk =
                isCurrentRun() &&
                sAfterWait.simulation.status == Running &&
                SimulationDriverRuntimeSupport.isStillInScene(~scenes, ~state=sAfterWait, ~sceneId)

              if stillOk {
                let isFirstLink = sAfterWait.simulation.visitedLinkIds->Belt.Array.length <= 1
                let delay = resolveAdvanceDelay(
                  ~scenes,
                  ~sceneId,
                  ~skipAutoForwardGlobal=sAfterWait.simulation.skipAutoForwardGlobal,
                  ~isFirstLink,
                )

                if delay > 0 {
                  let _ = await Promise.make((resolve, _) => {
                    let _ = setTimeout(resolve, delay)
                  })
                }
              }

              let sFinal = stateRef.current
              let finalOk =
                isCurrentRun() &&
                sFinal.simulation.status == Running &&
                SimulationDriverRuntimeSupport.isStillInScene(~scenes, ~state=sFinal, ~sceneId)

              switch waitResult {
              | Ok() if finalOk =>
                let decision = SimulationDriverRuntimeSupport.evaluateAdvanceDecision(
                  ~sceneId,
                  ~state=sFinal,
                  ~completedSceneIdRef,
                  ~retryCountRef,
                )

                switch decision {
                | Advance =>
                  await SimulationDriverRuntimeSupport.handleAdvance(
                    ~stateRef,
                    ~dispatch,
                    ~navigationCompleteRef,
                    ~completedSceneIdRef,
                    ~cancel,
                    ~retryCountRef,
                  )
                | Retry({count, backoffMs}) =>
                  advancingForSceneId.current = None
                  retryCountRef.current = count
                  scheduleAdvanceRetryReset(~advancingForSceneId, backoffMs)
                | Wait({reason: _}) =>
                  handleIncrementalRetry(~advancingForSceneId, ~retryCountRef, ~dispatch)
                | Stop({reason: _}) => stopSimulation(dispatch)
                }
              | Ok() => handleIncrementalRetry(~advancingForSceneId, ~retryCountRef, ~dispatch)
              | Error(msg) =>
                NotificationManager.dispatch({
                  id: "",
                  importance: Error,
                  context: Operation("simulation"),
                  message: "Simulation error: " ++ msg,
                  details: None,
                  action: None,
                  duration: NotificationTypes.defaultTimeoutMs(Error),
                  dismissible: true,
                  createdAt: Date.now(),
                })
                advancingForSceneId.current = None
                stopSimulation(dispatch)
              }
            } catch {
            | err =>
              let (_msg, _) = LoggerCommon.getErrorDetails(err)
              advancingForSceneId.current = None
              dispatch(StopAutoPilot)
            }
          } else if isCurrentRun() {
            advancingForSceneId.current = None
          }
        }
      }
    }

    let _ = runTick()
  } else {
    runIdRef.current = runIdRef.current + 1
    advancingForSceneId.current = None
    navigationCompleteRef.current = false
    completedSceneIdRef.current = None
  }

  Some(
    () => {
      cancel := true
    },
  )
}
