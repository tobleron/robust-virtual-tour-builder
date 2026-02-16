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
        }->SceneMutations.rebuildLegacyFields
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
          let targetSceneId = HotspotTarget.resolveSceneId(state.scenes, hotspotToDelete)

          // 1. Remove the hotspot
          let newSourceHotspots = Belt.Array.keepWithIndex(sourceScene.hotspots, (_, i) =>
            i != hotspotIndex
          )
          let updatedInventory =
            state.inventory->Belt.Map.String.set(
              id,
              {...entry, scene: {...sourceScene, hotspots: newSourceHotspots}},
            )

          // 2. Check if anything else still points to targetName
          let stillReferenced = updatedInventory->Belt.Map.String.some((_id, e) => {
            switch (e.status, targetSceneId) {
            | (Active, Some(tid)) =>
              Belt.Array.some(e.scene.hotspots, h =>
                HotspotTarget.resolveSceneId(state.scenes, h)
                ->Option.map(id => id == tid)
                ->Option.getOr(false)
              )
            | _ => false
            }
          })

          // 3. If no longer referenced, reset target scene's isAutoForward in inventory
          let finalInventory = if !stillReferenced {
            updatedInventory->Belt.Map.String.map(e => {
              switch targetSceneId {
              | Some(tid) if e.scene.id == tid => {...e, scene: {...e.scene, isAutoForward: false}}
              | _ => e
              }
            })
          } else {
            updatedInventory
          }

          {...state, inventory: finalInventory}->SceneMutations.rebuildLegacyFields
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
        {
          ...state,
          inventory: state.inventory->Belt.Map.String.set(
            id,
            {...entry, scene: {...entry.scene, hotspots: []}},
          ),
        }->SceneMutations.rebuildLegacyFields
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
        }->SceneMutations.rebuildLegacyFields
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
        }->SceneMutations.rebuildLegacyFields
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
        }->SceneMutations.rebuildLegacyFields
      | None => state
      }
    | None => state
    }
  | _ => state
  }
}
