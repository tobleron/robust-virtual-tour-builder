open Types

let getActiveScenes = (inventory, sceneOrder) => {
  sceneOrder->Belt.Array.keepMap(id => {
    switch inventory->Belt.Map.String.get(id) {
    | Some({scene, status: Active}) => Some(scene)
    | _ => None
    }
  })
}

let getDeletedIds = inventory => {
  inventory
  ->Belt.Map.String.toArray
  ->Belt.Array.keepMap(((id, entry)) => {
    switch entry.status {
    | Deleted(_) => Some(id)
    | Active => None
    }
  })
}



let syncInventoryNames = (inventory, sceneOrder) => {
  let renameMap = Belt.MutableMap.String.make()
  let updatedRef = ref(inventory)

  sceneOrder->Belt.Array.forEachWithIndex((index, id) => {
    switch inventory->Belt.Map.String.get(id) {
    | Some({scene, status: Active} as entry) =>
      if scene.label != "" {
        let oldName = scene.name
        let baseName = TourLogic.getBaseNameFromId(scene.id)
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

let rebuildLegacyFields = (state: state): state => {
  {
    ...state,
    scenes: getActiveScenes(state.inventory, state.sceneOrder),
    deletedSceneIds: getDeletedIds(state.inventory),
  }
}

let calculateActiveIndexAfterDelete = (
  currentIndex: int,
  deletedIndex: int,
  newOrderLength: int,
): int => {
  if newOrderLength == 0 {
    -1
  } else if deletedIndex == currentIndex {
    if deletedIndex < newOrderLength {
      deletedIndex
    } else {
      newOrderLength - 1
    }
  } else if deletedIndex < currentIndex {
    currentIndex - 1
  } else {
    currentIndex
  }
}

let handleDeleteScene = (state: state, index: int): state => {
  switch state.appMode {
  | Interactive(_) =>
    switch Belt.Array.get(state.sceneOrder, index) {
    | Some(idToDelete) =>
      switch state.inventory->Belt.Map.String.get(idToDelete) {
      | Some(entry) =>
        let targetName = entry.scene.name

        // 1. Mark as deleted in inventory
        let updatedInventory =
          state.inventory->Belt.Map.String.set(idToDelete, {...entry, status: Deleted(Date.now())})

        // 2. Remove ID from sceneOrder
        let updatedOrder = state.sceneOrder->Belt.Array.keep(id => id != idToDelete)

        // 3. Remove hotspots pointing to deleted scene in ALL active scenes
        let inventoryWithCleanHotspots = updatedInventory->Belt.Map.String.map(e => {
          let s = e.scene
          let newHotspots = s.hotspots->Belt.Array.keep(h => h.target != targetName)
          {...e, scene: {...s, hotspots: newHotspots}}
        })

        // 4. Adjust activeIndex
        let newLen = Belt.Array.length(updatedOrder)
        let newActiveIndex = calculateActiveIndexAfterDelete(state.activeIndex, index, newLen)

        // 5. Sync names & Rebuild legacy
        let finalizedInventory = syncInventoryNames(inventoryWithCleanHotspots, updatedOrder)
        {
          ...state,
          inventory: finalizedInventory,
          sceneOrder: updatedOrder,
          activeIndex: newActiveIndex,
          activeYaw: newActiveIndex == -1 ? 0.0 : state.activeYaw,
          activePitch: newActiveIndex == -1 ? 0.0 : state.activePitch,
          linkDraft: None,
          deletedSceneIds: state.deletedSceneIds->Array.concat([idToDelete]),
        }->rebuildLegacyFields

      | None => state
      }
    | None => state
    }
  | _ => state
  }
}

let handleReorderScenes = (state: state, fromIndex: int, toIndex: int): state => {
  switch state.appMode {
  | Interactive(_) =>
    if fromIndex != toIndex {
      switch Belt.Array.get(state.sceneOrder, fromIndex) {
      | Some(movedId) =>
        let rest = state.sceneOrder->Belt.Array.keepWithIndex((_, i) => i != fromIndex)
        let updatedOrder = UiHelpers.insertAt(rest, toIndex, movedId)

        let newActiveIndex = if state.activeIndex == fromIndex {
          toIndex
        } else if state.activeIndex > fromIndex && state.activeIndex <= toIndex {
          state.activeIndex - 1
        } else if state.activeIndex < fromIndex && state.activeIndex >= toIndex {
          state.activeIndex + 1
        } else {
          state.activeIndex
        }

        let finalizedInventory = syncInventoryNames(state.inventory, updatedOrder)
        {
          ...state,
          inventory: finalizedInventory,
          sceneOrder: updatedOrder,
          activeIndex: newActiveIndex,
        }->rebuildLegacyFields
      | None => state
      }
    } else {
      state
    }
  | _ => state
  }
}

let updateSceneCategories = (
  inventory: Belt.Map.String.t<sceneEntry>,
  sceneOrder: array<string>,
  targetIndex: int,
  lastUsedCategory: string,
): Belt.Map.String.t<sceneEntry> => {
  switch Belt.Array.get(sceneOrder, targetIndex) {
  | Some(id) =>
    switch inventory->Belt.Map.String.get(id) {
    | Some({scene} as entry) if !scene.categorySet =>
      inventory->Belt.Map.String.set(id, {...entry, scene: {...scene, category: lastUsedCategory}})
    | _ => inventory
    }
  | None => inventory
  }
}

let handleAddScenes = (state: state, scenesData: array<JSON.t>): state => {
  let modeStr = state.appMode->(
    mode =>
      switch mode {
      | Interactive(_) => "Interactive"
      | SystemBlocking(Uploading(_)) => "Uploading"
      | SystemBlocking(ProjectLoading(_)) => "ProjectLoading"
      | SystemBlocking(Exporting(_)) => "Exporting"
      | SystemBlocking(Summary(_)) => "Summary"
      | SystemBlocking(CriticalError(_)) => "CriticalError"
      | Initializing => "Initializing"
      }
  )
  Logger.info(
    ~module_="SceneMutations",
    ~message="ADD_SCENES_CALLED count=" ++
    Belt.Int.toString(Belt.Array.length(scenesData)) ++
    " appMode=" ++
    modeStr,
    (),
  )
  switch state.appMode {
  | Interactive(_)
  | SystemBlocking(Uploading(_))
  | Initializing =>
    let wasEmpty = Belt.Map.String.isEmpty(state.inventory)

    // 1. Parse and add to inventory
    Logger.info(
      ~module_="SceneMutations",
      ~message="ADD_SCENES_START",
      ~data=Some({"count": Belt.Array.length(scenesData)}),
      (),
    )
    let (updatedInventory, addedIds) = scenesData->Belt.Array.reduce((state.inventory, []), (
      (inv, ids),
      dataJson,
    ) => {
      let newScene = SceneHelpers.parseScene(dataJson)
      if inv->Belt.Map.String.has(newScene.id) {
        (inv, ids)
      } else {
        (
          inv->Belt.Map.String.set(newScene.id, {scene: newScene, status: Active}),
          Belt.Array.concat(ids, [newScene.id]),
        )
      }
    })
    Logger.info(
      ~module_="SceneMutations",
      ~message="ADD_SCENES_DONE",
      ~data=Some({"added": Belt.Array.length(addedIds)}),
      (),
    )

    // 2. Update order (sort current + new)
    let mergedOrder = Belt.Array.concat(state.sceneOrder, addedIds)
    let sortedOrder = Array.copy(mergedOrder)
    Array.sort(sortedOrder, (a, b) => {
      let nameA = switch updatedInventory->Belt.Map.String.get(a) {
      | Some(e) => e.scene.name
      | None => ""
      }
      let nameB = switch updatedInventory->Belt.Map.String.get(b) {
      | Some(e) => e.scene.name
      | None => ""
      }
      String.localeCompare(nameA, nameB)
    })

    // 3. Sync names
    let finalizedInventory = syncInventoryNames(updatedInventory, sortedOrder)

    // 4. Adjust activeIndex
    let activeIndex = if (
      (wasEmpty ||
      state.activeIndex == -1 ||
      state.activeIndex >= Belt.Array.length(sortedOrder)) && Belt.Array.length(sortedOrder) > 0
    ) {
      0
    } else {
      state.activeIndex
    }

    let nextState = {
      ...state,
      inventory: finalizedInventory,
      sceneOrder: sortedOrder,
      activeIndex,
    }

    if wasEmpty && activeIndex == 0 {
      {...nextState, activeYaw: 0.0, activePitch: 0.0}
    } else {
      nextState
    }->rebuildLegacyFields

  | _ => state
  }
}

let handleUpdateSceneMetadata = (state: state, index: int, metaJson: JSON.t): state => {
  switch state.appMode {
  | Interactive(_) =>
    switch Belt.Array.get(state.sceneOrder, index) {
    | Some(targetId) =>
      switch state.inventory->Belt.Map.String.get(targetId) {
      | Some({scene} as entry) =>
        let meta = switch JsonCombinators.Json.decode(metaJson, JsonParsers.Domain.updateMetadata) {
        | Ok(m) => m
        | Error(_) => {
            category: None,
            floor: None,
            label: None,
            isAutoForward: None,
          }
        }

        let newCategory = switch meta.category {
        | Some(c) => c
        | None => scene.category
        }
        let newFloor = switch meta.floor {
        | Some(f) => f
        | None => scene.floor
        }
        let newLabel = switch meta.label {
        | Some(l) => l
        | None => scene.label
        }
        let newIsAutoForward = switch meta.isAutoForward {
        | Some(af) => af
        | None => scene.isAutoForward
        }
        let categorySet = switch meta.category {
        | Some(_) => true
        | None => scene.categorySet
        }

        let updatedScene = {
          ...scene,
          category: newCategory,
          floor: newFloor,
          label: newLabel,
          isAutoForward: newIsAutoForward,
          categorySet,
        }

        {
          ...state,
          inventory: state.inventory->Belt.Map.String.set(
            targetId,
            {...entry, scene: updatedScene},
          ),
          lastUsedCategory: switch meta.category {
          | Some(c) => c
          | None => state.lastUsedCategory
          },
        }->rebuildLegacyFields

      | None => state
      }
    | None => state
    }
  | _ => state
  }
}

let calculateTransition = (transition: option<transition>): transition => {
  switch transition {
  | Some(t) => t
  | None => {type_: Fade, targetHotspotIndex: -1, fromSceneName: None}
  }
}

let handleSetActiveScene = (
  state: state,
  index: int,
  yaw: float,
  pitch: float,
  transition: option<transition>,
): state => {
  if index >= 0 && index < Belt.Array.length(state.sceneOrder) {
    let newTransition = calculateTransition(transition)
    let updatedInventory = updateSceneCategories(
      state.inventory,
      state.sceneOrder,
      index,
      state.lastUsedCategory,
    )

    {
      ...state,
      inventory: updatedInventory,
      activeIndex: index,
      activeYaw: yaw,
      activePitch: pitch,
      transition: newTransition,
    }->rebuildLegacyFields
  } else {
    state
  }
}

let handleApplyLazyRename = (state: state, index: int, name: string): state => {
  switch Belt.Array.get(state.sceneOrder, index) {
  | Some(id) =>
    switch state.inventory->Belt.Map.String.get(id) {
    | Some({scene} as entry) =>
      let updatedInventory =
        state.inventory->Belt.Map.String.set(id, {...entry, scene: {...scene, label: name}})
      let finalizedInventory = syncInventoryNames(updatedInventory, state.sceneOrder)
      {...state, inventory: finalizedInventory}->rebuildLegacyFields
    | None => state
    }
  | None => state
  }
}

let syncSceneNames = (scenes: array<Types.scene>) => {
  // LEGACY: Keeping to avoid breaking tests that depend on it
  let renameMap = Belt.MutableMap.String.make()
  let updatedScenes = Belt.Array.mapWithIndex(scenes, (index, scene) => {
    if scene.label != "" {
      let oldName = scene.name
      let baseName = TourLogic.getBaseNameFromId(scene.id)
      let newName = TourLogic.computeSceneFilename(index, scene.label, baseName)
      if newName != oldName {
        let _ = Belt.MutableMap.String.set(renameMap, oldName, newName)
        {...scene, name: newName}
      } else {
        scene
      }
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
