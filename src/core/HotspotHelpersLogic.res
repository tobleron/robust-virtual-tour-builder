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

let updateHotspotAtIndex = (
  hotspots: array<hotspot>,
  hotspotIndex: int,
  updateHotspot: hotspot => hotspot,
) => {
  HotspotHelpersMetadata.updateHotspotAtIndex(hotspots, hotspotIndex, updateHotspot)
}

let withFallback = (nextValue: option<'a>, currentValue: 'a): 'a => {
  HotspotHelpersMetadata.withFallback(nextValue, currentValue)
}

let withOptionalFallback = (nextValue: option<'a>, currentValue: option<'a>): option<'a> => {
  HotspotHelpersMetadata.withOptionalFallback(nextValue, currentValue)
}

let emptyHotspotMetadata = (): JsonParsersDecoders.updateHotspotMetadata => {
  HotspotHelpersMetadata.emptyHotspotMetadata()
}

let decodeHotspotMetadata = (metadata: JSON.t): JsonParsersDecoders.updateHotspotMetadata => {
  HotspotHelpersMetadata.decodeHotspotMetadata(metadata)
}

let applyHotspotMetadata = (
  hotspot: hotspot,
  meta: JsonParsersDecoders.updateHotspotMetadata,
) => {
  HotspotHelpersMetadata.applyHotspotMetadata(hotspot, meta)
}

let handleAddHotspotState = (state: state, sceneIndex: int, hotspot: hotspot): state => {
  switch state.appMode {
  | Interactive(_) =>
    switch Belt.Array.get(state.sceneOrder, sceneIndex) {
    | Some(id) =>
      switch state.inventory->Belt.Map.String.get(id) {
      | Some(entry) =>
        let updatedScene = {
          ...entry.scene,
          hotspots: Belt.Array.concat(entry.scene.hotspots, [hotspot]),
        }
        {
          ...state,
          inventory: state.inventory->Belt.Map.String.set(id, {...entry, scene: updatedScene}),
        }
      | None => state
      }
    | None => state
    }
  | _ => state
  }
}

let handleRemoveHotspotState = (state: state, sceneIndex: int, hotspotIndex: int): state => {
  switch state.appMode {
  | Interactive(_) =>
    switch Belt.Array.get(state.sceneOrder, sceneIndex) {
    | Some(id) =>
      switch state.inventory->Belt.Map.String.get(id) {
      | Some(entry) =>
        let sourceScene = entry.scene
        switch Belt.Array.get(sourceScene.hotspots, hotspotIndex) {
        | Some(hotspotToDelete) =>
          let linkIdToRemove = hotspotToDelete.linkId
          let newSourceHotspots = Belt.Array.keepWithIndex(sourceScene.hotspots, (_, i) =>
            i != hotspotIndex
          )
          let filteredTimeline = Belt.Array.keep(state.timeline, t => t.linkId != linkIdToRemove)
          let activeTimelineStepId = retainActiveTimelineStepId(
            state.activeTimelineStepId,
            filteredTimeline,
          )

          let updatedInventory =
            state.inventory->Belt.Map.String.set(
              id,
              {...entry, scene: {...sourceScene, hotspots: newSourceHotspots}},
            )

          {...state, inventory: updatedInventory, timeline: filteredTimeline, activeTimelineStepId}
        | None => state
        }
      | None => state
      }
    | None => state
    }
  | _ => state
  }
}

let handleClearHotspotsState = (state: state, sceneIndex: int): state => {
  switch state.appMode {
  | Interactive(_) =>
    switch Belt.Array.get(state.sceneOrder, sceneIndex) {
    | Some(id) =>
      switch state.inventory->Belt.Map.String.get(id) {
      | Some(entry) =>
        let filteredTimeline = Belt.Array.keep(state.timeline, t => t.sceneId != id)
        let activeTimelineStepId = retainActiveTimelineStepId(
          state.activeTimelineStepId,
          filteredTimeline,
        )
        {
          ...state,
          timeline: filteredTimeline,
          activeTimelineStepId,
          inventory: state.inventory->Belt.Map.String.set(
            id,
            {...entry, scene: {...entry.scene, hotspots: []}},
          ),
        }
      | None => state
      }
    | None => state
    }
  | _ => state
  }
}

