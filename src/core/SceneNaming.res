open Types

let syncInventoryNames = (inventory, sceneOrder) => {
  let renameMap = Belt.MutableMap.String.make()
  let updatedRef = ref(inventory)

  sceneOrder->Belt.Array.forEachWithIndex((index, id) => {
    switch inventory->Belt.Map.String.get(id) {
    | Some({scene, status: Active} as entry) =>
      if scene.label != "" {
        let oldName = scene.name
        let baseName = TourLogic.recoverBaseName(scene.name, scene.label)
        let newName = TourLogic.computeSceneFilename(index, scene.label, baseName)
        if newName != oldName {
          let _ = Belt.MutableMap.String.set(renameMap, oldName, newName)
          updatedRef.contents =
            updatedRef.contents->Belt.Map.String.set(
              id,
              {...entry, scene: {...scene, name: newName}},
            )
        }
      }
    | _ => ()
    }
  })

  let inventoryWithRenames = if Belt.MutableMap.String.size(renameMap) > 0 {
    updatedRef.contents->Belt.Map.String.map(entry => {
      let s = entry.scene
      let updatedHotspots = s.hotspots->Belt.Array.map(h => {
        switch renameMap->Belt.MutableMap.String.get(h.target) {
        | Some(newName) => {...h, target: newName}
        | None => h
        }
      })
      {...entry, scene: {...s, hotspots: updatedHotspots}}
    })
  } else {
    updatedRef.contents
  }
  inventoryWithRenames
}

let syncSceneNames = (scenes: array<Types.scene>) => {
  let renameMap = Belt.MutableMap.String.make()
  let updatedScenes = Belt.Array.mapWithIndex(scenes, (index, scene) => {
    let oldName = scene.name
    let newName = TourLogic.computeSceneFilename(index, scene.label, "")
    if newName != oldName {
      let _ = Belt.MutableMap.String.set(renameMap, oldName, newName)
      {...scene, name: newName}
    } else {
      scene
    }
  })

  if Belt.MutableMap.String.size(renameMap) > 0 {
    Belt.Array.map(updatedScenes, s => {
      let updatedHotspots = Belt.Array.map(s.hotspots, h => {
        switch Belt.MutableMap.String.get(renameMap, h.target) {
        | Some(newName) => {...h, target: newName}
        | None => h
        }
      })
      {...s, hotspots: updatedHotspots}
    })
  } else {
    updatedScenes
  }
}
