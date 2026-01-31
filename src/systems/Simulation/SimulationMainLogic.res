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

let getNextMove = (state: state): nextMove => {
  let simulation = state.simulation
  let visitedScenes = simulation.visitedScenes

  switch Belt.Array.get(state.scenes, state.activeIndex) {
  | Some(currentScene) =>
    let nextLinkFound = SimulationNavigation.findBestNextLink(currentScene, state, visitedScenes)
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
