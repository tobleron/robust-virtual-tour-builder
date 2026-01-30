/* src/systems/SimulationLogic.res */

open ReBindings
open Types
open Actions

// --- BINDINGS (INTERNAL) ---

@val external setTimeout: (unit => 'a, int) => int = "setTimeout"
@val external clearTimeout: int => unit = "clearTimeout"

module InternalDate = {
  @val @scope("Date") external now: unit => float = "now"
}

// --- TYPES ---

type enrichedLink = {
  hotspot: hotspot,
  hotspotIndex: int,
  targetIndex: int,
  isVisited: bool,
  isReturn: bool,
  isBridge: bool,
}

type skipResult = {
  finalLink: enrichedLink,
  skippedScenes: array<int>,
}

type arrivalView = {
  yaw: float,
  pitch: float,
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
  transitionTarget: option<transitionTarget>,
  arrivalView: arrivalView,
}

// --- UTILS: NAVIGATION ---

module Navigation = {
  let findViewerForScene = (sceneId: string): option<Viewer.t> => {
    let globalViewer = Nullable.toOption(Viewer.instance)
    switch globalViewer {
    | Some(v)
      if ViewerSystem.Adapter.getSceneId(ViewerSystem.Adapter.asCustom(v)) == Some(sceneId) =>
      Some(v)
    | _ =>
      ViewerSystem.Pool.pool.contents
      ->Belt.Array.getBy(vp => {
        switch vp.instance {
        | Some(v) =>
          ViewerSystem.Adapter.getSceneId(ViewerSystem.Adapter.asCustom(v)) == Some(sceneId)
        | None => false
        }
      })
      ->Option.flatMap(vp => vp.instance)
    }
  }

  let waitForViewerScene = async (
    sceneIndex: int,
    isAutoPilotActive: unit => bool,
    ~maxRetries=3,
    (),
  ): result<unit, string> => {
    let state = GlobalStateBridge.getState()
    switch Belt.Array.get(state.scenes, sceneIndex) {
    | Some(expectedScene) =>
      let rec attemptLoad = async (attempt: int) => {
        let timeout = Float.fromInt(Constants.sceneLoadTimeout)
        let start = InternalDate.now()
        let loop = ref(true)
        let currentResult = ref(Ok())

        while loop.contents {
          if !isAutoPilotActive() {
            loop := false
          } else if InternalDate.now() -. start > timeout {
            loop := false
            currentResult :=
              Error("Timeout waiting for viewer to load scene " ++ expectedScene.name)
          } else {
            let v = findViewerForScene(expectedScene.id)
            switch v {
            | Some(viewer) =>
              if ViewerSystem.isViewerReady(viewer) {
                loop := false
              } else {
                let _ = await Promise.make((resolve, _) => {
                  let _ = setTimeout(() => resolve(), 100)
                })
              }
            | None =>
              let _ = await Promise.make((resolve, _) => {
                let _ = setTimeout(() => resolve(), 100)
              })
            }
          }
        }

        switch currentResult.contents {
        | Ok() => Ok()
        | Error(msg) =>
          if attempt < maxRetries && isAutoPilotActive() {
            let nextAttempt = attempt + 1
            Logger.warn(
              ~module_="Simulation",
              ~message="SCENE_LOAD_RETRY",
              ~data=Some({"scene": expectedScene.name, "attempt": nextAttempt, "error": msg}),
              (),
            )
            EventBus.dispatch(ShowNotification("Retrying scene load...", #Warning))
            let backoffMs = switch attempt {
            | 1 => 1000
            | 2 => 2000
            | _ => 4000
            }
            let _ = await Promise.make((resolve, _) => {
              let _ = setTimeout(() => resolve(), backoffMs)
            })
            await attemptLoad(nextAttempt)
          } else {
            Error(msg)
          }
        }
      }
      await attemptLoad(1)
    | None => Error("Scene index out of bounds")
    }
  }

  let findBestNextLink = (currentScene: scene, state: state, visited: array<int>): option<
    enrichedLink,
  > => {
    let hotspots = currentScene.hotspots
    if Array.length(hotspots) == 0 {
      None
    } else {
      let allLinks =
        hotspots
        ->Belt.Array.mapWithIndex((i, hotspot) => {
          let targetIdx = Belt.Array.getIndexBy(state.scenes, s => s.name == hotspot.target)
          switch targetIdx {
          | Some(idx) =>
            switch Belt.Array.get(state.scenes, idx) {
            | Some(targetScene) =>
              Some({
                hotspot,
                hotspotIndex: i,
                targetIndex: idx,
                isVisited: Array.includes(visited, idx),
                isReturn: hotspot.isReturnLink->Option.getOr(false),
                isBridge: targetScene.isAutoForward,
              })
            | None => None
            }
          | None => None
          }
        })
        ->Belt.Array.keepMap(x => x)

      let p1 = Array.find(allLinks, l => !l.isVisited && !l.isReturn && !l.isBridge)
      switch p1 {
      | Some(l) => Some(l)
      | None =>
        let p2 = Array.find(allLinks, l => !l.isVisited && !l.isReturn && l.isBridge)
        switch p2 {
        | Some(l) => Some(l)
        | None =>
          let p3 = Array.find(allLinks, l => !l.isVisited && l.isReturn && !l.isBridge)
          switch p3 {
          | Some(l) => Some(l)
          | None =>
            let p4 = Array.find(allLinks, l => !l.isVisited && l.isReturn && l.isBridge)
            switch p4 {
            | Some(l) => Some(l)
            | None =>
              let p5 = Array.find(allLinks, l => !l.isReturn)
              switch p5 {
              | Some(l) => Some(l)
              | None => Array.find(allLinks, l => l.isReturn)
              }
            }
          }
        }
      }
    }
  }
}

// --- LOGIC: CHAIN SKIPPER ---

module ChainSkipper = {
  let skipAutoForwardChain = (
    initialLink: enrichedLink,
    state: state,
    visitedScenes: array<int>,
    onVisitScene: int => unit,
  ): skipResult => {
    let chainCounter = ref(0)
    let originalHotspotIndex = initialLink.hotspotIndex
    let originalHotspot = initialLink.hotspot
    let currentLink = ref(initialLink)
    let skippedScenes = []
    let loop = ref(true)

    while loop.contents && chainCounter.contents < 10 {
      switch Belt.Array.get(state.scenes, currentLink.contents.targetIndex) {
      | Some(targetScene) =>
        if !targetScene.isAutoForward {
          loop := false
        } else {
          if !Array.includes(visitedScenes, currentLink.contents.targetIndex) {
            onVisitScene(currentLink.contents.targetIndex)
            let _ = Array.push(skippedScenes, currentLink.contents.targetIndex)
          }
          switch Navigation.findBestNextLink(targetScene, state, visitedScenes) {
          | Some(jumpLink) =>
            currentLink := {
                ...jumpLink,
                hotspotIndex: originalHotspotIndex,
                hotspot: originalHotspot,
              }
            chainCounter := chainCounter.contents + 1
          | None => loop := false
          }
        }
      | None => loop := false
      }
    }
    {finalLink: currentLink.contents, skippedScenes}
  }
}

// --- LOGIC: PATH GENERATOR ---

module PathGenerator = {
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

      let initialArrivalView = switch Belt.Array.get(state.scenes, 0) {
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
          switch Belt.Array.get(state.scenes, currentIdx.contents) {
          | Some(currentScene) =>
            let nextLinkOpt = ref(Navigation.findBestNextLink(currentScene, state, localVisited))
            if skipAutoForward {
              switch nextLinkOpt.contents {
              | Some(link) =>
                let skipResult = ChainSkipper.skipAutoForwardChain(
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
                      targetName: Belt.Array.get(state.scenes, targetIdx)
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
}

// --- LOGIC: MAIN ---

module Logic = {
  type nextMove =
    | Move({
        targetIndex: int,
        hotspotIndex: int,
        yaw: float,
        pitch: float,
        hfov: float,
        triggerActions: array<action>,
      })
    | Complete({reason: string})
    | None

  let getNextMove = (state: state): nextMove => {
    let simulation = state.simulation
    let visitedScenes = simulation.visitedScenes

    switch Belt.Array.get(state.scenes, state.activeIndex) {
    | Some(currentScene) =>
      let nextLinkFound = Navigation.findBestNextLink(currentScene, state, visitedScenes)
      switch nextLinkFound {
      | Some(link) =>
        let (finalLink, extraVisited) = if simulation.skipAutoForwardGlobal {
          let skipResult = ChainSkipper.skipAutoForwardChain(link, state, visitedScenes, _ => ())
          (skipResult.finalLink, skipResult.skippedScenes)
        } else {
          (link, [])
        }

        let hotspot = finalLink.hotspot
        let targetIndex = finalLink.targetIndex
        let hotspotIndex = finalLink.hotspotIndex

        let (tYaw, tPitch, tHfov) = if finalLink.isReturn {
          hotspot.returnViewFrame
          ->Option.map(vf => (vf.yaw, vf.pitch, vf.hfov))
          ->Option.getOr((0.0, 0.0, 90.0))
        } else {
          hotspot.viewFrame
          ->Option.map(vf => (vf.yaw, vf.pitch, vf.hfov))
          ->Option.getOr(
            hotspot.targetYaw
            ->Option.map(y => (
              y,
              hotspot.targetPitch->Option.getOr(0.0),
              hotspot.targetHfov->Option.getOr(90.0),
            ))
            ->Option.getOr((0.0, 0.0, 90.0)),
          )
        }

        let isComplete = if targetIndex == 0 {
          switch Belt.Array.get(state.scenes, 0) {
          | Some(startScene) =>
            !Belt.Array.some(startScene.hotspots, h => {
              Belt.Array.getIndexBy(state.scenes, s => s.name == h.target)
              ->Option.map(i => !Array.includes(visitedScenes, i))
              ->Option.getOr(false)
            })
          | None => false
          }
        } else {
          false
        }

        if isComplete {
          Complete({reason: "returned_to_start"})
        } else {
          let actions = []
          extraVisited->Belt.Array.forEach(idx => {
            let _ = Array.push(actions, AddVisitedScene(idx))
          })
          let timelineItem = Array.find(state.timeline, item =>
            item.sceneId == currentScene.id && item.linkId == hotspot.linkId
          )
          let _ = Array.push(
            actions,
            SetActiveTimelineStep(timelineItem->Option.map(item => item.id)),
          )
          let finalActions = Belt.Array.concat(actions, [AddVisitedScene(targetIndex)])

          Move({
            targetIndex,
            hotspotIndex,
            yaw: tYaw,
            pitch: tPitch,
            hfov: tHfov,
            triggerActions: finalActions,
          })
        }
      | None => Complete({reason: "no_reachable_scenes"})
      }
    | None => Complete({reason: "invalid_current_scene"})
    }
  }
}
