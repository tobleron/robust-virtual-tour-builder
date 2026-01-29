/* src/systems/ViewerSystem.res - Consolidated Viewer System */

open ReBindings

// --- ADAPTER (from PannellumAdapter.res) ---

module Adapter = {
  type t = Viewer.t
  type customViewerProps = {
    @as("_sceneId") mutable sceneId: string,
    @as("_isLoaded") mutable isLoaded: bool,
  }
  external asCustom: Viewer.t => customViewerProps = "%identity"
  let name = "Pannellum"
  let initialize = (id, config) => Pannellum.viewer(id, config)
  let initializeViewer = initialize
  let destroy = v => {
    try {Viewer.destroy(v)} catch {
    | _ => ()
    }
  }
  let getPitch = v => Viewer.getPitch(v)
  let getYaw = v => Viewer.getYaw(v)
  let getHfov = v => Viewer.getHfov(v)
  let setPitch = (v, p, a) => Viewer.setPitch(v, p, a)
  let setYaw = (v, y, a) => Viewer.setYaw(v, y, a)
  let setHfov = (v, h, a) => Viewer.setHfov(v, h, a)
  let setView = (v, ~pitch=?, ~yaw=?, ~hfov=?, ~animated=false, ()) => {
    pitch->Option.forEach(p => Viewer.setPitch(v, p, animated))
    yaw->Option.forEach(y => Viewer.setYaw(v, y, animated))
    hfov->Option.forEach(h => Viewer.setHfov(v, h, animated))
  }
  let addHotSpot = (v, config) => Viewer.addHotSpot(v, config)
  let removeHotSpot = (v, id) => Viewer.removeHotSpot(v, id)
  let getScene = v => Viewer.getScene(v)
  let loadScene = (v, sceneId, ~pitch=?, ~yaw=?, ~hfov=?, ()) => {
    let p = pitch->Option.getOr(Viewer.getPitch(v))
    let y = yaw->Option.getOr(Viewer.getYaw(v))
    let h = hfov->Option.getOr(Viewer.getHfov(v))
    Viewer.loadScene(v, sceneId, p, y, h)
  }
  let on = (v, ev, cb) => Viewer.on(v, ev, cb)
  let isLoaded = v => asCustom(v).isLoaded
  let setMetaData = (v, key, value) => {
    let c = asCustom(v)
    if key == "sceneId" {
      c.sceneId = Obj.magic(value)
    } else if key == "isLoaded" {
      c.isLoaded = Obj.magic(value)
    }
  }
  let getMetaData = (v, key) => {
    let c = asCustom(v)
    if key == "sceneId" {
      Some(Obj.magic(c.sceneId))
    } else if key == "isLoaded" {
      Some(Obj.magic(c.isLoaded))
    } else {
      None
    }
  }
}

// --- POOL (from ViewerPool.res) ---