let handleUpdateHotspotTargetViewState = (
  state: state,
  sceneIndex: int,
  hotspotIndex: int,
  yaw: float,
  pitch: float,
  hfov: float,
): state => {
  switch state.appMode {
  | Interactive(_) =>
    switch Belt.Array.get(state.sceneOrder, sceneIndex) {
    | Some(id) =>
      switch state.inventory->Belt.Map.String.get(id) {
      | Some(entry) =>
        let updatedHotspots = updateHotspotAtIndex(entry.scene.hotspots, hotspotIndex, hotspot => {
          {...hotspot, targetYaw: Some(yaw), targetPitch: Some(pitch), targetHfov: Some(hfov)}
        })
        {
          ...state,
          inventory: state.inventory->Belt.Map.String.set(
            id,
            {...entry, scene: {...entry.scene, hotspots: updatedHotspots}},
          ),
        }
      | None => state
      }
    | None => state
    }
  | _ => state
  }
}

let handleUpdateHotspotMetadataState = (
  state: state,
  sceneIndex: int,
  hotspotIndex: int,
  metadata: JSON.t,
): state => {
  switch state.appMode {
  | Interactive(_) =>
    switch Belt.Array.get(state.sceneOrder, sceneIndex) {
    | Some(id) =>
      switch state.inventory->Belt.Map.String.get(id) {
      | Some(entry) =>
        let meta = decodeHotspotMetadata(metadata)
        let updatedHotspots = updateHotspotAtIndex(
          entry.scene.hotspots,
          hotspotIndex,
          hotspot => applyHotspotMetadata(hotspot, meta),
        )
        {
          ...state,
          inventory: state.inventory->Belt.Map.String.set(
            id,
            {...entry, scene: {...entry.scene, hotspots: updatedHotspots}},
          ),
        }
      | None => state
      }
    | None => state
    }
  | _ => state
  }
}

let lookupHotspotLinkId = (
  state: state,
  sceneId: option<string>,
  hotspotIndex: int,
): option<string> => {
  switch sceneId {
  | Some(sid) =>
    state.inventory
    ->Belt.Map.String.get(sid)
    ->Option.flatMap(entry => entry.scene.hotspots->Belt.Array.get(hotspotIndex))
    ->Option.map(h => h.linkId)
  | None => None
  }
}

let handleStartMovingHotspotState = (state: state, sceneIndex: int, hotspotIndex: int): state => {
  let sceneId = state.sceneOrder->Belt.Array.get(sceneIndex)
  let hotspotLinkId = lookupHotspotLinkId(state, sceneId, hotspotIndex)

  {
    ...state,
    movingHotspot: Some({sceneIndex, hotspotIndex, sceneId, hotspotLinkId}),
    isLinking: false,
    linkDraft: None,
  }
}

let handleCommitHotspotMoveState = (
  state: state,
  sceneIndex: int,
  hotspotIndex: int,
  yaw: float,
  pitch: float,
): state => {
  switch Belt.Array.get(state.sceneOrder, sceneIndex) {
  | Some(id) =>
    switch state.inventory->Belt.Map.String.get(id) {
    | Some(entry) =>
      let updatedHotspots = updateHotspotAtIndex(entry.scene.hotspots, hotspotIndex, hotspot => {
        {...hotspot, yaw, pitch, displayPitch: None}
      })
      {
        ...state,
        movingHotspot: None,
        inventory: state.inventory->Belt.Map.String.set(
          id,
          {...entry, scene: {...entry.scene, hotspots: updatedHotspots}},
        ),
      }
    | None => {...state, movingHotspot: None}
    }
  | None => {...state, movingHotspot: None}
  }
}

let canEnableAutoForwardState = (scenes: array<scene>, sceneIndex: int, hotspotIndex: int): bool => {
  switch Belt.Array.get(scenes, sceneIndex) {
  | None => true
  | Some(scene) =>
    let currentIsAutoForward = switch Belt.Array.get(scene.hotspots, hotspotIndex) {
    | Some(h) =>
      switch h.isAutoForward {
      | Some(true) => true
      | _ => false
      }
    | None => false
    }

    if currentIsAutoForward {
      true
    } else {
      let hasAnotherAutoForward =
        Belt.Array.keepWithIndex(scene.hotspots, (h, idx) =>
          idx != hotspotIndex &&
            switch h.isAutoForward {
            | Some(true) => true
            | _ => false
            }
        )->Belt.Array.length > 0
      !hasAnotherAutoForward
    }
  }
}
