// @efficiency-role: ui-component

open ReBindings
open Types

external idToUnknown: string => unknown = "%identity"

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
  let prevSimulationStatus = React.useRef(simulationStatus)
  let hasPannedForCurrentSimulation = React.useRef(false)

  // Reset tracking when simulation starts to guarantee the first scene pans
  React.useEffect1(() => {
    if prevSimulationStatus.current != Running && simulationStatus == Running {
      Logger.info(~module_="ViewerManagerIntro", ~message="SIMULATION_START_RESET_PAN_TRACKER", ())
      lastPannedSceneId.current = Nullable.null
      hasPannedForCurrentSimulation.current = false
    } else if prevSimulationStatus.current == Running && simulationStatus != Running {
      hasPannedForCurrentSimulation.current = false
    }
    prevSimulationStatus.current = simulationStatus
    None
  }, [simulationStatus])

  React.useEffect3(() => {
    let isIdle = navigationState.navigationFsm == IdleFsm

    if (
      simulationStatus == Running &&
      activeIndex != -1 &&
      !isLinking &&
      !isTeasing &&
      !hasPannedForCurrentSimulation.current
    ) {
      switch Belt.Array.get(scenes, activeIndex) {
      | Some(scene) =>
        if lastPannedSceneId.current != Nullable.make(scene.id) {
          if !isIdle {
            Logger.debug(
              ~module_="ViewerManagerIntro",
              ~message="PAN_DELAYED_NOT_IDLE",
              ~data=Some({"fsm": NavigationFSM.toString(navigationState.navigationFsm)}),
              (),
            )
          } else {
            let hotspotsWithWaypoints = scene.hotspots->Belt.Array.keep(h =>
              switch h.waypoints {
              | Some(w) => Array.length(w) > 0
              | None => false
              }
            )

            if Array.length(hotspotsWithWaypoints) == 0 {
              lastPannedSceneId.current = Nullable.make(scene.id)
              hasPannedForCurrentSimulation.current = true
            } else {
              let v = ViewerSystem.getActiveViewer()
              switch Nullable.toOption(v) {
              | Some(viewer) =>
                let viewerSceneId = ViewerSystem.Adapter.getMetaData(viewer, "sceneId")
                let targetId = idToUnknown(scene.id)

                if ViewerSystem.isViewerReady(viewer) && viewerSceneId == Some(targetId) {
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
                  hasPannedForCurrentSimulation.current = true

                  // Slow, gentle pan (2000ms duration)
                  Viewer.setYawWithDuration(viewer, ty, 2000)
                  Viewer.setPitchWithDuration(viewer, tp, 2000)
                } else if !isIdle {
                  Logger.debug(~module_="ViewerManagerIntro", ~message="PAN_DELAYED_NOT_IDLE", ())
                } else if viewerSceneId != Some(targetId) {
                  Logger.debug(
                    ~module_="ViewerManagerIntro",
                    ~message="PAN_DELAYED_SCENE_MISMATCH",
                    (),
                  )
                } else {
                  Logger.debug(
                    ~module_="ViewerManagerIntro",
                    ~message="PAN_DELAYED_VIEWER_NOT_READY",
                    (),
                  )
                }
              | None =>
                Logger.debug(~module_="ViewerManagerIntro", ~message="PAN_DELAYED_NO_VIEWER", ())
              }
            }
          }
        }
      | None => ()
      }
    }
    None
  }, (activeIndex, navigationState.navigationFsm, simulationStatus))
}
