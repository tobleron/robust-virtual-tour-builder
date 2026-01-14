open ReBindings
open Types

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

module LocalViewerBindings = {
  type t = Viewer.t
  @send external isLoaded: t => bool = "isLoaded"
  @get external sceneId: t => string = "_sceneId"
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

let waitForViewerScene = async sceneIndex => {
  let state = GlobalStateBridge.getState()
  switch Belt.Array.get(state.scenes, sceneIndex) {
  | Some(expectedScene) =>
    let timeout = 8000.0
    let start = Date.now()
    let loop = ref(true)

    while loop.contents {
      if !simStore.contents.isAutoPilot {
        loop := false
      } else if Date.now() -. start > timeout {
        loop := false
        JsError.throwWithMessage("Timeout waiting for viewer to load scene " ++ expectedScene.name)
      } else {
        let v = Nullable.toOption(Viewer.instance)
        switch v {
        | Some(viewer) =>
          let sceneId = LocalViewerBindings.sceneId(viewer)
          if sceneId == expectedScene.id && LocalViewerBindings.isLoaded(viewer) {
            loop := false
          } else {
            let _ = await Promise.make((resolve, _reject) => {
              let _ = setTimeout(() => resolve(), 100)
            })
          }
        | None =>
          let _ = await Promise.make((resolve, _reject) => {
            let _ = setTimeout(() => resolve(), 100)
          })
        }
      }
    }
  | None => ()
  }
}

type enrichedLink = {
  hotspot: hotspot,
  hotspotIndex: int,
  targetIndex: int,
  isVisited: bool,
  isReturn: bool,
  isBridge: bool,
}

let findBestNextLink = (
  currentScene: scene,
  state: state,
  explicitVisitedOpt: option<array<int>>,
) => {
  let visited = switch explicitVisitedOpt {
  | Some(v) => v
  | None => simStore.contents.visitedScenes
  }

  let hotspots = currentScene.hotspots
  if Array.length(hotspots) == 0 {
    None
  } else {
    let allLinks =
      hotspots
      ->Belt.Array.mapWithIndex((i, hotspot) => {
        let targetIdx = Belt.Array.getIndexBy(state.scenes, s => s.name == hotspot.target)
        switch targetIdx {
        | Some(idx) =>
          switch Belt.Array.get(state.scenes, idx) {
          | Some(targetScene) =>
            let isVisited = Js.Array.includes(idx, visited)
            let isReturn = switch hotspot.isReturnLink {
            | Some(b) => b
            | None => false
            }
            let isBridge = targetScene.isAutoForward

            Some({
              hotspot,
              hotspotIndex: i,
              targetIndex: idx,
              isVisited,
              isReturn,
              isBridge,
            })
          | None => None
          }
        | None => None
        }
      })
      ->Belt.Array.keepMap(x => x)

    let p1 = Js.Array.find(l => !l.isVisited && !l.isReturn && !l.isBridge, allLinks)
    switch p1 {
    | Some(l) => Some(l)
    | None =>
      let p2 = Js.Array.find(l => !l.isVisited && !l.isReturn && l.isBridge, allLinks)
      switch p2 {
      | Some(l) => Some(l)
      | None =>
        let p3 = Js.Array.find(l => !l.isVisited && l.isReturn && !l.isBridge, allLinks)
        switch p3 {
        | Some(l) => Some(l)
        | None =>
          let p4 = Js.Array.find(l => !l.isVisited && l.isReturn && l.isBridge, allLinks)
          switch p4 {
          | Some(l) => Some(l)
          | None =>
            let p5 = Js.Array.find(l => !l.isReturn, allLinks)
            switch p5 {
            | Some(l) => Some(l)
            | None => Js.Array.find(l => l.isReturn, allLinks)
            }
          }
        }
      }
    }
  }
}

let advanceToNextScene = () => {
  if simStore.contents.isAutoPilot {
    let state = GlobalStateBridge.getState()
    let currentSceneOpt = Belt.Array.get(state.scenes, state.activeIndex)

    switch currentSceneOpt {
    | Some(currentScene) =>
      let nextLinkFound = findBestNextLink(currentScene, state, None)

      switch nextLinkFound {
      | Some(link) =>
        let nextLink = ref(link)

        // SKIP AUTO-FORWARD LOGIC
        if simStore.contents.skipAutoForwardGlobal {
          let chainCounter = ref(0)
          let originalHotspotIndex = nextLink.contents.hotspotIndex
          let originalHotspot = nextLink.contents.hotspot
          let loop = ref(true)

          while loop.contents && chainCounter.contents < 10 {
            switch Belt.Array.get(state.scenes, nextLink.contents.targetIndex) {
            | Some(targetScene) =>
              let isAuto = targetScene.isAutoForward
              if !isAuto {
                loop := false
              } else {
                if !Js.Array.includes(nextLink.contents.targetIndex, simStore.contents.visitedScenes) {
                  dispatch(AddVisitedScene(nextLink.contents.targetIndex))
                }

                switch findBestNextLink(targetScene, state, None) {
                | Some(jumpLink) =>
                  nextLink := {
                      ...jumpLink,
                      hotspotIndex: originalHotspotIndex,
                      hotspot: originalHotspot,
                    }
                  chainCounter := chainCounter.contents + 1
                | None => loop := false
                }
              }
            | None => loop := false
            }
          }
        }

        let hotspot = nextLink.contents.hotspot
        let targetIndex = nextLink.contents.targetIndex
        let hotspotIndex = nextLink.contents.hotspotIndex

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

        let (tYaw, tPitch, tHfov) = if nextLink.contents.isReturn {
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
                let _ = await waitForViewerScene(sceneIndex)
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

// --- TEASER PATH GENERATION ---

// Note: transitionState and arrivalView use mutable fields for animation performance
// This is acceptable as it's scoped to animation frames and not app state
type arrivalView = {
  mutable yaw: float,
  mutable pitch: float,
}

type transitionTarget = {
  yaw: float,
  pitch: float,
  targetName: string,
  startYaw: float,
  startPitch: float,
  waypoints: array<viewFrame>,
}

type pathStep = {
  idx: int,
  mutable transitionTarget: option<transitionTarget>,
  mutable arrivalView: arrivalView,
}

let getSimulationPath = (skipAutoForward: bool) => {
  let state = GlobalStateBridge.getState()
  if Array.length(state.scenes) == 0 {
    []
  } else {
    let path = []
    let localVisited = [0]
    let currentIdx = ref(0)
    let loopCount = ref(0)
    let maxSteps = 50

    // Initial setup
    let currentPathObj = {
      idx: 0,
      transitionTarget: None,
      arrivalView: {yaw: 0.0, pitch: 0.0},
    }

    switch Belt.Array.get(state.scenes, 0) {
    | Some(firstScene) =>
      if Array.length(firstScene.hotspots) > 0 {
        switch Belt.Array.get(firstScene.hotspots, 0) {
        | Some(startHotspot) =>
          switch startHotspot.viewFrame {
          | Some(vf) =>
            currentPathObj.arrivalView.yaw = vf.yaw
            currentPathObj.arrivalView.pitch = vf.pitch
          | None => ()
          }
        | None => ()
        }
      }
    | None => ()
    }

    let _ = Js.Array.push(currentPathObj, path)
    let activePathObj = ref(currentPathObj)

    let visitedStateSet = [] // strings "idx->target"
    let pathSet = [] // strings "idx->target"

    let loop = ref(true)

    while loop.contents {
      if loopCount.contents >= maxSteps {
        Logger.warn(~module_="Simulation", ~message="MAX_STEPS_REACHED", ~data=Some({"maxSteps": maxSteps}), ())
        loop := false
      } else {
        switch Belt.Array.get(state.scenes, currentIdx.contents) {
        | Some(currentScene) =>
          // Find next link
          let nextLinkOpt = ref(findBestNextLink(currentScene, state, Some(localVisited)))

          // Skip Auto Forward Logic
          if skipAutoForward {
            switch nextLinkOpt.contents {
            | Some(link) =>
              let chainCounter = ref(0)
              let tempLink = ref(link)
              let skipLoop = ref(true)

              while skipLoop.contents && chainCounter.contents < 10 {
                switch Belt.Array.get(state.scenes, tempLink.contents.targetIndex) {
                | Some(targetScene) =>
                  let isAuto = targetScene.isAutoForward
                  if !isAuto {
                    skipLoop := false
                  } else {
                    if !Js.Array.includes(tempLink.contents.targetIndex, localVisited) {
                      let _ = Js.Array.push(tempLink.contents.targetIndex, localVisited)
                    }

                    let jumpLinkOpt = findBestNextLink(targetScene, state, Some(localVisited))
                    switch jumpLinkOpt {
                    | Some(jl) =>
                      tempLink := jl
                      chainCounter := chainCounter.contents + 1
                    | None => skipLoop := false
                    }
                  }
                | None => skipLoop := false
                }
              }

              nextLinkOpt :=
                Some({
                  hotspot: link.hotspot, // Use STARTING link for transition visuals
                  hotspotIndex: link.hotspotIndex,
                  targetIndex: tempLink.contents.targetIndex, // Use FINAL target
                  isVisited: tempLink.contents.isVisited,
                  isReturn: tempLink.contents.isReturn,
                  isBridge: tempLink.contents.isBridge,
                })

            | None => ()
            }
          }

          switch nextLinkOpt.contents {
          | None => loop := false
          | Some(link) =>
            let hotspot = link.hotspot
            let targetIdx = link.targetIndex

            let stateKey =
              Belt.Int.toString(currentIdx.contents) ++ "->" ++ Belt.Int.toString(targetIdx)
            if Js.Array.includes(stateKey, visitedStateSet) {
              Logger.warn(
                ~module_="Simulation", 
                ~message="INFINITE_LOOP_DETECTED", 
                ~data=Some({
                    "stateKey": stateKey, 
                    "visitedScenes": visitedStateSet
                }), 
                ()
              )
              loop := false
            } else {
              let _ = Js.Array.push(stateKey, visitedStateSet)
              let _ = Js.Array.push(stateKey, pathSet)

              // 1. Update current path obj (activePathObj)
              let transYaw = switch hotspot.viewFrame {
              | Some(vf) => vf.yaw
              | None => hotspot.yaw
              }
              let transPitch = switch hotspot.viewFrame {
              | Some(vf) => vf.pitch
              | None => hotspot.pitch
              }

              let waypoints = switch hotspot.waypoints {
              | Some(w) => w
              | None => []
              }

              activePathObj.contents.transitionTarget = Some({
                yaw: transYaw,
                pitch: transPitch,
                targetName: hotspot.target,
                startYaw: switch hotspot.startYaw {
                | Some(y) => y
                | None => 0.0
                },
                startPitch: switch hotspot.startPitch {
                | Some(p) => p
                | None => 0.0
                },
                waypoints,
              })

              // 2. Prepare next
              let arrivalYaw = ref(0.0)
              let arrivalPitch = ref(0.0)

              // Logic for arrival
              if link.isReturn {
                switch hotspot.returnViewFrame {
                | Some(vf) =>
                  arrivalYaw := vf.yaw
                  arrivalPitch := vf.pitch
                | _ => () // Keep 0
                }
              } else {
                switch hotspot.viewFrame {
                | Some(vf) =>
                  arrivalYaw := vf.yaw
                  arrivalPitch := vf.pitch
                | None =>
                  switch hotspot.targetYaw {
                  | Some(y) =>
                    arrivalYaw := y
                    arrivalPitch :=
                      switch hotspot.targetPitch {
                      | Some(p) => p
                      | None => 0.0
                      }
                  | None => ()
                  }
                }
              }

              let nextPathObj = {
                idx: targetIdx,
                transitionTarget: None,
                arrivalView: {yaw: arrivalYaw.contents, pitch: arrivalPitch.contents},
              }

              let _ = Js.Array.push(nextPathObj, path)
              activePathObj := nextPathObj

              let _ = Js.Array.push(targetIdx, localVisited)
              currentIdx := targetIdx
              loopCount := loopCount.contents + 1

              if targetIdx == 0 && Array.length(localVisited) > 2 {
                loop := false
              }
            }
          }
        | None => loop := false
        }
      }
    }

    // Telemetry
    // Telemetry
    Logger.debug(
      ~module_="Simulation",
      ~message="PATH_COMPUTED",
      ~data=Some({
        "steps": Array.length(path),
        "visited": Array.length(localVisited),
      }),
      (),
    )

    path
  }
}
