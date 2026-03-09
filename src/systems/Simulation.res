/* src/systems/Simulation.res - Consolidated Simulation System */

open Types
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
    SimulationDriverRuntime.runEffect(
      ~simulation,
      ~activeIndex,
      ~dispatch,
      ~stateRef,
      ~runIdRef,
      ~advancingForSceneId,
      ~navigationCompleteRef,
      ~completedSceneIdRef,
      ~retryCountRef,
      ~triggerValue=triggerRef.current,
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
