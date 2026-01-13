/* src/systems/SimulationSystem.res */

open ReBindings
open LegacyStore

// --- STATE ---
type simulationState = {
  mutable isAutoPilot: bool,
  mutable visitedScenes: array<int>,
  mutable stoppingOnArrival: bool,
  mutable skipAutoForwardGlobal: bool,
  mutable lastAdvanceTime: float,
  mutable pendingAdvanceId: option<int>,
  mutable autoPilotJourneyId: int,
}

let simState = {
  isAutoPilot: false,
  visitedScenes: [],
  stoppingOnArrival: false,
  skipAutoForwardGlobal: false,
  lastAdvanceTime: 0.0,
  pendingAdvanceId: None,
  autoPilotJourneyId: 0,
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

let notify = Notification.notify

let isAutoPilotActive = () => simState.isAutoPilot
ignore((Obj.magic(window))["isAutoPilotActive"] = isAutoPilotActive)

let stopAutoPilotLogic = (returnToStart) => {
    if simState.isAutoPilot {
        Debug.info("Simulation", "Auto-pilot stopping", ~data=Some({"returnToStart": returnToStart}), ())
        
        switch simState.pendingAdvanceId {
        | Some(id) => clearTimeout(id)
        | None => ()
        }
        simState.pendingAdvanceId = None
        
        simState.autoPilotJourneyId = simState.autoPilotJourneyId + 1
        simState.isAutoPilot = false
        simState.visitedScenes = []
        simState.stoppingOnArrival = false
        simState.skipAutoForwardGlobal = false
        
        Navigation.setSimulationMode(false)
        Navigation.clearSimulationUI()
        Navigation.resetAutoForwardChain()
        
        // Remove class from body
        ignore((Obj.magic(document))["body"]["classList"]["remove"]("auto-pilot-active"))
        
         // Reset toggle button appearance
        let simToggle = (Obj.magic(document))["getElementById"]("v-scene-sim-toggle")
        if (Obj.magic(simToggle) != Nullable.null) {
            ignore(simToggle["innerHTML"] = "<span class='material-icons' style='font-size: 22px; color: white;'>play_arrow</span>")
            ignore(simToggle["style"]["removeProperty"]("background-color"))
            ignore(simToggle["style"]["setProperty"]("background-color", "#10b981", "important"))
            ignore(simToggle["title"] = "Start Auto-Pilot Simulation")
        }

        // Return to start scene if requested
        if returnToStart && Array.length(LegacyStore.store.state.scenes) > 0 {
             LegacyStore.setActiveScene(
                ~index=0, 
                ~startYaw=0.0, 
                ~startPitch=0.0, 
                ~transition=Nullable.make({
                    type_: Nullable.make("auto-pilot-end"),
                    targetHotspotIndex: -1,
                    fromSceneName: Nullable.null
                })
             )
        }
        
        notify("Simulation stopped", "info")
    }
}

let stopAutoPilot = (returnToStart) => stopAutoPilotLogic(returnToStart)

let completeAutoPilot = () => {
    Debug.info("Simulation", "Auto-pilot journey complete", ~data=Some({"scenesVisited": Array.length(simState.visitedScenes)}), ())
    notify("Simulation complete! Visited " ++ Belt.Int.toString(Array.length(simState.visitedScenes)) ++ " scenes.", "success")
    
    let _ = setTimeout(() => {
        stopAutoPilot(true)
    }, 800)
}

let waitForViewerScene = async (sceneIndex) => {
    let state = LegacyStore.store.state
    switch Belt.Array.get(state.scenes, sceneIndex) {
    | Some(expectedScene) => 
        let timeout = 8000.0
        let start = Date.now()
        let loop = ref(true)
        
        while loop.contents {
            if !simState.isAutoPilot {
                loop := false 
            } else if (Date.now() -. start > timeout) {
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
                             let _ = setTimeout(() => resolve(. ()), 100)
                         })
                     }
                 | None => 
                     let _ = await Promise.make((resolve, _reject) => {
                         let _ = setTimeout(() => resolve(. ()), 100)
                     })
                 }
            }
        }
    | None => ()
    }
}

type enrichedLink = {
    hotspot: LegacyStore.hotspot,
    hotspotIndex: int,
    targetIndex: int,
    isVisited: bool,
    isReturn: bool,
    isBridge: bool
}

