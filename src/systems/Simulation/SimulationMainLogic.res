/* src/systems/Simulation/SimulationMainLogic.res */

open Types
open Actions
@@warning("-45")
open SimulationTypes

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

let selectArrivalHotspot = (state: state, scene: scene, visitedAfterArrival: array<int>): option<
  hotspot,
> => {
  SimulationNavigation.findBestNextLink(scene, state, visitedAfterArrival)
  ->Option.map(link => link.hotspot)
  ->Option.orElse(
    scene.hotspots
    ->Belt.Array.getBy(h => h.isReturnLink != Some(true))
    ->Option.orElse(scene.hotspots->Belt.Array.get(0)),
  )
}

let arrivalFromTargetScene = (
  state: state,
  targetIndex: int,
  visitedAfterArrival: array<int>,
): option<(float, float, float)> => {
  Belt.Array.get(state.scenes, targetIndex)->Option.flatMap(scene => {
    let candidate = selectArrivalHotspot(state, scene, visitedAfterArrival)

    candidate->Option.map(h => (
      h.startYaw->Option.getOr(h.yaw),
      h.startPitch->Option.getOr(h.pitch),
      h.startHfov->Option.getOr(h.targetHfov->Option.getOr(90.0)),
    ))
  })
}

let getNextMove = (state: state): nextMove => {
  let simulation = state.simulation
  let visitedScenes = simulation.visitedScenes

  switch Belt.Array.get(state.scenes, state.activeIndex) {
  | Some(currentScene) =>
    Logger.debug(
      ~module_="SimulationMainLogic",
      ~message="GET_NEXT_MOVE",
      ~data=Some({
        "currentSceneId": currentScene.id,
        "currentSceneName": currentScene.name,
        "activeIndex": state.activeIndex,
        "visitedScenes": visitedScenes,
        "hotspotCount": Belt.Array.length(currentScene.hotspots),
      }),
      (),
    )
    let nextLinkFound = SimulationNavigation.findBestNextLink(currentScene, state, visitedScenes)
    Logger.debug(
      ~module_="SimulationMainLogic",
      ~message="NEXT_LINK_RESULT",
      ~data=Some({
        "found": Belt.Option.isSome(nextLinkFound),
        "targetIndex": nextLinkFound->Belt.Option.map(l => l.targetIndex),
      }),
      (),
    )
    switch nextLinkFound {
    | Some(link) =>
      let (finalLink, extraVisited) = if simulation.skipAutoForwardGlobal {
        let skipResult = SimulationChainSkipper.skipAutoForwardChain(
          link,
          state,
          visitedScenes,
          _ => (),
        )
        (skipResult.finalLink, skipResult.skippedScenes)
      } else {
        (link, [])
      }

      let hotspot = finalLink.hotspot
      let targetIndex = finalLink.targetIndex
      let hotspotIndex = finalLink.hotspotIndex
      let visitedAfterArrival = Belt.Array.concat(
        Belt.Array.concat(visitedScenes, extraVisited),
        [targetIndex],
      )

      let (tYaw, tPitch, tHfov) = if finalLink.isReturn {
        hotspot.returnViewFrame
        ->Option.map(vf => (vf.yaw, vf.pitch, vf.hfov))
        ->Option.getOr((0.0, 0.0, 90.0))
      } else {
        let sourceFallback =
          hotspot.viewFrame
          ->Option.map(vf => (vf.yaw, vf.pitch, vf.hfov))
          ->Option.getOr(
            hotspot.targetYaw
            ->Option.map(y => (
              y,
              hotspot.targetPitch->Option.getOr(0.0),
              hotspot.targetHfov->Option.getOr(90.0),
            ))
            ->Option.getOr((hotspot.yaw, hotspot.pitch, hotspot.targetHfov->Option.getOr(90.0))),
          )

        arrivalFromTargetScene(state, targetIndex, visitedAfterArrival)->Option.getOr(
          sourceFallback,
        )
      }

      let isComplete = if targetIndex == 0 {
        switch Belt.Array.get(state.scenes, 0) {
        | Some(startScene) =>
          !Belt.Array.some(startScene.hotspots, h => {
            HotspotTarget.resolveSceneIndex(state.scenes, h)
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
