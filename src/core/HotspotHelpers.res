open Types

let calculateNewReturnViewFrame = (hotspot: hotspot, isReturnLink: bool): option<viewFrame> => {
  if isReturnLink && hotspot.returnViewFrame == None {
    let vf = switch hotspot.viewFrame {
    | Some(v) => v
    | None => {yaw: 0.0, pitch: 0.0, hfov: 90.0}
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
  let newScenes = Belt.Array.mapWithIndex(state.scenes, (i, s) => {
    if i == sceneIndex {
      {...s, hotspots: Belt.Array.concat(s.hotspots, [hotspot])}
    } else {
      s
    }
  })
  {...state, scenes: newScenes}
}

let handleRemoveHotspot = (state: state, sceneIndex: int, hotspotIndex: int): state => {
  let scenes = state.scenes
  switch Belt.Array.get(scenes, sceneIndex) {
  | Some(sourceScene) =>
    switch Belt.Array.get(sourceScene.hotspots, hotspotIndex) {
    | Some(hotspotToDelete) =>
      let targetName = hotspotToDelete.target

      // 1. Remove the hotspot
      let newSourceHotspots = Belt.Array.keepWithIndex(sourceScene.hotspots, (_, i) =>
        i != hotspotIndex
      )
      let scenesWithRemovedHotspot = Belt.Array.mapWithIndex(scenes, (i, s) => {
        if i == sceneIndex {
          {...s, hotspots: newSourceHotspots}
        } else {
          s
        }
      })

      // 2. Check if anything else still points to targetName
      let stillReferenced = Belt.Array.some(scenesWithRemovedHotspot, s => {
        Belt.Array.some(s.hotspots, h => h.target == targetName)
      })

      // 3. If no longer referenced, reset target scene's isAutoForward
      let finalScenes = if !stillReferenced {
        Belt.Array.map(scenesWithRemovedHotspot, s => {
          if s.name == targetName {
            {...s, isAutoForward: false}
          } else {
            s
          }
        })
      } else {
        scenesWithRemovedHotspot
      }

      {...state, scenes: finalScenes}
    | None => state
    }
  | None => state
  }
}

let handleClearHotspots = (state: state, sceneIndex: int): state => {
  let newScenes = Belt.Array.mapWithIndex(state.scenes, (i, s) => {
    if i == sceneIndex {
      {...s, hotspots: []}
    } else {
      s
    }
  })
  {...state, scenes: newScenes}
}

let handleUpdateHotspotTargetView = (
  state: state,
  sceneIndex: int,
  hotspotIndex: int,
  yaw: float,
  pitch: float,
  hfov: float,
): state => {
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
  {...state, scenes: newScenes}
}

let handleUpdateHotspotReturnView = (
  state: state,
  sceneIndex: int,
  hotspotIndex: int,
  yaw: float,
  pitch: float,
  hfov: float,
): state => {
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
  {...state, scenes: newScenes}
}

let handleToggleHotspotReturnLink = (state: state, sceneIndex: int, hotspotIndex: int): state => {
  let newScenes = Belt.Array.mapWithIndex(state.scenes, (i, s) => {
    if i == sceneIndex {
      let newHotspots = Belt.Array.mapWithIndex(s.hotspots, (hi, h) => {
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
      {...s, hotspots: newHotspots}
    } else {
      s
    }
  })
  {...state, scenes: newScenes}
}
