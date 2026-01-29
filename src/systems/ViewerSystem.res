/* src/systems/ViewerSystem.res - Consolidated Viewer System */

open ReBindings

// --- ADAPTER (from PannellumAdapter.res) ---

module Adapter = {
  type t = Viewer.t
  type customViewerProps
  external asCustom: Viewer.t => customViewerProps = "%identity"

  @get @return(nullable) external getSceneId: customViewerProps => option<string> = "_sceneId"
  @set external setSceneId: (customViewerProps, string) => unit = "_sceneId"

  @get @return(nullable) external getIsLoaded: customViewerProps => option<bool> = "_isLoaded"
  @set external setIsLoaded: (customViewerProps, bool) => unit = "_isLoaded"

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
  let isLoaded = v => asCustom(v)->getIsLoaded->Option.getOr(false)
  let setMetaData = (v, key, value) => {
    let c = asCustom(v)
    if key == "sceneId" {
      setSceneId(c, Obj.magic(value))
    } else if key == "isLoaded" {
      setIsLoaded(c, Obj.magic(value))
    }
  }
  let getMetaData = (v, key) => {
    let c = asCustom(v)
    if key == "sceneId" {
      Some(Obj.magic(getSceneId(c)))
    } else if key == "isLoaded" {
      Some(Obj.magic(getIsLoaded(c)))
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
    instance: option<Adapter.t>,
    status: status,
    cleanupTimeout: option<int>,
  }
  let pool = ref([
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
  ])
  let getViewport = id => pool.contents->Belt.Array.getBy(v => v.id == id)
  let getViewportByContainer = cId => pool.contents->Belt.Array.getBy(v => v.containerId == cId)
  let getActive = () => pool.contents->Belt.Array.getBy(v => v.status == #Active)
  let getActiveViewer = () => getActive()->Option.flatMap(v => v.instance)
  let getInactive = () => pool.contents->Belt.Array.getBy(v => v.status == #Background)
  let getInactiveViewer = () => getInactive()->Option.flatMap(v => v.instance)
  let swapActive = () =>
    pool :=
      pool.contents->Belt.Array.map(v => {
        ...v,
        status: switch v.status {
        | #Active => #Background
        | #Background => #Active
        | #Free => #Free
        },
      })
  let registerInstance = (cId, inst) =>
    pool :=
      pool.contents->Belt.Array.map(v =>
        if v.containerId == cId {
          {...v, instance: Some(inst)}
        } else {
          v
        }
      )
  let clearInstance = cId =>
    pool :=
      pool.contents->Belt.Array.map(v =>
        if v.containerId == cId {
          {...v, instance: None}
        } else {
          v
        }
      )
  let setCleanupTimeout = (id, t) =>
    pool :=
      pool.contents->Belt.Array.map(v =>
        if v.id == id {
          v.cleanupTimeout->Option.forEach(Window.clearTimeout)
          {...v, cleanupTimeout: t}
        } else {
          v
        }
      )
  let clearCleanupTimeout = id =>
    pool :=
      pool.contents->Belt.Array.map(v =>
        if v.id == id {
          v.cleanupTimeout->Option.forEach(Window.clearTimeout)
          {...v, cleanupTimeout: None}
        } else {
          v
        }
      )
}

// --- FOLLOW (from ViewerFollow.res) ---

module Follow = {
  let isInsideDeadZone = (startPt, lastMouse) => {
    switch (startPt, lastMouse) {
    | (Some(st), Some(ev)) =>
      let d = Math.sqrt(
        (Belt.Int.toFloat(Dom.clientX(ev)) -. st["x"]) ** 2.0 +.
          (Belt.Int.toFloat(Dom.clientY(ev)) -. st["y"]) ** 2.0,
      )
      if d > 150.0 {
        (false, true)
      } else {
        (true, false)
      }
    | (Some(_), None) => (true, false)
    | _ => (false, false)
    }
  }

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

      if (
        !ViewerState.state.contents.followLoopActive ||
        vOpt == None ||
        (!s.isLinking && !hasHotspots)
      ) {
        if !fsmBusy {
          Dom.getElementById("viewer-hotspot-lines")
          ->Nullable.toOption
          ->Option.forEach(el => Dom.setTextContent(el, ""))
        }
        ViewerState.state := {...ViewerState.state.contents, followLoopActive: false}
      } else {
        if s.isLinking {
          let startPt = ViewerState.state.contents.linkingStartPoint->Nullable.toOption
          let lastMouse = ViewerState.state.contents.lastMouseEvent->Nullable.toOption
          let (insideDz, shouldReset) = isInsideDeadZone(startPt, lastMouse)

          if shouldReset {
            ViewerState.state := {...ViewerState.state.contents, linkingStartPoint: Nullable.null}
          }

          let yb = ViewerLogic.getBoost(ViewerState.state.contents.mouseVelocityX)
          let pb = ViewerLogic.getBoost(ViewerState.state.contents.mouseVelocityY)
          let yd = insideDz
            ? 0.0
            : ViewerLogic.getEdgePower(ViewerState.state.contents.mouseXNorm, 0.5) *. 1.5 *. (1.0 +. yb)
          let pd = insideDz
            ? 0.0
            : -.ViewerLogic.getEdgePower(ViewerState.state.contents.mouseYNorm, 0.5) *. 1.0 *. (1.0 +. pb)
          ViewerState.state := {
              ...ViewerState.state.contents,
              lastAppliedYaw: Nullable.null,
              lastAppliedPitch: Nullable.null,
            }
          vOpt->Option.forEach(v => {
            if yd != 0.0 {
              Viewer.setYaw(v, Viewer.getYaw(v) +. yd, false)
            }
            if pd != 0.0 {
              Viewer.setPitch(v, Viewer.getPitch(v) +. pd, false)
            }
          })
        }
        if !ViewerState.state.contents.isSwapping {
          let me = ViewerState.state.contents.lastMouseEvent->Nullable.toOption
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
