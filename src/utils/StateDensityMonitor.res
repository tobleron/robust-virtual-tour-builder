open Types

type densityLevel =
  | Healthy
  | Watch
  | High

type densitySnapshot = {
  sceneCount: int,
  hotspotCount: int,
  timelineCount: int,
  inventoryCount: int,
  deletedSceneCount: int,
  score: float,
  level: densityLevel,
}

let watchThreshold = 120.0
let highThreshold = 220.0

let classifyScore = (score: float): densityLevel => {
  if score >= highThreshold {
    High
  } else if score >= watchThreshold {
    Watch
  } else {
    Healthy
  }
}

let toSnapshot = (state: state): densitySnapshot => {
  let hotspotCount =
    state.scenes->Belt.Array.reduce(0, (acc, scene) => acc + Belt.Array.length(scene.hotspots))
  let inventoryCount = Belt.Map.String.size(state.inventory)
  let timelineCount = Belt.Array.length(state.timeline)
  let deletedSceneCount = Belt.Array.length(state.deletedSceneIds)
  let sceneCount = Belt.Array.length(state.scenes)
  let score =
    sceneCount->Int.toFloat +.
    hotspotCount->Int.toFloat *. 0.35 +.
    timelineCount->Int.toFloat *. 0.4 +.
    deletedSceneCount->Int.toFloat *. 0.15 +.
    inventoryCount->Int.toFloat *. 0.1

  {
    sceneCount,
    hotspotCount,
    timelineCount,
    inventoryCount,
    deletedSceneCount,
    score,
    level: classifyScore(score),
  }
}

let levelToString = (level: densityLevel): string =>
  switch level {
  | Healthy => "healthy"
  | Watch => "watch"
  | High => "high"
  }

let lastLevel = ref((None: option<densityLevel>))

let shouldRun = () => Constants.isDebugBuild() || Constants.enableStateInspector()

let observe = (state: state) => {
  if shouldRun() {
    let snapshot = toSnapshot(state)
    let levelChanged = switch lastLevel.contents {
    | Some(previous) => previous != snapshot.level
    | None => true
    }

    if levelChanged {
      let payload = {
        "level": levelToString(snapshot.level),
        "score": snapshot.score,
        "scenes": snapshot.sceneCount,
        "hotspots": snapshot.hotspotCount,
        "timelineSteps": snapshot.timelineCount,
        "inventoryEntries": snapshot.inventoryCount,
        "deletedScenes": snapshot.deletedSceneCount,
      }

      switch snapshot.level {
      | Healthy =>
        Logger.info(
          ~module_="StateDensityMonitor",
          ~message="STATE_DENSITY_HEALTHY",
          ~data=payload,
          (),
        )
      | Watch =>
        Logger.warn(
          ~module_="StateDensityMonitor",
          ~message="STATE_DENSITY_WATCH",
          ~data=payload,
          (),
        )
      | High =>
        Logger.warn(
          ~module_="StateDensityMonitor",
          ~message="STATE_DENSITY_HIGH",
          ~data=payload,
          (),
        )
      }
    }

    lastLevel := Some(snapshot.level)
  }
}
