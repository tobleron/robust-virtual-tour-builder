/* src/systems/Navigation.res */

open ReBindings
open LegacyStore

/* --- MODULE STATE --- */
type linkInfo = {
  sceneIndex: int,
  hotspotIndex: int,
}

let onSceneArrivalCallback: ref<option<(int, bool) => unit>> = ref(None)
let incomingLink: ref<option<linkInfo>> = ref(None)
let isSimulationMode = ref(false)
let autoForwardChain: ref<array<int>> = ref([])
let pendingReturnSceneName: ref<option<string>> = ref(None)
let currentJourneyId = ref(0)
let isNavigating = ref(false)
let previewingLink: ref<option<linkInfo>> = ref(None)

/* --- GETTERS / SETTERS --- */
let getIsSimulationMode = () => isSimulationMode.contents

let getIncomingLink = () => incomingLink.contents
let setIncomingLink = (val) => incomingLink := val

let getAutoForwardChain = () => autoForwardChain.contents
let resetAutoForwardChain = () => autoForwardChain := []

let getPendingReturnSceneName = () => pendingReturnSceneName.contents
let setPendingReturnSceneName = (val) => pendingReturnSceneName := val

let getPreviewingLink = () => previewingLink.contents

let registerOnSceneArrival = (cb) => {
  onSceneArrivalCallback := Some(cb)
}

let clearSimulationUI = () => {
    PubSub.publish(PubSub.clearSimUi, ())
}

/* --- LOGIC HELPERS --- */

/* Calculate the intended arrival orientation for a scene */
let calculateSmartArrivalTarget = (state: LegacyStore.state, targetIndex: int) => {
  let arrivalYaw = ref(0.0)
  let arrivalPitch = ref(0.0)
  let arrivalHfov = ref(90.0)
  
  if targetIndex >= 0 && targetIndex < Belt.Array.length(state.scenes) {
    let nextSceneOpt = Belt.Array.get(state.scenes, targetIndex)
    
    switch nextSceneOpt {
    | Some(nextScene) =>
        /* PRIORITY: Use creation sequence (Oldest first) logic from JS is:
           let nextHotspot = null
           if (!nextHotspot && nextScene.hotspots.length > 0) ...
           Use find explicitly. 
        */
        let nextHotspot = Js.Array.find(h => {
          /* !h.isReturnLink */
          switch h.isReturnLink {
          | Nullable.Value(true) => false
          | _ => true
          }
        }, nextScene.hotspots)
        
        let target = switch nextHotspot {
        | Some(h) => Some(h)
        | None => 
          if Belt.Array.length(nextScene.hotspots) > 0 {
            Belt.Array.get(nextScene.hotspots, 0)
          } else {
            None
          }
        }
        
        switch target {
        | Some(h) =>
          /* Check startYaw/Pitch definition */
          switch (h.startYaw, h.startPitch) {
          | (Nullable.Value(sy), Nullable.Value(sp)) =>
            arrivalYaw := sy
            arrivalPitch := sp
            switch h.startHfov {
            | Nullable.Value(sh) => arrivalHfov := sh
            | _ => ()
            }
          | _ =>
            arrivalYaw := h.yaw -. 35.0
            arrivalPitch := 0.0
          }
        | None => ()
        }
    | None => ()
    }
  }
  
  (arrivalYaw.contents, arrivalPitch.contents, arrivalHfov.contents)
}

/* Helper to get current view safely */
let getCurrentView = (overrideViewer) => {
  let vOpt = switch overrideViewer {
  | Some(v) => Some(v)
  | None => Nullable.toOption(Viewer.instance)
  }
  
  switch vOpt {
  | Some(v) =>
     /* Paranoid check: if somehow it's still null in JS land */
     if (Obj.magic(v) == Nullable.null) {
        (0.0, 0.0, 90.0)
     } else {
        (Viewer.getYaw(v), Viewer.getPitch(v), Viewer.getHfov(v))
     }
  | None => (0.0, 0.0, 90.0)
  }
}

/* --- NAVIGATION CORE --- */

/* We define a type for journey data to pass around */
type journeyData = {
  journeyId: int,
  targetIndex: int,
  sourceIndex: int,
  hotspotIndex: int,
  arrivalYaw: float,
  arrivalPitch: float, 
  arrivalHfov: float,
  previewOnly: bool,
}

