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

let selectArrivalHotspot = (state: state, scene: scene, _visited: array<string>): option<
  hotspot,
> => {
  // Use linkId-based link finding
  SimulationNavigation.findBestNextLinkByLinkId(scene, state, _visited)
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
  visitedLinkIds: array<string>,
): option<(float, float, float)> => {
  let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
  Belt.Array.get(activeScenes, targetIndex)->Option.flatMap(scene => {
    let candidate = selectArrivalHotspot(state, scene, visitedLinkIds)

    candidate->Option.map(h => (
      h.startYaw->Option.getOr(h.yaw),
      h.startPitch->Option.getOr(h.pitch),
      h.startHfov->Option.getOr(h.targetHfov->Option.getOr(90.0)),
    ))
  })
}

let getNextMove = (state: state): nextMove => {
  let simulation = state.simulation
  let visitedLinkIds = simulation.visitedLinkIds

  let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
  switch Belt.Array.get(activeScenes, state.activeIndex) {
  | Some(currentScene) =>
    Logger.debug(
      ~module_="SimulationMainLogic",
      ~message="GET_NEXT_MOVE",
      ~data=Some({
        "currentSceneId": currentScene.id,
        "currentSceneName": currentScene.name,
        "activeIndex": state.activeIndex,
        "visitedLinkIds": visitedLinkIds,
        "hotspotCount": Belt.Array.length(currentScene.hotspots),
      }),
      (),
    )
    let nextLinkFound = SimulationNavigation.findBestNextLinkByLinkId(currentScene, state, visitedLinkIds)
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
        // Note: skipAutoForwardChain uses scene-based tracking internally for chain detection
        // The main visited tracking is via visitedLinkIds (AddVisitedLink action)
        // We pass [] here since chain skipping is an optimization, not the main traversal logic
        let skipResult = SimulationChainSkipper.skipAutoForwardChain(
          link,
          state,
          [],
          _ => (),
        )
        (skipResult.finalLink, skipResult.skippedScenes)
      } else {
        (link, [])
      }

      let hotspot = finalLink.hotspot
      let targetIndex = finalLink.targetIndex
      let hotspotIndex = finalLink.hotspotIndex
      // Note: visitedAfterArrival kept for backward compatibility with helper functions
      // Main tracking is via visitedLinkIds which is updated by AddVisitedLink action
      let visitedAfterArrival = visitedLinkIds

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

      // Check if tour is complete: we are taking a visited link back to start and all links from start have been traversed
      let isComplete = if targetIndex == 0 && finalLink.isVisited {
        let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
        switch Belt.Array.get(activeScenes, 0) {
        | Some(startScene) =>
          // Check if all hotspots from start scene have their linkId in visitedLinkIds
          !Belt.Array.some(startScene.hotspots, h => {
            !Array.includes(visitedLinkIds, h.linkId)
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
        // Note: extraVisited is for auto-forward chain skipping (scene indices)
        // We still process these but the main tracking is by linkId
        extraVisited->Belt.Array.forEach(idx => {
          // Skip scene-based tracking, linkId tracking handles this
          let _ = idx
        })
        let timelineItem = Array.find(state.timeline, item =>
          item.sceneId == currentScene.id && item.linkId == hotspot.linkId
        )
        let _ = Array.push(
          actions,
          SetActiveTimelineStep(timelineItem->Option.map(item => item.id)),
        )
        // KEY CHANGE: Add the linkId to visited, not the scene index
        let finalActions = Belt.Array.concat(actions, [AddVisitedLink(hotspot.linkId)])

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
