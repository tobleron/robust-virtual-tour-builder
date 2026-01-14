open Types
open SimulationNavigation
open SimulationChainSkipper

// --- STATE ---
// --- STATE ---
type simulationState = {
  isAutoPilot: bool,
  visitedScenes: array<int>,
  stoppingOnArrival: bool,
  skipAutoForwardGlobal: bool,
  lastAdvanceTime: float,
  pendingAdvanceId: option<int>,
  autoPilotJourneyId: int,
}

let makeInitialState = (): simulationState => {
  isAutoPilot: false,
  visitedScenes: [],
  stoppingOnArrival: false,
  skipAutoForwardGlobal: false,
  lastAdvanceTime: 0.0,
  pendingAdvanceId: None,
  autoPilotJourneyId: 0,
}

type simulationAction =
  | StartAutoPilot(int, bool) // journeyId, skipAutoForward
  | StopAutoPilot
  | AddVisitedScene(int)
  | ClearVisitedScenes
  | SetStoppingOnArrival(bool)
  | SetSkipAutoForward(bool)
  | UpdateAdvanceTime(float)
  | SetPendingAdvance(option<int>)
  | IncrementJourneyId

let reduceSimulation = (state: simulationState, action: simulationAction): simulationState => {
  Logger.debug(
    ~module_="Simulation",
    ~message="STATE_TRANSITION",
    ~data=Some(Obj.magic({"action": action, "prevState": state})),
    ()
  )

  let newState = switch action {
  | StartAutoPilot(journeyId, skip) => {
      ...state,
      isAutoPilot: true,
      autoPilotJourneyId: journeyId,
      visitedScenes: [],
      skipAutoForwardGlobal: skip,
      stoppingOnArrival: false,
    }
  | StopAutoPilot => {
      ...state,
      isAutoPilot: false,
      pendingAdvanceId: None,
      visitedScenes: [],
      stoppingOnArrival: false,
      skipAutoForwardGlobal: false,
    }
  | AddVisitedScene(sceneIdx) => {
      ...state,
      visitedScenes: Belt.Array.concat(state.visitedScenes, [sceneIdx]),
    }
  | ClearVisitedScenes => {
      ...state,
      visitedScenes: [],
    }
  | SetStoppingOnArrival(value) => {
      ...state,
      stoppingOnArrival: value,
    }
  | SetSkipAutoForward(value) => {
      ...state,
      skipAutoForwardGlobal: value,
    }
  | UpdateAdvanceTime(time) => {
      ...state,
      lastAdvanceTime: time,
    }
  | SetPendingAdvance(id) => {
      ...state,
      pendingAdvanceId: id,
    }
  | IncrementJourneyId => {
      ...state,
      autoPilotJourneyId: state.autoPilotJourneyId + 1,
    }
  }

  Logger.debug(
    ~module_="Simulation",
    ~message="STATE_UPDATED",
    ~data=Some(Obj.magic({"newState": newState})),
    ()
  )

  newState
}

let simStore = ref(makeInitialState())

let dispatch = (action: simulationAction): unit => {
  simStore := reduceSimulation(simStore.contents, action)
}

