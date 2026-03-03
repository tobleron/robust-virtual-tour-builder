/* src/systems/Simulation.res - Consolidated Simulation System */

open Types
open Actions
include SimulationLogic

// --- BINDINGS (INTERNAL) ---
@val external setTimeout: (unit => 'a, int) => int = "setTimeout"

// --- REACT COMPONENT: DRIVER ---

@react.component
let make = () => {
  let state = AppContext.useAppState()
  let dispatch = AppContext.useAppDispatch()

  // Safe state access
  let simulation = state.simulation
  let activeIndex = state.activeIndex

  let stateRef = React.useRef(state)
  let runIdRef = React.useRef(0)
  let opIdRef = React.useRef(None)

  // Scene-ID based tracking (more reliable than index during async operations)
  let advancingForSceneId = React.useRef(None)

  // Event-driven completion signal
  let navigationCompleteRef = React.useRef(false)
  let completedSceneIdRef = React.useRef(None)

  // Retry tracking for debounced recovery
  let retryCountRef = React.useRef(0)

  // Trigger ref - incremented when navigation completes to force effect re-run
  let triggerRef = React.useRef(0)

  // Track if viewer has been initialized
  let viewerInitialized = React.useRef(false)

  React.useEffect1(() => {
    stateRef.current = state
    None
  }, [state])

  // Initialize viewer if not already done
  React.useEffect0(() => {
    if !viewerInitialized.current && state.activeIndex >= 0 {
      viewerInitialized.current = true
      // Ensure background viewer exists before simulation starts
      Scene.Loader.ensureBackgroundViewer(~_state=state, ~_dispatch=dispatch)
    }
    None
  })

  // Subscribe to navigation completion events
  React.useEffect0(() => {
    let unsubscribe = EventBus.subscribe(e => {
      switch e {
      | SimulationAdvanceComplete({sceneId, sceneIndex}) =>
        let currentState = stateRef.current
        if currentState.simulation.status == Running {
          // Record completion by sceneId; tick logic decides if it matches current scene.
          completedSceneIdRef.current = Some(sceneId)
          navigationCompleteRef.current = true
          retryCountRef.current = 0

          // Trigger effect re-run
          triggerRef.current = triggerRef.current + 1

          let scenes = SceneInventory.getActiveScenes(
            currentState.inventory,
            currentState.sceneOrder,
          )
          let activeSceneId =
            scenes->Belt.Array.get(currentState.activeIndex)->Option.map(s => s.id)
          Logger.debug(
            ~module_="Simulation",
            ~message="SIMULATION_ADVANCE_EVENT_RECEIVED",
            ~data=Some({
              "eventSceneId": sceneId,
              "eventSceneIndex": sceneIndex,
              "activeSceneId": activeSceneId->Option.getOr("none"),
            }),
            (),
          )
        } else {
          Logger.debug(
            ~module_="Simulation",
            ~message="SIMULATION_ADVANCE_EVENT_IGNORED_NOT_RUNNING",
            ~data=Some({
              "eventSceneId": sceneId,
              "eventSceneIndex": sceneIndex,
              "status": currentState.simulation.status == Running ? "Running" : "Stopped",
            }),
            (),
          )
        }
      | _ => ()
      }
    })
    Some(unsubscribe)
  })

  // Operation Lifecycle Sync
  React.useEffect1(() => {
    if simulation.status == Running {
      if opIdRef.current == None {
        opIdRef.current = Some(
          OperationLifecycle.start(~type_=Simulation, ~scope=Ambient, ~phase="Running", ()),
        )
      }
    } else {
      switch opIdRef.current {
      | Some(id) =>
        OperationLifecycle.complete(id, ())
        opIdRef.current = None
      | None => ()
      }
    }
    None
  }, [simulation.status])

  React.useEffect3(() => {
    let cancel = ref(false)

    Logger.info(
      ~module_="Simulation",
      ~message="=== SIM_EFFECT_RUN ===",
      ~data=Some({
        "status": simulation.status == Running ? "Running" : "Stopped",
        "activeIndex": state.activeIndex,
        "advancingForSceneId": advancingForSceneId.current,
        "navigationComplete": navigationCompleteRef.current,
        "visitedLinkIds": state.simulation.visitedLinkIds,
        "triggerRef": triggerRef.current,
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
          // Scene-ID based tracking (more reliable than index during async operations)
          if advancingForSceneId.current != Some(sceneId) {
            advancingForSceneId.current = Some(sceneId)
            // Don't reset navigationCompleteRef - it was set by SimulationAdvanceComplete event

            let _delay = if stateRef.current.simulation.skipAutoForwardGlobal {
              switch scenes->Belt.Array.getBy(ss => ss.id == sceneId) {
              | Some(scene) =>
                let hasAutoForwardLink = Belt.Array.some(scene.hotspots, h =>
                  switch h.isAutoForward {
                  | Some(true) => true
                  | _ => false
                  }
                )
                if hasAutoForwardLink || scene.isAutoForward {
                  0
                } else {
                  Constants.Simulation.stepDelay
                }
              | _ => Constants.Simulation.stepDelay
              }
            } else {
              Constants.Simulation.stepDelay
            }

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
                let waitResult = await Navigation.waitForViewerScene(
                  stateRef.current.activeIndex,
                  () => isCurrentRun() && stateRef.current.simulation.status == Running,
                  ~currentRunId,
                  ~getRunId=() => runIdRef.current,
                  ~getState=() => stateRef.current,
                  (),
                )

                // Re-resolve state after delay
                let sAfterWait = stateRef.current
                let stillOk =
                  isCurrentRun() &&
                  sAfterWait.simulation.status == Running &&
                  scenes
                  ->Belt.Array.get(sAfterWait.activeIndex)
                  ->Option.map(ss => ss.id) == Some(sceneId)

                if stillOk {
                  let isFirstLink = sAfterWait.simulation.visitedLinkIds->Belt.Array.length <= 1
                  let delay = if sAfterWait.simulation.skipAutoForwardGlobal {
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

                  if delay > 0 {
                    let _ = await Promise.make((resolve, _) => {
                      let _ = setTimeout(resolve, delay)
                    })
                  }
                }

                // Final check before advancing
                let sFinal = stateRef.current
                let finalOk =
                  isCurrentRun() &&
                  sFinal.simulation.status == Running &&
                  scenes
                  ->Belt.Array.get(sFinal.activeIndex)
                  ->Option.map(ss => ss.id) == Some(sceneId)

                switch waitResult {
                | Ok()
                  if finalOk &&
                  sFinal.navigationState.navigationFsm == IdleFsm &&
                  !OperationLifecycle.isBusy(~type_=Navigation, ()) =>
                  // For first scene, proceed immediately. For subsequent scenes, wait for navigation completion signal
                  let isFirstScene = sFinal.simulation.visitedLinkIds->Belt.Array.length == 0
                  let hasSceneCompletionSignal = completedSceneIdRef.current == Some(sceneId)
                  let shouldAdvance = isFirstScene || hasSceneCompletionSignal

                  Logger.info(
                    ~module_="Simulation",
                    ~message="=== SIM_CHECK_ADVANCE ===",
                    ~data=Some({
                      "isFirstScene": isFirstScene,
                      "navigationComplete": navigationCompleteRef.current,
                      "completionSceneId": completedSceneIdRef.current->Option.getOr("none"),
                      "currentSceneId": sceneId,
                      "hasSceneCompletionSignal": hasSceneCompletionSignal,
                      "shouldAdvance": shouldAdvance,
                      "visitedCount": Belt.Array.length(sFinal.simulation.visitedLinkIds),
                      "visitedLinkIds": sFinal.simulation.visitedLinkIds,
                      "activeIndex": sFinal.activeIndex,
                    }),
                    (),
                  )

                  if shouldAdvance {
                    retryCountRef.current = 0
                    Logger.info(
                      ~module_="Simulation",
                      ~message="=== CALLING_GET_NEXT_MOVE ===",
                      ~data=Some({"activeIndex": sFinal.activeIndex}),
                      (),
                    )
                    let move = Logic.getNextMove(sFinal)
                    Logger.info(
                      ~module_="Simulation",
                      ~message="=== GET_NEXT_MOVE_RESULT ===",
                      ~data=Some({
                        "moveType": switch move {
                        | Move(_) => "Move"
                        | Complete({reason}) => "Complete: " ++ reason
                        | None => "None"
                        },
                      }),
                      (),
                    )
                    switch move {
                    | Move({targetIndex, hotspotIndex, yaw, pitch, hfov, triggerActions}) =>
                      // Reset navigationCompleteRef so we wait for the next scene transition
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
                    | Complete({reason: _reason}) =>
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
                  } else {
                    // Not ready to advance yet - retry with backoff
                    advancingForSceneId.current = None
                    retryCountRef.current = retryCountRef.current + 1
                    let maxRetries = 3
                    if retryCountRef.current <= maxRetries {
                      let backoffMs = 100 * retryCountRef.current
                      let _ = ReBindings.Window.setTimeout(() => {
                        advancingForSceneId.current = None
                      }, backoffMs)
                    } else {
                      Scene.Switcher.cancelNavigation()
                      dispatch(StopAutoPilot)
                    }
                  }
                | Ok() =>
                  // Navigation didn't complete - retry with backoff
                  advancingForSceneId.current = None
                  retryCountRef.current = retryCountRef.current + 1
                  let maxRetries = 3
                  if retryCountRef.current <= maxRetries {
                    let backoffMs = 100 * retryCountRef.current
                    let _ = ReBindings.Window.setTimeout(() => {
                      advancingForSceneId.current = None
                    }, backoffMs)
                  } else {
                    Scene.Switcher.cancelNavigation()
                    dispatch(StopAutoPilot)
                  }
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
                  Scene.Switcher.cancelNavigation()
                  dispatch(StopAutoPilot)
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
  }, (simulation.status, activeIndex, triggerRef.current))

  // Cleanup on unmount
  React.useEffect0(() => {
    Some(
      () => {
        switch opIdRef.current {
        | Some(id) =>
          OperationLifecycle.cancel(id)
          opIdRef.current = None
        | None => ()
        }
      },
    )
  })

  React.null
}
