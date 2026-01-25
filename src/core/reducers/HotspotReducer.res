open Types
open Actions

let reduce = (state: state, action: action): option<state> => {
  switch action {
  | AddHotspot(sceneIndex, hotspot) =>
    let newScenes = Belt.Array.mapWithIndex(state.scenes, (i, s) => {
      if i == sceneIndex {
        {...s, hotspots: Belt.Array.concat(s.hotspots, [hotspot])}
      } else {
        s
      }
    })
    Some({...state, scenes: newScenes})

  | RemoveHotspot(sceneIndex, hotspotIndex) =>
    Some(SceneHelpers.handleRemoveHotspot(state, sceneIndex, hotspotIndex))

  | ClearHotspots(index) =>
    let newScenes = Belt.Array.mapWithIndex(state.scenes, (i, s) => {
      if i == index {
        {...s, hotspots: []}
      } else {
        s
      }
    })
    Some({...state, scenes: newScenes})

  | UpdateHotspotTargetView(sceneIndex, hotspotIndex, yaw, pitch, hfov) =>
    let newScenes = Belt.Array.mapWithIndex(state.scenes, (i, s) => {
      if i == sceneIndex {
        let newHotspots = Belt.Array.mapWithIndex(s.hotspots, (hi, h) => {
          if hi == hotspotIndex {
            {...h, targetYaw: Some(yaw), targetPitch: Some(pitch), targetHfov: Some(hfov)}
          } else {
            h
          }
        })
        {...s, hotspots: newHotspots}
      } else {
        s
      }
    })
    Some({...state, scenes: newScenes})

  | UpdateHotspotReturnView(sceneIndex, hotspotIndex, yaw, pitch, hfov) =>
    let newScenes = Belt.Array.mapWithIndex(state.scenes, (i, s) => {
      if i == sceneIndex {
        let newHotspots = Belt.Array.mapWithIndex(s.hotspots, (hi, h) => {
          if hi == hotspotIndex {
            let vf: viewFrame = {yaw, pitch, hfov}
            {...h, returnViewFrame: Some(vf), isReturnLink: Some(true)}
          } else {
            h
          }
        })
        {...s, hotspots: newHotspots}
      } else {
        s
      }
    })
    Some({...state, scenes: newScenes})

  | ToggleHotspotReturnLink(sceneIndex, hotspotIndex) =>
    let newScenes = Belt.Array.mapWithIndex(state.scenes, (i, s) => {
      if i == sceneIndex {
        let newHotspots = Belt.Array.mapWithIndex(s.hotspots, (hi, h) => {
          if hi == hotspotIndex {
            let currentVal = switch h.isReturnLink {
            | Some(b) => b
            | None => false
            }
            let nextVal = !currentVal
            let newReturnViewFrame = if nextVal && h.returnViewFrame == None {
              let vf = switch h.viewFrame {
              | Some(v) => v
              | None => {yaw: 0.0, pitch: 0.0, hfov: 90.0}
              }
              Some({
                yaw: vf.yaw,
                pitch: vf.pitch,
                hfov: vf.hfov,
              })
            } else {
              h.returnViewFrame
            }
            {...h, isReturnLink: Some(nextVal), returnViewFrame: newReturnViewFrame}
          } else {
            h
          }
        })
        {...s, hotspots: newHotspots}
      } else {
        s
      }
    })
    Some({...state, scenes: newScenes})

  | _ => None
  }
}
