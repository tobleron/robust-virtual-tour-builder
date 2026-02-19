// @efficiency-role: ui-component

open ReBindings
open Types

// Hook 10: Intro Pan logic
let useIntroPan = (
  ~navigationState: navigationState,
  ~activeIndex: int,
  ~isLinking: bool,
  ~isTeasing: bool,
  ~scenes: array<scene>,
  ~simulationStatus: simulationStatus,
) => {
  let lastPannedSceneId = React.useRef(Nullable.null)

  React.useEffect3(() => {
    let isIdle = navigationState.navigationFsm == IdleFsm

    if isIdle && activeIndex != -1 && !isLinking && !isTeasing {
      switch Belt.Array.get(scenes, activeIndex) {
      | Some(scene) =>
        if lastPannedSceneId.current != Nullable.make(scene.id) {
          let hotspotsWithWaypoints = scene.hotspots->Belt.Array.keep(h =>
            switch h.waypoints {
            | Some(w) => Array.length(w) > 0
            | None => false
            }
          )

          if Array.length(hotspotsWithWaypoints) == 0 {
            lastPannedSceneId.current = Nullable.make(scene.id)
          } else {
            let v = ViewerSystem.getActiveViewer()
            switch Nullable.toOption(v) {
            | Some(viewer) =>
              if ViewerSystem.isViewerReady(viewer) {
                let targetHotspot =
                  hotspotsWithWaypoints
                  ->Belt.Array.getBy(h => h.isReturnLink != Some(true))
                  ->Option.getOr(hotspotsWithWaypoints->Belt.Array.get(0)->Option.getOrThrow)

                let ty = targetHotspot.startYaw->Option.getOr(targetHotspot.yaw)
                let tp = targetHotspot.startPitch->Option.getOr(targetHotspot.pitch)

                Logger.info(
                  ~module_="ViewerManagerIntro",
                  ~message="INTRO_PAN_TRIGGERED",
                  ~data=Some({"sceneId": scene.id, "targetYaw": ty, "targetPitch": tp}),
                  (),
                )

                lastPannedSceneId.current = Nullable.make(scene.id)

                // Slow, gentle pan (2000ms duration)
                Viewer.setYawWithDuration(viewer, ty, 2000)
                Viewer.setPitchWithDuration(viewer, tp, 2000)
              }
            | None => ()
            }
          }
        }
      | None => ()
      }
    }
    None
  }, (activeIndex, navigationState.navigationFsm, simulationStatus))
}
