/* src/systems/ViewerSystem.res - Consolidated Viewer System */

open ReBindings
open Types

// --- ADAPTER (from PannellumAdapter.res) ---

module Adapter = {
  type t = Viewer.t
  type customViewerProps
  external asCustom: Viewer.t => customViewerProps = "%identity"
  external identity: 'a => 'b = "%identity"
  external asAny: 'a => {..} = "%identity"

  @get @return(nullable) external getSceneId: customViewerProps => option<string> = "_sceneId"
  @set external setSceneId: (customViewerProps, string) => unit = "_sceneId"

  @get @return(nullable) external getIsLoaded: customViewerProps => option<bool> = "_isLoaded"
  @set external setIsLoaded: (customViewerProps, bool) => unit = "_isLoaded"

  let name = "Pannellum"

  let initialize = (id, config) => {
    ViewerAdapter.initialize(id, config)
  }
  let initializeViewer = initialize

  let destroy = v => {
    ViewerAdapter.destroy(v)
  }

  let getPitch = v => Viewer.getPitch(v)
  let getYaw = v => Viewer.getYaw(v)
  let getHfov = v => Viewer.getHfov(v)
  let setPitch = (v, p, a) => Viewer.setPitch(v, p, a)
  let setYaw = (v, y, a) => Viewer.setYaw(v, y, a)
  let setHfov = (v, h, a) => Viewer.setHfov(v, h, a)
  let setView = (v, ~pitch=?, ~yaw=?, ~hfov=?, ~animated=false, ()) => {
    ViewerAdapter.setView(v, ~pitch?, ~yaw?, ~hfov?, ~animated, ())
  }
  let addHotSpot = (v, config) => Viewer.addHotSpot(v, config)
  let removeHotSpot = (v, id) => Viewer.removeHotSpot(v, id)
  let getScene = v => Viewer.getScene(v)
  let loadScene = (v, sceneId, ~pitch=?, ~yaw=?, ~hfov=?, ()) => {
    ViewerAdapter.loadScene(v, sceneId, ~pitch?, ~yaw?, ~hfov?, ())
  }
  let addScene = (v, id, config) => Viewer.addScene(v, id, config)
  let on = (v, ev, cb) => Viewer.on(v, ev, cb)
  let isLoaded = v => Viewer.isLoaded(v)
  let setMetaData = (v, key, value) => {
    ViewerAdapter.setMetaData(v, key, value)
  }
  let getMetaData = (v, key) => {
    ViewerAdapter.getMetaData(v, key)
  }
}

// --- POOL (from ViewerPool.res) ---

module Pool = {
  type status = ViewerPool.status
  type viewport = ViewerPool.viewport

  let pool = ViewerPool.pool

  // Revert accessors to original logic, but using the aliased 'pool' ref
  let getViewport = id => pool.contents->Belt.Array.getBy(v => v.id == id)
  let getViewportByContainer = cId => pool.contents->Belt.Array.getBy(v => v.containerId == cId)
  let getActive = () => pool.contents->Belt.Array.getBy(v => v.status == #Active)
  let getActiveViewer = () => getActive()->Option.flatMap(v => v.instance)
  let getInactive = () => pool.contents->Belt.Array.getBy(v => v.status == #Background)
  let getInactiveViewer = () => getInactive()->Option.flatMap(v => v.instance)

  let swapActive = () =>
    ViewerPool.swapActive()
  let registerInstance = (cId, inst) =>
    ViewerPool.registerInstance(cId, inst)
  let clearInstance = cId =>
    ViewerPool.clearInstance(cId)
  let setCleanupTimeout = (id, t) =>
    ViewerPool.setCleanupTimeout(id, t)
  let clearCleanupTimeout = id =>
    ViewerPool.clearCleanupTimeout(id)

  let reset = () => {
    ViewerPool.reset()
  }
}

// --- FOLLOW (from ViewerFollow.res) ---

module Follow = {
  let isInsideDeadZone = (startPt, lastMouse) => {
    ViewerFollow.isInsideDeadZone(startPt, lastMouse)
  }

  let updateFollowLoop = (~getState: unit => state) => {
    ViewerFollow.updateFollowLoop(~getState)
  }
}

// --- FACADE (Getters for circular dependency fix) ---

let getActiveViewer = () => Pool.getActiveViewer()->Nullable.fromOption
let getInactiveViewer = () => Pool.getInactiveViewer()->Nullable.fromOption
let getActiveContainerId = () =>
  switch Pool.getActive() {
  | Some(v) => v.containerId
  | None => "panorama-a"
  }
let getInactiveContainerId = () =>
  switch Pool.getInactive() {
  | Some(v) => v.containerId
  | None => "panorama-b"
  }

let resetState = () => {
  ViewerState.resetState()
  Pool.reset()
  Pool.pool.contents->Belt.Array.forEach(v => {
    Pool.clearCleanupTimeout(v.id)
  })
}

// --- STATUS ---

let isViewerValid = (viewer: Viewer.t): bool => {
  let loaded = Viewer.isLoaded(viewer)
  if !loaded {
    false
  } else {
    let hfov = Viewer.getHfov(viewer)
    let yaw = Viewer.getYaw(viewer)
    let pitch = Viewer.getPitch(viewer)
    hfov > 0.0 && Float.isFinite(hfov) && Float.isFinite(yaw) && Float.isFinite(pitch)
  }
}

let isActiveViewer = (viewer: Viewer.t): bool => {
  let activeViewer = getActiveViewer()
  switch Nullable.toOption(activeViewer) {
  | Some(active) => active === viewer
  | None => false
  }
}

let isViewerReady = (viewer: Viewer.t): bool => {
  if !isViewerValid(viewer) {
    false
  } else if !isActiveViewer(viewer) {
    false
  } else {
    Viewer.getHfov(viewer) > 1.0
  }
}

let destroyViewer = Adapter.destroy

// --- COMPATIBILITY ALIASES ---
module PannellumAdapter = Adapter
module PannellumLifecycle = Adapter
module ViewerPool = Pool
module ViewerFollow = Follow
module HotspotLineLogic = HotspotLine.Logic
