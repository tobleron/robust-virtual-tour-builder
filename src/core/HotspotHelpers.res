open Types

let handleAddHotspot = (state: state, sceneIndex: int, hotspot: hotspot): state => {
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

let handleRemoveHotspot = (state: state, sceneIndex: int, hotspotIndex: int): state => {
  switch state.appMode {
  | Interactive(_) =>
    switch Belt.Array.get(state.sceneOrder, sceneIndex) {
    | Some(id) =>
      switch state.inventory->Belt.Map.String.get(id) {
      | Some(entry) =>
        let sourceScene = entry.scene
        switch Belt.Array.get(sourceScene.hotspots, hotspotIndex) {
        | Some(hotspotToDelete) =>
          // 1. Extract the linkId to clean up timeline
          let linkIdToRemove = hotspotToDelete.linkId

          // 2. Remove the hotspot from the scene
          let newSourceHotspots = Belt.Array.keepWithIndex(sourceScene.hotspots, (_, i) =>
            i != hotspotIndex
          )

          // 3. Remove all timeline items with this linkId (prevents duplicate entries)
          let filteredTimeline = Belt.Array.keep(state.timeline, t => t.linkId != linkIdToRemove)

          // 4. Clear active timeline step if it was removed
          let activeTimelineStepId = switch state.activeTimelineStepId {
          | Some(stepId) =>
            let stillExists = filteredTimeline->Belt.Array.some(t => t.id == stepId)
            stillExists ? Some(stepId) : None
          | None => None
          }

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

let handleClearHotspots = (state: state, sceneIndex: int): state => {
  switch state.appMode {
  | Interactive(_) =>
    switch Belt.Array.get(state.sceneOrder, sceneIndex) {
    | Some(id) =>
      switch state.inventory->Belt.Map.String.get(id) {
      | Some(entry) =>
        let filteredTimeline = Belt.Array.keep(state.timeline, t => t.sceneId != id)
        let activeTimelineStepId = switch state.activeTimelineStepId {
        | Some(stepId) =>
          let stillExists = filteredTimeline->Belt.Array.some(t => t.id == stepId)
          stillExists ? Some(stepId) : None
        | None => None
        }
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

let handleUpdateHotspotTargetView = (
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
        let updatedHotspots = Belt.Array.mapWithIndex(entry.scene.hotspots, (hi, h) => {
          if hi == hotspotIndex {
            {...h, targetYaw: Some(yaw), targetPitch: Some(pitch), targetHfov: Some(hfov)}
          } else {
            h
          }
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

let handleUpdateHotspotMetadata = (
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
        let decoded = JsonCombinators.Json.decode(
          metadata,
          JsonParsers.Domain.updateHotspotMetadata,
        )
        let meta = switch decoded {
        | Ok(m) => m
        | Error(_) => {isAutoForward: None}
        }

        let updatedHotspots = Belt.Array.mapWithIndex(entry.scene.hotspots, (hi, h) => {
          if hi == hotspotIndex {
            {
              ...h,
              isAutoForward: switch meta.isAutoForward {
              | Some(af) => Some(af)
              | None => h.isAutoForward
              },
            }
          } else {
            h
          }
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

let handleStartMovingHotspot = (state: state, sceneIndex: int, hotspotIndex: int): state => {
  {...state, movingHotspot: Some({sceneIndex, hotspotIndex}), isLinking: false, linkDraft: None}
}

let handleStopMovingHotspot = (state: state): state => {
  {...state, movingHotspot: None}
}

let handleCommitHotspotMove = (
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
      let updatedHotspots = Belt.Array.mapWithIndex(entry.scene.hotspots, (hi, h) => {
        if hi == hotspotIndex {
          // Commit ONLY the button position change.
          // Preserve the waypoint (viewFrame and waypoints) exactly as it was.
          // Clear displayPitch to ensure the button renders at the exact clicked pitch (no floor snap).
          {...h, yaw, pitch, displayPitch: None}
        } else {
          h
        }
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

let canEnableAutoForward = (
  scenes: array<scene>,
  sceneIndex: int,
  hotspotIndex: int,
): bool => {
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

    // If this hotspot is already auto-forward, toggling is always allowed (disable path).
    if currentIsAutoForward {
      true
    } else {
      let hasAnotherAutoForward = Belt.Array.keepWithIndex(scene.hotspots, (h, idx) =>
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
