open ReBindings
open Types

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

let rec updateFollowLoop = (~getState: unit => state) => {
  let busy =
    Dom.getElementById("processing-ui")
    ->Nullable.toOption
    ->Option.map(el => !(Dom.classList(el)->Dom.ClassList.contains("hidden")))
    ->Option.getOr(false)
  if !busy {
    let vOpt = ViewerPool.getActiveViewer()
    let s = getState()
    let scenes = SceneInventory.getActiveScenes(s.inventory, s.sceneOrder)
    let hasHotspots = if s.activeIndex >= 0 && s.activeIndex < Array.length(scenes) {
      scenes[s.activeIndex]
      ->Option.map(sc => Array.length(sc.hotspots) > 0)
      ->Option.getOr(false)
    } else {
      false
    }
    let fsmBusy = switch Nullable.toOption(ViewerAdapter.asAny(s)["navigationState"]) {
    | Some(ns) =>
      switch ns["navigationFsm"] {
      | Preloading(_) | Transitioning(_) | Stabilizing(_) => true
      | _ => false
      }
    | None => false
    }

    if (
      !ViewerState.state.contents.followLoopActive || vOpt == None || (!s.isLinking && !hasHotspots)
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
          : ViewerLogic.getEdgePower(ViewerState.state.contents.mouseXNorm, 0.5) *.
            1.5 *.
            (1.0 +. yb)
        let pd = insideDz
          ? 0.0
          : -.ViewerLogic.getEdgePower(ViewerState.state.contents.mouseYNorm, 0.5) *.
            1.0 *.
            (1.0 +. pb)
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
      if NavigationSupervisor.isIdle() {
        let me = ViewerState.state.contents.lastMouseEvent->Nullable.toOption
        vOpt->Option.forEach(v => {
          try {HotspotLine.updateLines(v, s, ~mouseEvent=?me, ())} catch {
          | _ => ()
          }
        })
      }
      let _ = Window.requestAnimationFrame(() => updateFollowLoop(~getState))
    }
  }
}