let handleJourneyFinalize = (data: journeyData) => {
  if data.journeyId == currentJourneyId.contents {
    Debug.info("Navigation", "Journey finalized", ~data=Some(data), ())
    
    if data.previewOnly {
      Debug.info("Navigation", "Preview complete", ())
      isNavigating := false
      previewingLink := None
      Notification.notify("Preview complete", "success")
    } else {
      let _state = (store.state : LegacyStore.state)
      
      /* Set incoming link */
      incomingLink := Some({
        sceneIndex: data.sourceIndex,
        hotspotIndex: data.hotspotIndex
      })
      
      /* Sync Visual Pipeline (Timeline) */
      /* Logic omitted for brevity, strictly UI sync */
      
      isNavigating := false
      
      /* Set Active Scene */
      let transition = {
        type_: Nullable.make("link"),
        targetHotspotIndex: -1,
        fromSceneName: Nullable.null
      }
      
      LegacyStore.setActiveScene(
        ~index=data.targetIndex,
        ~startYaw=data.arrivalYaw,
        ~startPitch=data.arrivalPitch,
        ~transition=Nullable.make(transition)
      )
      
      clearSimulationUI()
      
      /* Notify SimulationSystem */
      if isSimulationMode.contents {
         switch onSceneArrivalCallback.contents {
         | Some(cb) => cb(data.targetIndex, false)
         | None => ()
         }
      }
    }
  }
}

/* Calculate path info and publish event */
let startNavigationAnimation = (
  journeyId: int, 
  targetIndex: int, 
  sourceSceneIndex: int, 
  sourceHotspotIndex: int,
  targetYaw: float,
  targetPitch: float,
  targetHfov: float,
  currentView: (float, float, float),
  previewOnly: bool
) => {
    let state = (store.state : LegacyStore.state)
    
    let sourceSceneOpt = Belt.Array.get(state.scenes, sourceSceneIndex)
    switch sourceSceneOpt {
    | Some(sourceScene) =>
        let hotspotOpt = Belt.Array.get(sourceScene.hotspots, sourceHotspotIndex)
        switch hotspotOpt {
        | Some(hotspot) =>
            let (curYaw, curPitch, curHfov) = currentView
            
            let (arrYaw, arrPitch, arrHfov) = if isSimulationMode.contents {
                calculateSmartArrivalTarget(state, targetIndex)
            } else {
                (targetYaw, targetPitch, targetHfov)
            }
            
            /* Path Calculation Logic */
            /* Determine start params */
            let startPitch = switch hotspot.startPitch { | Nullable.Value(p) => p | _ => curPitch }
            let startYaw = switch hotspot.startYaw { | Nullable.Value(y) => y | _ => curYaw }
            
            /* Determine target pan params */
            let (tYawPan, tPitchPan) = switch hotspot.viewFrame {
            | Nullable.Value(vf) => (vf.yaw, vf.pitch)
            | _ => (targetYaw, targetPitch)
            }
            
            /* Generate Control Points */
            let p0: PathInterpolation.point = {yaw: startYaw, pitch: startPitch}
            let pEnd: PathInterpolation.point = {yaw: tYawPan, pitch: tPitchPan}
            
            let waypointsRaw = switch Nullable.toOption(hotspot.waypoints) { | Some(w) => w | None => [] }
            let waypoints: array<PathInterpolation.point> = Belt.Array.map(waypointsRaw, w => ({PathInterpolation.yaw: w.yaw, pitch: w.pitch}))

            let controlPoints = if Array.length(waypoints) > 0 {
                Belt.Array.concat([p0], Belt.Array.concat(waypoints, [pEnd]))
            } else {
                [p0, pEnd]
            }

            /* Spline generation */
            let path = PathInterpolation.getCatmullRomSpline(controlPoints, 100)
            
            /* Calculate segments and total distance */
            let totalDistance = ref(0.0)
            let segments = []
            
            if Array.length(path) >= 2 {
                for i in 0 to Array.length(path) - 2 {
                    let p1 = Belt.Array.getExn(path, i)
                    let p2 = Belt.Array.getExn(path, i+1)
                    let yawDiff = ref(p2.yaw -. p1.yaw)
                    while yawDiff.contents > 180.0 { yawDiff := yawDiff.contents -. 360.0 }
                    while yawDiff.contents < -180.0 { yawDiff := yawDiff.contents +. 360.0 }
                    
                    let pitchDiff = p2.pitch -. p1.pitch
                    let dist = Math.sqrt(yawDiff.contents *. yawDiff.contents +. pitchDiff *. pitchDiff)
                    
                    let segment = {
                        "dist": dist,
                        "yawDiff": yawDiff.contents,
                        "pitchDiff": pitchDiff,
                        "p1": p1,
                        "p2": p2
                    }
                    let _ = Js.Array.push(segment, segments)
                    totalDistance := totalDistance.contents +. dist
                }
            }

            let panDuration = Math.min(
                Math.max(totalDistance.contents /. Constants.panningVelocity, Constants.panningMinDuration),
                Constants.panningMaxDuration
            )

            /* Publish Event */
            let payload = {
                "journeyId": journeyId,
                "sourceIndex": sourceSceneIndex,
                "targetIndex": targetIndex,
                "hotspotIndex": sourceHotspotIndex,
                "previewOnly": previewOnly,
                "pathData": {
                    "startPitch": startPitch,
                    "startYaw": startYaw,
                    "startHfov": curHfov,
                    "targetPitchForPan": tPitchPan,
                    "targetYawForPan": tYawPan,
                    "targetHfovForPan": arrHfov,
                    "totalPathDistance": totalDistance.contents,
                    "segments": segments, 
                    "waypoints": waypoints,
                    "panDuration": panDuration,
                    "arrivalYaw": arrYaw,
                    "arrivalPitch": arrPitch,
                    "arrivalHfov": arrHfov
                } 
            }
            
            PubSub.publish(PubSub.navStart, payload)
        | None => ()
        }
    | None => ()
    }
}

