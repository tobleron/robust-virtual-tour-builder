open Types

let calculateNewReturnViewFrame = (hotspot: hotspot, isReturnLink: bool): option<viewFrame> => {
  if isReturnLink && hotspot.returnViewFrame == None {
    let vf = switch hotspot.viewFrame {
    | Some(v) => v
    | None => {yaw: 0.0, pitch: 0.0, hfov: Constants.globalHfov}
    }
    Some({
      yaw: vf.yaw,
      pitch: vf.pitch,
      hfov: vf.hfov,
    })
  } else {
    hotspot.returnViewFrame
  }
}

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
        | Some(_hotspotToDelete) =>
          // 1. Remove the hotspot
          let newSourceHotspots = Belt.Array.keepWithIndex(sourceScene.hotspots, (_, i) =>
            i != hotspotIndex
          )
          let updatedInventory =
            state.inventory->Belt.Map.String.set(
              id,
              {...entry, scene: {...sourceScene, hotspots: newSourceHotspots}},
            )

          {...state, inventory: updatedInventory}
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

let handleUpdateHotspotReturnView = (
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
            let vf: viewFrame = {yaw, pitch, hfov}
            {...h, returnViewFrame: Some(vf), isReturnLink: Some(true)}
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

let handleToggleHotspotReturnLink = (state: state, sceneIndex: int, hotspotIndex: int): state => {
  switch state.appMode {
  | Interactive(_) =>
    switch Belt.Array.get(state.sceneOrder, sceneIndex) {
    | Some(id) =>
      switch state.inventory->Belt.Map.String.get(id) {
      | Some(entry) =>
        let updatedHotspots = Belt.Array.mapWithIndex(entry.scene.hotspots, (hi, h) => {
          if hi == hotspotIndex {
            let currentVal = switch h.isReturnLink {
            | Some(b) => b
            | None => false
            }
            let nextVal = !currentVal
            let newReturnViewFrame = calculateNewReturnViewFrame(h, nextVal)
            {...h, isReturnLink: Some(nextVal), returnViewFrame: newReturnViewFrame}
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
