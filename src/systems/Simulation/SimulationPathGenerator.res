/* src/systems/Simulation/SimulationPathGenerator.res */

open Types
@@warning("-45")

open SimulationTypes

let getSimulationPath = (
  skipAutoForward: bool,
  ~getState: unit => state=AppContext.getBridgeState,
): array<pathStep> => {
  let state = getState()
  let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
  if Array.length(activeScenes) == 0 {
    []
  } else {
    let path = []
    let localVisited = [0]
    let currentIdx = ref(0)
    let loopCount = ref(0)
    let maxSteps = 50

    let initialArrivalView = switch Belt.Array.get(activeScenes, 0) {
    | Some(firstScene) if Array.length(firstScene.hotspots) > 0 =>
      switch Belt.Array.get(firstScene.hotspots, 0) {
      | Some(startHotspot) =>
        switch startHotspot.viewFrame {
        | Some(vf) => {yaw: vf.yaw, pitch: vf.pitch}
        | None => {yaw: 0.0, pitch: 0.0}
        }
      | None => {yaw: 0.0, pitch: 0.0}
      }
    | _ => {yaw: 0.0, pitch: 0.0}
    }

    let currentPathObj = {idx: 0, transitionTarget: None, arrivalView: initialArrivalView}

    let _ = Array.push(path, currentPathObj)
    let activePathObjIdx = ref(0)
    let visitedStateSet = [] // "idx->target"
    let loop = ref(true)

    while loop.contents {
      if loopCount.contents >= maxSteps {
        Logger.warn(
          ~module_="Simulation",
          ~message="MAX_STEPS_REACHED",
          ~data=Some({"maxSteps": maxSteps}),
          (),
        )
        loop := false
      } else {
        switch Belt.Array.get(activeScenes, currentIdx.contents) {
        | Some(currentScene) =>
          let nextLinkOpt = ref(
            SimulationNavigation.findBestNextLink(currentScene, state, localVisited),
          )
          if skipAutoForward {
            switch nextLinkOpt.contents {
            | Some(link) =>
              let skipResult = SimulationChainSkipper.skipAutoForwardChain(
                link,
                state,
                localVisited,
                sceneIdx => {
                  let _ = Array.push(localVisited, sceneIdx)
                },
              )
              nextLinkOpt := Some(skipResult.finalLink)
            | None => ()
            }
          }

          switch nextLinkOpt.contents {
          | None => loop := false
          | Some(link) =>
            let hotspot = link.hotspot
            let targetIdx = link.targetIndex
            let stateKey =
              Belt.Int.toString(currentIdx.contents) ++ "->" ++ Belt.Int.toString(targetIdx)

            if Array.includes(visitedStateSet, stateKey) {
              Logger.warn(
                ~module_="Simulation",
                ~message="INFINITE_LOOP_DETECTED",
                ~data=Some({"stateKey": stateKey}),
                (),
              )
              loop := false
            } else {
              let _ = Array.push(visitedStateSet, stateKey)
              let transYaw = switch hotspot.viewFrame {
              | Some(vf) => vf.yaw
              | None => hotspot.yaw
              }
              let transPitch = switch hotspot.viewFrame {
              | Some(vf) => vf.pitch
              | None => hotspot.pitch
              }
              let waypoints = hotspot.waypoints->Option.getOr([])

              // Update the PREVIOUS step's transition target
              switch Belt.Array.get(path, activePathObjIdx.contents) {
              | Some(prev) =>
                path[
                  activePathObjIdx.contents
                ] = {
                  ...prev,
                  transitionTarget: Some({
                    yaw: transYaw,
                    pitch: transPitch,
                    targetName: Belt.Array.get(activeScenes, targetIdx)
                    ->Option.map(s => s.name)
                    ->Option.getOr(hotspot.target),
                    startYaw: hotspot.startYaw->Option.getOr(0.0),
                    startPitch: hotspot.startPitch->Option.getOr(0.0),
                    waypoints,
                  }),
                }
              | None => ()
              }

              let arrivalYaw = ref(0.0)
              let arrivalPitch = ref(0.0)
              if link.isReturn {
                switch hotspot.returnViewFrame {
                | Some(vf) =>
                  arrivalYaw := vf.yaw
                  arrivalPitch := vf.pitch
                | _ => ()
                }
              } else {
                switch hotspot.viewFrame {
                | Some(vf) =>
                  arrivalYaw := vf.yaw
                  arrivalPitch := vf.pitch
                | None =>
                  switch hotspot.targetYaw {
                  | Some(y) =>
                    arrivalYaw := y
                    arrivalPitch := hotspot.targetPitch->Option.getOr(0.0)
                  | None => ()
                  }
                }
              }

              let nextPathObj = {
                idx: targetIdx,
                transitionTarget: None,
                arrivalView: {yaw: arrivalYaw.contents, pitch: arrivalPitch.contents},
              }
              let _ = Array.push(path, nextPathObj)
              activePathObjIdx := Array.length(path) - 1
              let _ = Array.push(localVisited, targetIdx)
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
    path
  }
}
