open Types
open SimulationChainSkipper

// Note: transitionState and arrivalView use mutable fields for animation performance
// This is acceptable as it's scoped to animation frames and not app state
/**
 * Path Generation for Simulation Teaser/Preview
 * 
 * This module computes a pre-calculated path through all scenes for the
 * simulation teaser feature. It simulates the autopilot logic to generate
 * a sequence of scene transitions that can be used for preview or animation.
 */
type arrivalView = {
  mutable yaw: float,
  mutable pitch: float,
}

type transitionTarget = {
  yaw: float,
  pitch: float,
  targetName: string,
  startYaw: float,
  startPitch: float,
  waypoints: array<viewFrame>,
}

type pathStep = {
  idx: int,
  mutable transitionTarget: option<transitionTarget>,
  mutable arrivalView: arrivalView,
}

/**
 * Generates a complete simulation path for preview/teaser purposes.
 * 
 * @param skipAutoForward - Whether to skip through auto-forward bridge scenes
 * @returns Array of pathStep objects representing the complete simulation path
 */
let getSimulationPath = (skipAutoForward: bool): array<pathStep> => {
  let state = GlobalStateBridge.getState()
  if Array.length(state.scenes) == 0 {
    []
  } else {
    let path = []
    let localVisited = [0]
    let currentIdx = ref(0)
    let loopCount = ref(0)
    let maxSteps = 50

    // Initial setup
    let currentPathObj = {
      idx: 0,
      transitionTarget: None,
      arrivalView: {yaw: 0.0, pitch: 0.0},
    }

    switch Belt.Array.get(state.scenes, 0) {
    | Some(firstScene) =>
      if Array.length(firstScene.hotspots) > 0 {
        switch Belt.Array.get(firstScene.hotspots, 0) {
        | Some(startHotspot) =>
          switch startHotspot.viewFrame {
          | Some(vf) =>
            currentPathObj.arrivalView.yaw = vf.yaw
            currentPathObj.arrivalView.pitch = vf.pitch
          | None => ()
          }
        | None => ()
        }
      }
    | None => ()
    }

    let _ = Js.Array.push(currentPathObj, path)
    let activePathObj = ref(currentPathObj)

    let visitedStateSet = [] // strings "idx->target"
    let pathSet = [] // strings "idx->target"

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
        switch Belt.Array.get(state.scenes, currentIdx.contents) {
        | Some(currentScene) =>
          // Find next link
          let nextLinkOpt = ref(
            SimulationNavigation.findBestNextLink(currentScene, state, localVisited),
          )

          // Skip Auto Forward Logic
          if skipAutoForward {
            switch nextLinkOpt.contents {
            | Some(link) =>
              let skipResult = skipAutoForwardChain(link, state, localVisited, sceneIdx => {
                let _ = Js.Array.push(sceneIdx, localVisited)
              })

              // Use the final target but keep original hotspot for visuals
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
            if Js.Array.includes(stateKey, visitedStateSet) {
              Logger.warn(
                ~module_="Simulation",
                ~message="INFINITE_LOOP_DETECTED",
                ~data=Some({
                  "stateKey": stateKey,
                  "visitedScenes": visitedStateSet,
                }),
                (),
              )
              loop := false
            } else {
              let _ = Js.Array.push(stateKey, visitedStateSet)
              let _ = Js.Array.push(stateKey, pathSet)

              // 1. Update current path obj (activePathObj)
              let transYaw = switch hotspot.viewFrame {
              | Some(vf) => vf.yaw
              | None => hotspot.yaw
              }
              let transPitch = switch hotspot.viewFrame {
              | Some(vf) => vf.pitch
              | None => hotspot.pitch
              }

              let waypoints = switch hotspot.waypoints {
              | Some(w) => w
              | None => []
              }

              activePathObj.contents.transitionTarget = Some({
                yaw: transYaw,
                pitch: transPitch,
                targetName: hotspot.target,
                startYaw: switch hotspot.startYaw {
                | Some(y) => y
                | None => 0.0
                },
                startPitch: switch hotspot.startPitch {
                | Some(p) => p
                | None => 0.0
                },
                waypoints,
              })

              // 2. Prepare next
              let arrivalYaw = ref(0.0)
              let arrivalPitch = ref(0.0)

              // Logic for arrival
              if link.isReturn {
                switch hotspot.returnViewFrame {
                | Some(vf) =>
                  arrivalYaw := vf.yaw
                  arrivalPitch := vf.pitch
                | _ => () // Keep 0
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
                    arrivalPitch :=
                      switch hotspot.targetPitch {
                      | Some(p) => p
                      | None => 0.0
                      }
                  | None => ()
                  }
                }
              }

              let nextPathObj = {
                idx: targetIdx,
                transitionTarget: None,
                arrivalView: {yaw: arrivalYaw.contents, pitch: arrivalPitch.contents},
              }

              let _ = Js.Array.push(nextPathObj, path)
              activePathObj := nextPathObj

              let _ = Js.Array.push(targetIdx, localVisited)
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

    // Telemetry
    Logger.debug(
      ~module_="Simulation",
      ~message="PATH_COMPUTED",
      ~data=Some({
        "steps": Array.length(path),
        "visited": Array.length(localVisited),
      }),
      (),
    )

    path
  }
}
