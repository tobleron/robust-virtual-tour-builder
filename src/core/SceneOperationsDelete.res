// @efficiency-role: domain-logic

open Types

let retainActiveTimelineStepId = (
  activeTimelineStepId: option<string>,
  filteredTimeline: array<timelineItem>,
): option<string> => {
  switch activeTimelineStepId {
  | Some(stepId) =>
    let stillExists = filteredTimeline->Belt.Array.some(t => t.id == stepId)
    stillExists ? Some(stepId) : None
  | None => None
  }
}

let handleDeleteScene = (state: state, index: int): state => {
  switch state.appMode {
  | Interactive(_) =>
    switch Belt.Array.get(state.sceneOrder, index) {
    | Some(idToDelete) =>
      switch state.inventory->Belt.Map.String.get(idToDelete) {
      | Some(entry) =>
        let sceneToDelete = entry.scene
        let updatedInventory =
          state.inventory->Belt.Map.String.set(idToDelete, {...entry, status: Deleted(Date.now())})
        let updatedOrder = state.sceneOrder->Belt.Array.keep(id => id != idToDelete)
        let inventoryWithCleanHotspots = updatedInventory->Belt.Map.String.map(sceneEntry => {
          let scene = sceneEntry.scene
          let newHotspots =
            scene.hotspots->Belt.Array.keep(hotspot => !HotspotTarget.pointsToScene(hotspot, sceneToDelete))
          {...sceneEntry, scene: {...scene, hotspots: newHotspots}}
        })
        let filteredTimeline = Belt.Array.keep(state.timeline, timelineItem => timelineItem.sceneId != idToDelete)
        let activeTimelineStepId = retainActiveTimelineStepId(
          state.activeTimelineStepId,
          filteredTimeline,
        )
        let newLen = Belt.Array.length(updatedOrder)
        let newActiveIndex = SceneInventory.calculateActiveIndexAfterDelete(
          state.activeIndex,
          index,
          newLen,
        )
        let finalizedInventory = SceneNaming.syncInventoryNames(
          inventoryWithCleanHotspots,
          updatedOrder,
        )

        let nextMovingHotspot = switch state.movingHotspot {
        | None => None
        | Some(movingHotspot) =>
          if movingHotspot.sceneIndex == index {
            None
          } else {
            let shiftedSceneIndex = if movingHotspot.sceneIndex > index {
              movingHotspot.sceneIndex - 1
            } else {
              movingHotspot.sceneIndex
            }

            switch Belt.Array.get(updatedOrder, shiftedSceneIndex) {
            | None => None
            | Some(sceneId) =>
              switch finalizedInventory->Belt.Map.String.get(sceneId) {
              | Some(sceneEntry) =>
                switch movingHotspot.hotspotLinkId {
                | Some(linkId) =>
                  switch sceneEntry.scene.hotspots->Belt.Array.getIndexBy(hotspot => hotspot.linkId == linkId) {
                  | Some(nextHotspotIndex) =>
                    Some({
                      ...movingHotspot,
                      sceneIndex: shiftedSceneIndex,
                      hotspotIndex: nextHotspotIndex,
                      sceneId: Some(sceneId),
                    })
                  | None => None
                  }
                | None =>
                  if movingHotspot.hotspotIndex < Belt.Array.length(sceneEntry.scene.hotspots) {
                    Some({
                      ...movingHotspot,
                      sceneIndex: shiftedSceneIndex,
                      sceneId: Some(sceneId),
                    })
                  } else {
                    None
                  }
                }
              | None => None
              }
            }
          }
        }

        let nextState = {
          ...state,
          inventory: finalizedInventory,
          sceneOrder: updatedOrder,
          activeIndex: newActiveIndex,
          activeYaw: newActiveIndex == -1 ? 0.0 : state.activeYaw,
          activePitch: newActiveIndex == -1 ? 0.0 : state.activePitch,
          isLinking: false,
          linkDraft: None,
          movingHotspot: nextMovingHotspot,
          timeline: filteredTimeline,
          activeTimelineStepId,
        }

        let (cleanedState, _) = TimelineCleanup.applyCleanup(nextState)
        cleanedState
      | None => state
      }
    | None => state
    }
  | _ => state
  }
}