// --- BINDINGS ---
@val external document: {..} = "document"
@val external window: {..} = "window"
@val external setTimeout: (unit => 'a, int) => int = "setTimeout"
@val external clearTimeout: int => unit = "clearTimeout"

module Date = {
  @val @scope("Date") external now: unit => float = "now"
}

// --- LOGIC ---



let isAutoPilotActive = () => simStore.contents.isAutoPilot
try {
  ignore(Obj.magic(window)["isAutoPilotActive"] = isAutoPilotActive)
} catch {
| _ => ()
}

let stopAutoPilotLogic = returnToStart => {
  if simStore.contents.isAutoPilot {
    Logger.info(
      ~module_="Simulation",
      ~message="AUTOPILOT_STOP",
      ~data=Some({"returnToStart": returnToStart}),
      (),
    )

    switch simStore.contents.pendingAdvanceId {
    | Some(id) => clearTimeout(id)
    | None => ()
    }
    
    dispatch(IncrementJourneyId)
    dispatch(StopAutoPilot)

    Navigation.setSimulationMode(GlobalStateBridge.dispatch, GlobalStateBridge.getState(), false)

    // Remove class from body
    ignore(Obj.magic(document)["body"]["classList"]["remove"]("auto-pilot-active"))

    // Reset toggle button appearance
    let simToggle = Obj.magic(document)["getElementById"]("v-scene-sim-toggle")
    if Obj.magic(simToggle) != Nullable.null {
      ignore(
        simToggle["textContent"] = "",
      )
      
      let span = document["createElement"]("span")
      ignore(span["className"] = "material-icons")
      ignore(span["style"]["fontSize"] = "22px")
      ignore(span["style"]["color"] = "white")
      ignore(span["textContent"] = "play_arrow")
      ignore(simToggle["appendChild"](span))
      ignore(simToggle["style"]["removeProperty"]("background-color"))
      ignore(simToggle["style"]["setProperty"]("background-color", "#10b981", "important"))
      ignore(simToggle["title"] = "Start Auto-Pilot Simulation")
    }

    // Return to start scene if requested
    let state = GlobalStateBridge.getState()
    if returnToStart && Array.length(state.scenes) > 0 {
      GlobalStateBridge.dispatch(
        Actions.SetActiveScene(
          0,
          0.0,
          0.0,
          Some({
            type_: Some("auto-pilot-end"),
            targetHotspotIndex: -1,
            fromSceneName: None,
          }),
        ),
      )
    }

    EventBus.dispatch(ShowNotification("Simulation stopped", #Info))
  }
}

let stopAutoPilot = returnToStart => stopAutoPilotLogic(returnToStart)

let completeAutoPilot = () => {
  Logger.endOperation(
    ~module_="Simulation",
    ~operation="AUTOPILOT",
    ~data=Some({
        "scenesVisited": Array.length(simStore.contents.visitedScenes),
        "reason": "completed"
    }),
    (),
  )
  EventBus.dispatch(ShowNotification(
    "Simulation complete! Visited " ++
    Belt.Int.toString(Array.length(simStore.contents.visitedScenes)) ++ " scenes.",
    #Success,
  ))

  let _ = setTimeout(() => {
    stopAutoPilot(true)
  }, 800)
}

let advanceToNextScene = () => {
  if simStore.contents.isAutoPilot {
    let state = GlobalStateBridge.getState()
    let currentSceneOpt = Belt.Array.get(state.scenes, state.activeIndex)

    switch currentSceneOpt {
    | Some(currentScene) =>
      let nextLinkFound = findBestNextLink(currentScene, state, simStore.contents.visitedScenes)

      switch nextLinkFound {
      | Some(link) =>
        // Apply chain skipping if enabled
        let nextLink = if simStore.contents.skipAutoForwardGlobal {
          let skipResult = skipAutoForwardChain(
            link,
            state,
            simStore.contents.visitedScenes,
            sceneIdx => dispatch(AddVisitedScene(sceneIdx))
          )
          skipResult.finalLink
        } else {
          link
        }

        let hotspot = nextLink.hotspot
        let targetIndex = nextLink.targetIndex
        let hotspotIndex = nextLink.hotspotIndex

        // SYNC VISUAL PIPELINE
        let timelineItem = Js.Array.find(
          item => item.sceneId == currentScene.id && item.linkId == hotspot.linkId,
          state.timeline,
        )
        switch timelineItem {
        | Some(item) => GlobalStateBridge.dispatch(Actions.SetActiveTimelineStep(Some(item.id)))
        | None => GlobalStateBridge.dispatch(Actions.SetActiveTimelineStep(None))
        }

        if targetIndex == 0 {
          switch Belt.Array.get(state.scenes, 0) {
          | Some(startScene) =>
            let hasNewPaths = Belt.Array.some(startScene.hotspots, h => {
              let tIdx = Belt.Array.getIndexBy(state.scenes, s => s.name == h.target)
              switch tIdx {
              | Some(i) => !Js.Array.includes(i, simStore.contents.visitedScenes)
              | None => false
              }
            })

            if !hasNewPaths {
              Logger.info(~module_="Simulation", ~message="SIM_COMPLETE", ~data=Some({"reason": "returned_to_start"}), ())
              dispatch(SetStoppingOnArrival(true))
            }
          | None => ()
          }
        }

        Logger.debug(
          ~module_="Simulation", 
          ~message="SIM_STEP", 
          ~data=Some({
            "currentScene": currentScene.name,
            "nextScene": hotspot.target, 
            "visitedCount": Array.length(simStore.contents.visitedScenes)
          }), 
          ()
        )

        let (tYaw, tPitch, tHfov) = if nextLink.isReturn {
          switch hotspot.returnViewFrame {
          | Some(vf) => (vf.yaw, vf.pitch, vf.hfov)
          | None => (0.0, 0.0, 90.0)
          }
        } else {
          switch hotspot.viewFrame {
          | Some(vf) => (vf.yaw, vf.pitch, vf.hfov)
          | None =>
            switch hotspot.targetYaw {
            | Some(y) => (
                y,
                switch hotspot.targetPitch {
                | Some(p) => p
                | None => 0.0
                },
                switch hotspot.targetHfov {
                | Some(h) => h
                | None => 90.0
                },
              )
            | None => (0.0, 0.0, 90.0)
            }
          }
        }

        Navigation.navigateToScene(
          GlobalStateBridge.dispatch,
          state,
          targetIndex,
          state.activeIndex,
          hotspotIndex,
          ~targetYaw=tYaw,
          ~targetPitch=tPitch,
          ~targetHfov=tHfov,
          (),
        )

      | None =>
        Logger.endOperation(
          ~module_="Simulation", 
          ~operation="AUTOPILOT", 
          ~data=Some({"reason": "no_reachable_scenes", "scenesVisited": Array.length(simStore.contents.visitedScenes)}), 
          ()
        )
        completeAutoPilot()
      }

    | None => completeAutoPilot()
    }
  }
}

let onSceneArrival = (sceneIndex, _isChainEnd) => {
  if simStore.contents.isAutoPilot {
    Logger.debug(~module_="Simulation", ~message="SCENE_ARRIVED", ~data=Some({"sceneIndex": sceneIndex}), ())

    if simStore.contents.stoppingOnArrival {
      dispatch(SetStoppingOnArrival(false))
      completeAutoPilot()
    } else {
      switch simStore.contents.pendingAdvanceId {
      | Some(id) => clearTimeout(id)
      | None => ()
      }
      dispatch(SetPendingAdvance(None))

      let now = Date.now()
      if now -. simStore.contents.lastAdvanceTime < 300.0 {
        Logger.warn(~module_="Simulation", ~message="ARRIVAL_DEBOUNCED", ())
      } else {
        dispatch(UpdateAdvanceTime(now))

        if !Js.Array.includes(sceneIndex, simStore.contents.visitedScenes) {
          dispatch(AddVisitedScene(sceneIndex))
        }

        let state = GlobalStateBridge.getState()
        switch Belt.Array.get(state.scenes, sceneIndex) {
        | Some(currentScene) =>
          let isBridge = currentScene.isAutoForward

          let delay = if simStore.contents.skipAutoForwardGlobal && isBridge {
            0
          } else {
            500
          }

          dispatch(SetPendingAdvance(Some(setTimeout(async () => {
              try {
                let _ = await waitForViewerScene(sceneIndex, () => simStore.contents.isAutoPilot)
                // Accessing ref in closure is safe
                if simStore.contents.isAutoPilot && !simStore.contents.stoppingOnArrival {
                  advanceToNextScene()
                }
              } catch {
              | e =>
                if simStore.contents.isAutoPilot {
                  Logger.error(
                    ~module_="Simulation",
                    ~message="SCENE_ARRIVAL_FAILED",
                    ~data=Some({"error": e}),
                    (),
                  )
                  completeAutoPilot()
                }
              }
            }, delay))))
        | None => ()
        }
      }
    }
  }
}

let startAutoPilot = skipAutoForward => {
  let state = GlobalStateBridge.getState()
  if Array.length(state.scenes) == 0 {
    EventBus.dispatch(ShowNotification("No scenes to simulate", #Warning))
  } else {
    Logger.startOperation(
        ~module_="Simulation", 
        ~operation="AUTOPILOT", 
        ~data=Some({
            "startScene": switch Belt.Array.get(state.scenes, state.activeIndex) {
                | Some(s) => s.name
                | None => "unknown"
            }, 
            "mode": "auto"
        }), 
        ()
    )



    dispatch(IncrementJourneyId)
    dispatch(StartAutoPilot(simStore.contents.autoPilotJourneyId, switch skipAutoForward {
    | Some(b) => b
    | None => false
    }))

    Navigation.setSimulationMode(GlobalStateBridge.dispatch, state, true)

    ignore(Obj.magic(document)["body"]["classList"]["add"]("auto-pilot-active"))

    // Update toggle button appearance
    let simToggle = Obj.magic(document)["getElementById"]("v-scene-sim-toggle")
    if Obj.magic(simToggle) != Nullable.null {
      ignore(
        simToggle["textContent"] = "",
      )

      let span = document["createElement"]("span")
      ignore(span["className"] = "material-icons")
      ignore(span["style"]["fontSize"] = "22px")
      ignore(span["style"]["color"] = "white")
      ignore(span["textContent"] = "stop")
      ignore(simToggle["appendChild"](span))
      ignore(simToggle["style"]["removeProperty"]("background-color"))
      ignore(simToggle["style"]["setProperty"]("background-color", "#dc3545", "important"))
      ignore(simToggle["title"] = "Click to Stop Simulation")
      ignore(simToggle["offsetHeight"])
    }

    if state.activeIndex != 0 {
      GlobalStateBridge.dispatch(
        Actions.SetActiveScene(
          0,
          0.0,
          0.0,
          Some({
            type_: Some("auto-pilot-start"),
            targetHotspotIndex: -1,
            fromSceneName: None,
          }),
        ),
      )
    }

    dispatch(AddVisitedScene(0))

    switch simStore.contents.pendingAdvanceId {
    | Some(id) => clearTimeout(id)
    | None => ()
    }

    dispatch(SetPendingAdvance(Some(setTimeout(() => {
        advanceToNextScene()
      }, 800))))

    EventBus.dispatch(ShowNotification("Auto-pilot started", #Success))
  }
}

let initSimulationKeyHandler = () => {
  // Navigation arrival handled via React effects in ViewerManager or state observation
  Logger.initialized(~module_="Simulation")
}

// Re-export from SimulationPathGenerator for backward compatibility
let getSimulationPath = SimulationPathGenerator.getSimulationPath