let findBestNextLink = (currentScene: LegacyStore.scene, state: LegacyStore.state, explicitVisitedOpt: option<array<int>>) => {
    let visited = switch explicitVisitedOpt {
    | Some(v) => v
    | None => simState.visitedScenes
    }
    
    let hotspots = currentScene.hotspots
    if Array.length(hotspots) == 0 {
        None
    } else {
        let allLinks = hotspots
            -> Belt.Array.mapWithIndex((i, hotspot) => {
                 let targetIdx = Belt.Array.getIndexBy(state.scenes, s => s.name == hotspot.target)
                 switch targetIdx {
                 | Some(idx) =>
                     switch Belt.Array.get(state.scenes, idx) {
                     | Some(targetScene) =>
                         let isVisited = Js.Array.includes(idx, visited)
                         let isReturn = switch Nullable.toOption(hotspot.isReturnLink) { | Some(b) => b | None => false }
                         let isBridge = switch Nullable.toOption(targetScene.isAutoForward) { | Some(b) => b | None => false }
                         
                         Some({
                             hotspot: hotspot,
                             hotspotIndex: i,
                             targetIndex: idx,
                             isVisited: isVisited,
                             isReturn: isReturn,
                             isBridge: isBridge
                         })
                     | None => None
                     }
                 | None => None
                 }
            })
            -> Belt.Array.keepMap(x => x)
        
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
    if simState.isAutoPilot {
        let state = LegacyStore.store.state
        let currentSceneOpt = Belt.Array.get(state.scenes, state.activeIndex)
        
        switch currentSceneOpt {
        | Some(currentScene) =>
            let nextLinkFound = findBestNextLink(currentScene, state, None)
            
            switch nextLinkFound {
            | Some(link) =>
                let nextLink = ref(link)
                
                // SKIP AUTO-FORWARD LOGIC
                if simState.skipAutoForwardGlobal {
                    let chainCounter = ref(0)
                    let originalHotspotIndex = nextLink.contents.hotspotIndex
                    let originalHotspot = nextLink.contents.hotspot
                    let loop = ref(true)
                    
                    while loop.contents && chainCounter.contents < 10 {
                        switch Belt.Array.get(state.scenes, nextLink.contents.targetIndex) {
                        | Some(targetScene) =>
                            let isAuto = switch Nullable.toOption(targetScene.isAutoForward) { | Some(b) => b | None => false }
                            if !isAuto { loop := false }
                            else {
                                if !Js.Array.includes(nextLink.contents.targetIndex, simState.visitedScenes) {
                                    let _ = Js.Array.push(nextLink.contents.targetIndex, simState.visitedScenes)
                                }
                                
                                switch findBestNextLink(targetScene, state, None) {
                                | Some(jumpLink) =>
                                    nextLink := {
                                        ...jumpLink,
                                        hotspotIndex: originalHotspotIndex,
                                        hotspot: originalHotspot
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
                let timelineItem = Js.Array.find(item => 
                    item.sceneId == currentScene.id && item.linkId == hotspot.linkId,
                    state.timeline
                )
                switch timelineItem {
                | Some(item) => LegacyStore.setActiveTimelineStep(Nullable.make(item.id))
                | None => LegacyStore.setActiveTimelineStep(Nullable.null)
                }

                if targetIndex == 0 {
                    switch Belt.Array.get(state.scenes, 0) {
                    | Some(startScene) =>
                        let hasNewPaths = Belt.Array.some(startScene.hotspots, h => {
                            let tIdx = Belt.Array.getIndexBy(state.scenes, s => s.name == h.target)
                            switch tIdx {
                            | Some(i) => !Js.Array.includes(i, simState.visitedScenes)
                            | None => false
                            }
                        })
                        
                        if !hasNewPaths {
                            Debug.info("Simulation", "Stopping on arrival at start scene", ())
                            simState.stoppingOnArrival = true
                        }
                    | None => ()
                    }
                }
                
                Debug.info("Simulation", "Advancing to " ++ hotspot.target, ())
                
                let (tYaw, tPitch, tHfov) = if nextLink.contents.isReturn {
                    switch Nullable.toOption(hotspot.returnViewFrame) {
                    | Some(vf) => (vf.yaw, vf.pitch, vf.hfov)
                    | None => (0.0, 0.0, 90.0)
                    }
                } else {
                    switch Nullable.toOption(hotspot.viewFrame) {
                    | Some(vf) => (vf.yaw, vf.pitch, vf.hfov)
                    | None => 
                        switch Nullable.toOption(hotspot.targetYaw) {
                        | Some(y) => (y, 
                                      Nullable.getOr(hotspot.targetPitch, 0.0), 
                                      Nullable.getOr(hotspot.targetHfov, 90.0))
                        | None => (0.0, 0.0, 90.0)
                        }
                    }
                }
                
                Navigation.navigateToScene(
                    targetIndex,
                    state.activeIndex,
                    hotspotIndex,
                    ~targetYaw=tYaw,
                    ~targetPitch=tPitch,
                    ~targetHfov=tHfov,
                    ()
                )
                
            | None =>
                Debug.info("Simulation", "Auto-pilot complete: No reachable scenes", ())
                completeAutoPilot()
            }
            
        | None => 
            completeAutoPilot()
        }
    }
}

let onSceneArrival = (sceneIndex, _isChainEnd) => {
    if simState.isAutoPilot {
        Debug.debug("Simulation", "Arrived at scene " ++ Belt.Int.toString(sceneIndex), ())
        
        if simState.stoppingOnArrival {
            simState.stoppingOnArrival = false
            completeAutoPilot()
        } else {
            switch simState.pendingAdvanceId {
            | Some(id) => clearTimeout(id)
            | None => ()
            }
            simState.pendingAdvanceId = None
            
            let now = Date.now()
            if (now -. simState.lastAdvanceTime < 300.0) {
                 Debug.warn("Simulation", "onSceneArrival called too quickly, debouncing", ())
            } else {
                simState.lastAdvanceTime = now
                
                if !Js.Array.includes(sceneIndex, simState.visitedScenes) {
                    let _ = Js.Array.push(sceneIndex, simState.visitedScenes)
                }
                
                let state = LegacyStore.store.state
                switch Belt.Array.get(state.scenes, sceneIndex) {
                | Some(currentScene) =>
                    let isBridge = switch Nullable.toOption(currentScene.isAutoForward) {
                    | Some(b) => b
                    | None => false
                    }
                    
                    let delay = if simState.skipAutoForwardGlobal && isBridge { 0 } else { 500 }
                    
                    simState.pendingAdvanceId = Some(setTimeout(async () => {
                        try {
                            let _ = await waitForViewerScene(sceneIndex)
                            if simState.isAutoPilot && !simState.stoppingOnArrival {
                                advanceToNextScene()
                            }
                        } catch {
                        | e => 
                            if simState.isAutoPilot {
                                Debug.error("Simulation", "Failed to arrive at scene properly, stopping", ~data=e, ())
                                completeAutoPilot()
                            }
                        }
                    }, delay))
                | None => ()
                }
            }
        }
    }
}

let startAutoPilot = (skipAutoForward) => {
    let state = LegacyStore.store.state
    if Array.length(state.scenes) == 0 {
        notify("No scenes to simulate", "warning")
    } else {
        Debug.info("Simulation", "Auto-pilot starting", ())
        
        simState.isAutoPilot = true
        simState.visitedScenes = []
        simState.stoppingOnArrival = false
        simState.skipAutoForwardGlobal = switch skipAutoForward { | Some(b) => b | None => false }
        simState.autoPilotJourneyId = simState.autoPilotJourneyId + 1
        
        Navigation.setSimulationMode(true)
        
        ignore((Obj.magic(document))["body"]["classList"]["add"]("auto-pilot-active"))
        
         // Update toggle button appearance
        let simToggle = (Obj.magic(document))["getElementById"]("v-scene-sim-toggle")
        if (Obj.magic(simToggle) != Nullable.null) {
            ignore(simToggle["innerHTML"] = "<span class='material-icons' style='font-size: 22px; color: white;'>stop</span>")
            ignore(simToggle["style"]["removeProperty"]("background-color"))
            ignore(simToggle["style"]["setProperty"]("background-color", "#dc3545", "important"))
            ignore(simToggle["title"] = "Click to Stop Simulation")
            ignore(simToggle["offsetHeight"])
        }

        if state.activeIndex != 0 {
             LegacyStore.setActiveScene(
                ~index=0, 
                ~startYaw=0.0, 
                ~startPitch=0.0, 
                ~transition=Nullable.make({
                    type_: Nullable.make("auto-pilot-start"),
                    targetHotspotIndex: -1,
                    fromSceneName: Nullable.null
                })
             )
        }
        
        let _ = Js.Array.push(0, simState.visitedScenes)
        
        switch simState.pendingAdvanceId {
        | Some(id) => clearTimeout(id)
        | None => ()
        }
        
        simState.pendingAdvanceId = Some(setTimeout(() => {
            advanceToNextScene()
        }, 800))
        
        notify("Auto-pilot started", "success")
    }
}

let initSimulationKeyHandler = () => {
    Navigation.registerOnSceneArrival(onSceneArrival)
    Debug.info("Simulation", "Simulation initialized", ())
}

// --- TEASER PATH GENERATION ---

type arrivalView = {
  mutable yaw: float,
  mutable pitch: float
}

type transitionTarget = {
  yaw: float,
  pitch: float,
  targetName: string,
  startYaw: float,
  startPitch: float,
  waypoints: array<LegacyStore.viewFrame>
}

type pathStep = {
  idx: int,
  mutable transitionTarget: option<transitionTarget>,
  mutable arrivalView: arrivalView
}

let getSimulationPath = (skipAutoForward: bool) => {
    let state = LegacyStore.store.state
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
            arrivalView: { yaw: 0.0, pitch: 0.0 }
        }
        
        switch Belt.Array.get(state.scenes, 0) {
        | Some(firstScene) =>
            if Array.length(firstScene.hotspots) > 0 {
                 switch Belt.Array.get(firstScene.hotspots, 0) {
                 | Some(startHotspot) =>
                     switch Nullable.toOption(startHotspot.viewFrame) {
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
                Debug.warn("Simulation", "Path generation max steps reached", ())
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
                                     let isAuto = switch Nullable.toOption(targetScene.isAutoForward) { | Some(b) => b | None => false }
                                     if !isAuto { skipLoop := false } 
                                     else {
                                         if !Js.Array.includes(tempLink.contents.targetIndex, localVisited) {
                                             let _ = Js.Array.push(tempLink.contents.targetIndex, localVisited)
                                         }
                                         
                                         let jumpLinkOpt = findBestNextLink(targetScene, state, Some(localVisited))
                                         switch jumpLinkOpt {
                                         | Some(jl) => 
                                             tempLink := jl
                                             chainCounter := chainCounter.contents + 1
                                         | None => 
                                             skipLoop := false 
                                         }
                                     }
                                 | None => skipLoop := false
                                 }
                             }
                             
                             nextLinkOpt := Some({
                                 hotspot: link.hotspot, // Use STARTING link for transition visuals
                                 hotspotIndex: link.hotspotIndex,
                                 targetIndex: tempLink.contents.targetIndex, // Use FINAL target
                                 isVisited: tempLink.contents.isVisited,
                                 isReturn: tempLink.contents.isReturn, 
                                 isBridge: tempLink.contents.isBridge
                             })
                             
                         | None => ()
                         }
                    }
                    
                    switch nextLinkOpt.contents {
                    | None => loop := false
                    | Some(link) =>
                        let hotspot = link.hotspot
                        let targetIdx = link.targetIndex
                        
                        let stateKey = Belt.Int.toString(currentIdx.contents) ++ "->" ++ Belt.Int.toString(targetIdx)
                        if Js.Array.includes(stateKey, visitedStateSet) {
                             Debug.warn("Simulation", "Infinite loop detected: " ++ stateKey, ())
                             loop := false
                        } else {
                             let _ = Js.Array.push(stateKey, visitedStateSet)
                             let _ = Js.Array.push(stateKey, pathSet)
                             
                             // 1. Update current path obj (activePathObj)
                             let transYaw = switch Nullable.toOption(hotspot.viewFrame) {
                             | Some(vf) => vf.yaw
                             | None => hotspot.yaw
                             }
                             let transPitch = switch Nullable.toOption(hotspot.viewFrame) {
                             | Some(vf) => vf.pitch
                             | None => hotspot.pitch
                             }
                             
                             let waypoints = switch Nullable.toOption(hotspot.waypoints) { | Some(w) => w | None => [] }
                             
                             activePathObj.contents.transitionTarget = Some({
                                 yaw: transYaw,
                                 pitch: transPitch,
                                 targetName: hotspot.target, 
                                 startYaw: Nullable.getOr(hotspot.startYaw, 0.0),
                                 startPitch: Nullable.getOr(hotspot.startPitch, 0.0),
                                 waypoints: waypoints
                             })
                             
                             // 2. Prepare next
                             let arrivalYaw = ref(0.0)
                             let arrivalPitch = ref(0.0)
                             
                             // Logic for arrival
                             if link.isReturn {
                                 switch Nullable.toOption(hotspot.returnViewFrame) {
                                 | Some(vf) => 
                                     arrivalYaw := vf.yaw
                                     arrivalPitch := vf.pitch
                                 | _ => () // Keep 0
                                 }
                             } else {
                                  switch Nullable.toOption(hotspot.viewFrame) {
                                  | Some(vf) =>
                                     arrivalYaw := vf.yaw
                                     arrivalPitch := vf.pitch
                                  | None =>
                                     switch Nullable.toOption(hotspot.targetYaw) {
                                     | Some(y) =>
                                         arrivalYaw := y
                                         arrivalPitch := Nullable.getOr(hotspot.targetPitch, 0.0)
                                     | None => ()
                                     }
                                  }
                             }
                             
                             let nextPathObj = {
                                 idx: targetIdx,
                                 transitionTarget: None,
                                 arrivalView: { yaw: arrivalYaw.contents, pitch: arrivalPitch.contents }
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
        Debug.info("Simulation", "PATH_GENERATED", ~data=Some({
            "steps": Array.length(path),
            "visited": Array.length(localVisited)
        }), ())
        
        path
    }
}
