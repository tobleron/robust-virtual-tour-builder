/* src/systems/SceneLoader.res - Consolidated Scene Loading System */
open Types
open Actions

/* --- Config --- */

let blankPanorama = "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw=="

let getHotspots = (scene: scene, ~state, ~dispatch) =>
  scene.hotspots->Belt.Array.mapWithIndex((idx, h) => {
    HotspotManager.createHotspotConfig(~hotspot=h, ~index=idx, ~state, ~scene, ~dispatch)
  })

let isMissingPanoramaFile = (f: Types.file) => {
  switch f {
  | Url(u) => u == ""
  | Blob(_) | File(_) => false
  }
}

let resolveScenePanoramaFile = (scene: scene): Types.file => {
  if !isMissingPanoramaFile(scene.file) {
    scene.file
  } else {
    switch scene.originalFile {
    | Some(f) if !isMissingPanoramaFile(f) => f
    | _ =>
      switch scene.tinyFile {
      | Some(f) if !isMissingPanoramaFile(f) => f
      | _ => scene.file
      }
    }
  }
}

let resolveArrivalView = (~state: state, ~scene: scene): option<viewFrame> => {
  switch state.navigationState.navigation {
  | Navigating(journey) =>
    let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
    switch Belt.Array.get(activeScenes, journey.targetIndex) {
    | Some(targetScene) if targetScene.id == scene.id =>
      Some({
        yaw: journey.arrivalYaw,
        pitch: journey.arrivalPitch,
        hfov: journey.arrivalHfov,
      })
    | _ => None
    }
  | _ => None
  }
}

let makeSceneConfig = (scene: scene, ~state, ~dispatch) => {
  let fileForLoad = resolveScenePanoramaFile(scene)
  let url = SceneCache.getSourceUrl(scene.id, fileForLoad)
  let arrivalView = resolveArrivalView(~state, ~scene)
  let initialYaw = arrivalView->Option.map(v => v.yaw)->Option.getOr(state.activeYaw)
  let initialPitch = arrivalView->Option.map(v => v.pitch)->Option.getOr(state.activePitch)
  let initialHfov =
    arrivalView->Option.map(v => v.hfov)->Option.getOr(ViewerSystem.getCorrectHfov())
  let panorama = if url == "" {
    Logger.error(
      ~module_="SceneLoader",
      ~message="MISSING_PANORAMA_SOURCE_FALLBACK_BLANK",
      ~data=Some({"id": scene.id}),
      (),
    )
    blankPanorama
  } else {
    url
  }
  Logger.debug(
    ~module_="SceneLoader",
    ~message="PREPARING_SCENE_INNER",
    ~data={"id": scene.id, "url": url},
    (),
  )
  {
    "panorama": panorama,
    "hotSpots": getHotspots(scene, ~state, ~dispatch),
    "yaw": initialYaw,
    "pitch": initialPitch,
    "hfov": initialHfov,
  }
}

let makeInitialConfig = (scene: scene, ~state, ~dispatch) => {
  let inner = makeSceneConfig(scene, ~state, ~dispatch)
  {
    "default": {"firstScene": scene.id},
    "scenes": Dict.fromArray([(scene.id, inner)]),
    "autoLoad": true,
    "hfov": Constants.globalMaxHfov,
    "minHfov": Constants.globalMinHfov,
    "maxHfov": Constants.globalMaxHfov,
    "mouseZoom": false,
    "doubleClickZoom": false,
    "keyboardZoom": false,
    "showZoomCtrl": false,
  }
}

let backgroundViewerConfig = () => {
  {
    "panorama": blankPanorama,
    "hotSpots": [],
    "autoLoad": false,
    "hfov": Constants.globalMaxHfov,
    "minHfov": Constants.globalMinHfov,
    "maxHfov": Constants.globalMaxHfov,
    "mouseZoom": false,
    "doubleClickZoom": false,
    "keyboardZoom": false,
    "showZoomCtrl": false,
  }
}