let navigateToScene = (
  targetIndex: int, 
  sourceSceneIndex: int, 
  sourceHotspotIndex: int,
  ~targetYaw: float=0.0, 
  ~targetPitch: float=0.0, 
  ~targetHfov: float=90.0,
  ~overrideViewer: option<Viewer.t>=?, 
  ~previewOnly: bool=false,
  ()
) => {
  if isNavigating.contents {
    Debug.warn("Navigation", "BLOCKED: Navigation already in progress", ())
  } else {
    currentJourneyId := currentJourneyId.contents + 1
    let jId = currentJourneyId.contents
    isNavigating := true
    
    let state = (store.state : LegacyStore.state)
    
    /* Just use unsafe access here or check, strict Belt.Array.get is better */
    /* If sourceScene is valid, proceed */
    
    let currentView = getCurrentView(overrideViewer)
    
    if previewOnly {
       previewingLink := Some({sceneIndex: sourceSceneIndex, hotspotIndex: sourceHotspotIndex})
    }
    
    let shouldAnimate = (isSimulationMode.contents || previewOnly) 
    
    if shouldAnimate {
       startNavigationAnimation(
         jId, targetIndex, sourceSceneIndex, sourceHotspotIndex,
         targetYaw, targetPitch, targetHfov, currentView, previewOnly
       )
    } else {
       /* Manual Jump */
       let (arrYaw, arrPitch, arrHfov) = calculateSmartArrivalTarget(state, targetIndex)
       
       let data: journeyData = {
           journeyId: jId,
           targetIndex: targetIndex,
           sourceIndex: sourceSceneIndex,
           hotspotIndex: sourceHotspotIndex,
           arrivalYaw: arrYaw,
           arrivalPitch: arrPitch,
           arrivalHfov: arrHfov,
           previewOnly: false
       }
       handleJourneyFinalize(data)
    }
  }
}

let cancelNavigation = () => {
  currentJourneyId := currentJourneyId.contents + 1
  isNavigating := false
  PubSub.publish(PubSub.navCancelled, ())
}

let handleAutoForward = (currentScene: LegacyStore.scene, state: LegacyStore.state, _viewer: option<Viewer.t>) => {
    /* Recursion / Logic port from JS */
    if isSimulationMode.contents {
        /* Skipped in Sim Mode */
        ()
    } else {
       switch currentScene.isAutoForward {
       | Nullable.Value(true) => 
         if !state.isLinking {
             Debug.info("Navigation", "AutoForward Processing: " ++ currentScene.name, ())
             
             /* Chain Logic */
             let chain = autoForwardChain.contents
             if Belt.Array.length(chain) == 0 {
                 switch incomingLink.contents {
                 | Some(l) => ignore(Js.Array.push(l.sceneIndex, chain))
                 | None => ()
                 }
             }
             
             if Js.Array.includes(state.activeIndex, chain) {
                 Debug.warn("Navigation", "Loop detected", ())
                 autoForwardChain := []
                 Notification.notify("Loop detected", "warning")
             } else {
                 ignore(Js.Array.push(state.activeIndex, chain))
                 /* Heuristic Logic skipped for V1 port */
             }
         }
       | _ => ()  
       }
    }
}

let setSimulationMode = (val) => {
    isSimulationMode := val
    Debug.info("Navigation", "Simulation mode: " ++ (if val {"ON"} else {"OFF"}), ())
    
    autoForwardChain := []
    incomingLink := None
    currentJourneyId := currentJourneyId.contents + 1
    clearSimulationUI()
    isNavigating := false
    
    if val {
        let state = (store.state : LegacyStore.state)
        if state.activeIndex >= 0 {
            /* Timeout 100ms logic */
            let _ = setTimeout(() => {
                switch Belt.Array.get(state.scenes, state.activeIndex) {
                | Some(scene) =>
                   handleAutoForward(scene, state, Nullable.toOption(Viewer.instance))
                | None => ()
                }
            }, 100)
        }
    }
}

/* Initialization */
let initNavigation = () => {
    isSimulationMode := false
    currentJourneyId := 0
    isNavigating := false
    incomingLink := None
    autoForwardChain := []
    
    /* Subscribe */
    let _ = PubSub.subscribe(PubSub.navCompleted, (data) => {
        handleJourneyFinalize(data)
    })
    
    let _ = PubSub.subscribe(PubSub.navCancelled, (_data) => {
        isNavigating := false
    })
    
    Debug.info("Navigation", "Navigation system initialized (ReScript)", ())
}
