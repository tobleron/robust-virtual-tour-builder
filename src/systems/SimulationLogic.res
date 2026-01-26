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
            | Some(i) => !Array.includes(visitedScenes, i)
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
        Logger.info(
          ~module_="Simulation",
          ~message="SIM_COMPLETED_AT_START",
          ~data=Some({"target": targetIndex}),
          (),
        )
        Complete({reason: "returned_to_start"})
      } else {
        // Prepare side actions
        let actions = []

        Logger.debug(
          ~module_="Simulation",
          ~message="SIM_MOVE_SELECTED",
          ~data=Some({"from": state.activeIndex, "to": targetIndex}),
          (),
        )

        // Add visited scenes for chain skipping
        extraVisited->Belt.Array.forEach(idx => {
          let _ = Array.push(actions, AddVisitedScene(idx))
        })

        // Sync Timeline (if applicable)
        let timelineItem = Array.find(state.timeline, item =>
          item.sceneId == currentScene.id && item.linkId == hotspot.linkId
        )
        switch timelineItem {
        | Some(item) =>
          let _ = Array.push(actions, SetActiveTimelineStep(Some(item.id)))
        | None =>
          let _ = Array.push(actions, SetActiveTimelineStep(None))
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

    | None =>
      Logger.warn(
        ~module_="Simulation",
        ~message="SIM_NO_MOVE_FOUND",
        ~data=Some({"activeIndex": state.activeIndex}),
        (),
      )
      Complete({reason: "no_reachable_scenes"})
    }
  | None =>
    Logger.error(
      ~module_="Simulation",
      ~message="SIM_INVALID_STATE",
      ~data=Some({"activeIndex": state.activeIndex}),
      (),
    )
    Complete({reason: "invalid_current_scene"})
  }
}