/* --- Events --- */

let isStaleTask = (~taskId: option<string>=?, ~signal: option<BrowserBindings.AbortSignal.t>=?) => {
  let taskMismatch = switch taskId {
  | Some(tid) => !NavigationSupervisor.isCurrentTaskId(tid)
  | None => false
  }
  let signalAborted = switch signal {
  | Some(s) => BrowserBindings.AbortSignal.aborted(s)
  | None => false
  }
  taskMismatch || signalAborted
}

let castToDict: 'a => dict<string> = %raw("(x) => (typeof x === 'object' && x !== null) ? x : {}")
external boolToUnknown: bool => unknown = "%identity"
external idToUnknown: string => unknown = "%identity"

let onSceneLoad = (
  ~dispatch,
  v,
  loadedScene: scene,
  ~taskId: option<string>=?,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
) => {
  if isStaleTask(~taskId?, ~signal?) {
    Logger.debug(
      ~module_="SceneLoader",
      ~message="STALE_SCENE_LOAD_IGNORED",
      ~data=Some({"sceneId": loadedScene.id, "taskId": taskId->Option.getOr("none")}),
      (),
    )
    ()
  } else {
    let vId = castToDict(v)->Dict.get("container")->Option.getOr("")
    let entry = ViewerSystem.Pool.pool.contents->Belt.Array.getBy(e => e.containerId == vId)
    entry->Option.forEach(e => {
      e.instance->Option.forEach(inst => {
        ViewerSystem.Adapter.setMetaData(inst, "isLoaded", boolToUnknown(true))
        ViewerSystem.Adapter.setMetaData(inst, "sceneId", idToUnknown(loadedScene.id))
      })
    })
    ViewerSystem.Pool.setCleanupTimeout(vId, None)

    switch taskId {
    | Some(tid) => NavigationSupervisor.transitionTo(tid, Swapping(tid, loadedScene.id))
    | None => ()
    }

    dispatch(DispatchNavigationFsmEvent(TextureLoaded({targetSceneId: loadedScene.id})))
  }
}

let onSceneError = (
  ~dispatch,
  msg,
  targetSceneId,
  ~taskId: option<string>=?,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
) => {
  if isStaleTask(~taskId?, ~signal?) {
    Logger.debug(
      ~module_="SceneLoader",
      ~message="STALE_SCENE_ERROR_IGNORED",
      ~data=Some({"targetId": targetSceneId, "taskId": taskId->Option.getOr("none")}),
      (),
    )
    ()
  } else {
    Logger.error(
      ~module_="SceneLoader",
      ~message="LOAD_ERROR",
      ~data={"error": msg, "targetId": targetSceneId},
      (),
    )

    switch taskId {
    | Some(tid) => NavigationSupervisor.abort(tid)
    | None => ()
    }

    NotificationManager.dispatch({
      id: "",
      importance: Error,
      context: Operation("scene_loader"),
      message: msg,
      details: None,
      action: None,
      duration: NotificationTypes.defaultTimeoutMs(Error),
      dismissible: true,
      createdAt: Date.now(),
    })
    dispatch(DispatchNavigationFsmEvent(LoadTimeout))
  }
}

/* --- Reuse --- */

let findReusableInstance = (pathRequest: pathRequest, targetIdx: int): option<
  ViewerSystem.Adapter.t,
> => {
  let targetSceneId = pathRequest.scenes[targetIdx]->Option.map(s => s.id)
  ViewerSystem.Pool.pool.contents
  ->Belt.Array.getBy(v => {
    v.instance
    ->Option.map(inst => {
      let metaId = ViewerSystem.Adapter.getMetaData(inst, "sceneId")
      metaId == targetSceneId->Option.map(idToUnknown)
    })
    ->Option.getOr(false)
  })
  ->Option.flatMap(v => v.instance)
}
