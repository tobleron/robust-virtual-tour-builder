/* src/systems/SimulationLogic.res */
open Types
open Actions
module Nav = SimulationNavigation
open SimulationChainSkipper

type nextMove =
  | Move({
      targetIndex: int,
      hotspotIndex: int,
      yaw: float,
      pitch: float,
      hfov: float,
      triggerActions: array<action>,
    }) // Actions like AddVisitedScene, SetActiveTimelineStep
  | Complete({reason: string})
  | None // No valid move found

let getNextMove = (state: state): nextMove => {
  let simulation = state.simulation
  let visitedScenes = simulation.visitedScenes
  let currentSceneOpt = Belt.Array.get(state.scenes, state.activeIndex)

  switch currentSceneOpt {
  | Some(currentScene) =>
    let nextLinkFound = Nav.findBestNextLink(currentScene, state, visitedScenes)

    switch nextLinkFound {
    | Some(link) =>
      // Apply chain skipping if enabled
      let (finalLink, extraVisited) = if simulation.skipAutoForwardGlobal {
        let skipResult = skipAutoForwardChain(link, state, visitedScenes, _ => ()) // We gather IDs separately
        (skipResult.finalLink, skipResult.skippedScenes)
      } else {
        (link, [])
      }

      let hotspot = finalLink.hotspot
      let targetIndex = finalLink.targetIndex
      let hotspotIndex = finalLink.hotspotIndex

      // Determine View Frame
      let (tYaw, tPitch, tHfov) = if finalLink.isReturn {
        switch hotspot.returnViewFrame {
        | Some(vf) => (vf.yaw, vf.pitch, vf.hfov)
        | None => (0.0, 0.0, 90.0)
        }
      } else {
        switch hotspot.viewFrame {
        | Some(vf) => (vf.yaw, vf.pitch, vf.hfov)
        | None =>
          switch hotspot.targetYaw {
          | Some(y) => (
              y,
              switch hotspot.targetPitch {
              | Some(p) => p
              | None => 0.0
              },
              switch hotspot.targetHfov {
              | Some(h) => h
              | None => 90.0
              },
            )
          | None => (0.0, 0.0, 90.0)
          }
        }
      }

      // Check for Completion (Returned to start and no new paths)
      let isComplete = if targetIndex == 0 {
        switch Belt.Array.get(state.scenes, 0) {
        | Some(startScene) =>
          let hasNewPaths = Belt.Array.some(startScene.hotspots, h => {
            let tIdx = Belt.Array.getIndexBy(state.scenes, s => s.name == h.target)
            switch tIdx {
            | Some(i) => !Js.Array.includes(i, visitedScenes)
            | None => false
            }
          })
          !hasNewPaths
        | None => false
        }
      } else {
        false
      }

      if isComplete {
        Complete({reason: "returned_to_start"})
      } else {
        // Prepare side actions
        let actions = []

        // Add visited scenes for chain skipping
        extraVisited->Belt.Array.forEach(idx => {
          let _ = Js.Array.push(AddVisitedScene(idx), actions)
        })

        // Sync Timeline (if applicable)
        let timelineItem = Js.Array.find(
          item => item.sceneId == currentScene.id && item.linkId == hotspot.linkId,
          state.timeline,
        )
        switch timelineItem {
        | Some(item) =>
          let _ = Js.Array.push(SetActiveTimelineStep(Some(item.id)), actions)
        | None =>
          let _ = Js.Array.push(SetActiveTimelineStep(None), actions)
        }

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