module Pool = {
  type status = [#Free | #Active | #Background]
  type viewport = {
    id: string,
    containerId: string,
    mutable instance: option<Adapter.t>,
    mutable status: status,
    mutable cleanupTimeout: option<int>,
  }
  let pool = [
    {
      id: "primary-a",
      containerId: "panorama-a",
      instance: None,
      status: #Active,
      cleanupTimeout: None,
    },
    {
      id: "primary-b",
      containerId: "panorama-b",
      instance: None,
      status: #Background,
      cleanupTimeout: None,
    },
  ]
  let getViewport = id => pool->Belt.Array.getBy(v => v.id == id)
  let getViewportByContainer = cId => pool->Belt.Array.getBy(v => v.containerId == cId)
  let getActive = () => pool->Belt.Array.getBy(v => v.status == #Active)
  let getActiveViewer = () => getActive()->Option.flatMap(v => v.instance)
  let getInactive = () => pool->Belt.Array.getBy(v => v.status == #Background)
  let getInactiveViewer = () => getInactive()->Option.flatMap(v => v.instance)
  let swapActive = () =>
    pool->Belt.Array.forEach(v =>
      v.status = switch v.status {
      | #Active => #Background
      | #Background => #Active
      | #Free => #Free
      }
    )
  let registerInstance = (cId, inst) =>
    pool->Belt.Array.forEach(v =>
      if v.containerId == cId {
        v.instance = Some(inst)
      }
    )
  let clearInstance = cId =>
    pool->Belt.Array.forEach(v =>
      if v.containerId == cId {
        v.instance = None
      }
    )
  let setCleanupTimeout = (id, t) =>
    pool->Belt.Array.forEach(v =>
      if v.id == id {
        v.cleanupTimeout->Option.forEach(Window.clearTimeout)
        v.cleanupTimeout = t
      }
    )
  let clearCleanupTimeout = id =>
    pool->Belt.Array.forEach(v =>
      if v.id == id {
        v.cleanupTimeout->Option.forEach(Window.clearTimeout)
        v.cleanupTimeout = None
      }
    )
}

// --- FOLLOW (from ViewerFollow.res) ---

module Follow = {
  let rec updateFollowLoop = () => {
    let busy =
      Dom.getElementById("processing-ui")
      ->Nullable.toOption
      ->Option.map(el => !(Dom.classList(el)->Dom.ClassList.contains("hidden")))
      ->Option.getOr(false)
    if !busy {
      let vOpt = Pool.getActiveViewer()
      let s = GlobalStateBridge.getState()
      let hasHotspots = if s.activeIndex >= 0 && s.activeIndex < Array.length(s.scenes) {
        s.scenes[s.activeIndex]
        ->Option.map(sc => Array.length(sc.hotspots) > 0)
        ->Option.getOr(false)
      } else {
        false
      }
      let fsmBusy = switch s.navigationFsm {
      | Preloading(_) | Transitioning(_) | Stabilizing(_) => true
      | _ => false
      }

      if !ViewerState.state.followLoopActive || vOpt == None || (!s.isLinking && !hasHotspots) {
        if !fsmBusy {
          Dom.getElementById("viewer-hotspot-lines")
          ->Nullable.toOption
          ->Option.forEach(el => Dom.setTextContent(el, ""))
        }
        ViewerState.state.followLoopActive = false
      } else {
        if s.isLinking {
          let getEdgePower = (val, dz) => {
            let a = Math.abs(val)
            if a > dz {
              let s = val > 0.0 ? 1.0 : -1.0
              let n = (a -. dz) /. (1.0 -. dz)
              s *. (n *. n)
            } else {
              0.0
            }
          }
          let startPt = ViewerState.state.linkingStartPoint->Nullable.toOption
          let lastMouse = ViewerState.state.lastMouseEvent->Nullable.toOption
          let insideDz = switch (startPt, lastMouse) {
          | (Some(st), Some(ev)) =>
            let d = Math.sqrt(
              (Belt.Int.toFloat(Dom.clientX(ev)) -. st["x"]) ** 2.0 +.
                (Belt.Int.toFloat(Dom.clientY(ev)) -. st["y"]) ** 2.0,
            )
            if d > 150.0 {
              ViewerState.state.linkingStartPoint = Nullable.null
              false
            } else {
              true
            }
          | (Some(_), None) => true
          | _ => false
          }
          let getBoost = vel => {
            let a = Math.abs(vel)
            if a > 500.0 {
              Math.min((a -. 500.0) /. 3000.0, 1.5)
            } else {
              0.0
            }
          }
          let yb = getBoost(ViewerState.state.mouseVelocityX)
          let pb = getBoost(ViewerState.state.mouseVelocityY)
          let yd = insideDz
            ? 0.0
            : getEdgePower(ViewerState.state.mouseXNorm, 0.5) *. 1.5 *. (1.0 +. yb)
          let pd = insideDz
            ? 0.0
            : -.getEdgePower(ViewerState.state.mouseYNorm, 0.5) *. 1.0 *. (1.0 +. pb)
          ViewerState.state.lastAppliedYaw = Nullable.null
          ViewerState.state.lastAppliedPitch = Nullable.null
          vOpt->Option.forEach(v => {
            if yd != 0.0 {
              Viewer.setYaw(v, Viewer.getYaw(v) +. yd, false)
            }
            if pd != 0.0 {
              Viewer.setPitch(v, Viewer.getPitch(v) +. pd, false)
            }
          })
        }
        if !ViewerState.state.isSwapping {
          let me = ViewerState.state.lastMouseEvent->Nullable.toOption
          vOpt->Option.forEach(v => {
            try {HotspotLine.updateLines(v, s, ~mouseEvent=?me, ())} catch {
            | _ => ()
            }
          })
        }
        let _ = Window.requestAnimationFrame(updateFollowLoop)
      }
    }
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
  Pool.pool->Belt.Array.forEach(v => {
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
