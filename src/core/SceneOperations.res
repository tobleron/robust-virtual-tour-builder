open Types

let handleDeleteScene = (state: state, index: int): state => {
  switch state.appMode {
  | Interactive(_) =>
    switch Belt.Array.get(state.sceneOrder, index) {
    | Some(idToDelete) =>
      switch state.inventory->Belt.Map.String.get(idToDelete) {
      | Some(entry) =>
        let sceneToDelete = entry.scene

        // 1. Mark as deleted in inventory
        let updatedInventory =
          state.inventory->Belt.Map.String.set(idToDelete, {...entry, status: Deleted(Date.now())})

        // 2. Remove ID from sceneOrder
        let updatedOrder = state.sceneOrder->Belt.Array.keep(id => id != idToDelete)

        // 3. Remove hotspots pointing to deleted scene in ALL active scenes
        let inventoryWithCleanHotspots = updatedInventory->Belt.Map.String.map(e => {
          let s = e.scene
          let newHotspots =
            s.hotspots->Belt.Array.keep(h => !HotspotTarget.pointsToScene(h, sceneToDelete))
          {...e, scene: {...s, hotspots: newHotspots}}
        })

        // 4. Remove timeline items for the deleted scene (prevents orphaned entries)
        let filteredTimeline = Belt.Array.keep(state.timeline, t => t.sceneId != idToDelete)
        
        // 5. Clear active timeline step if it was removed
        let activeTimelineStepId = switch state.activeTimelineStepId {
        | Some(stepId) =>
          let stillExists = filteredTimeline->Belt.Array.some(t => t.id == stepId)
          stillExists ? Some(stepId) : None
        | None => None
        }

        // 6. Adjust activeIndex
        let newLen = Belt.Array.length(updatedOrder)
        let newActiveIndex = SceneInventory.calculateActiveIndexAfterDelete(
          state.activeIndex,
          index,
          newLen,
        )

        // 7. Sync names & Rebuild legacy
        let finalizedInventory = SceneNaming.syncInventoryNames(
          inventoryWithCleanHotspots,
          updatedOrder,
        )
        {
          ...state,
          inventory: finalizedInventory,
          sceneOrder: updatedOrder,
          activeIndex: newActiveIndex,
          activeYaw: newActiveIndex == -1 ? 0.0 : state.activeYaw,
          activePitch: newActiveIndex == -1 ? 0.0 : state.activePitch,
          isLinking: false,
          timeline: filteredTimeline,
          activeTimelineStepId,
        }

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

        let finalizedInventory = SceneNaming.syncInventoryNames(state.inventory, updatedOrder)
        {
          ...state,
          inventory: finalizedInventory,
          sceneOrder: updatedOrder,
          activeIndex: newActiveIndex,
          linkDraft: None,
        }
      | None => state
      }
    } else {
      state
    }
  | _ => state
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
    ~module_="SceneOperations",
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
    let nextSceneSeq = ref(state.nextSceneSequenceId)

    // 1. Parse and add to inventory
    Logger.info(
      ~module_="SceneOperations",
      ~message="ADD_SCENES_START",
      ~data=Some({"count": Belt.Array.length(scenesData)}),
      (),
    )
    let (updatedInventory, addedIds) = scenesData->Belt.Array.reduce((state.inventory, []), (
      (inv, ids),
      dataJson,
    ) => {
      let newScene = SceneHelpers.parseScene(dataJson)
      let finalSeq =
        if newScene.sequenceId > 0 {
          newScene.sequenceId
        } else {
          let seq = nextSceneSeq.contents
          nextSceneSeq.contents = seq + 1
          seq
        }
      if finalSeq >= nextSceneSeq.contents {
        nextSceneSeq.contents = finalSeq + 1
      }
      let sequencedScene = {...newScene, sequenceId: finalSeq}
      if inv->Belt.Map.String.has(sequencedScene.id) {
        (inv, ids)
      } else {
        (
          inv->Belt.Map.String.set(sequencedScene.id, {scene: sequencedScene, status: Active}),
          Belt.Array.concat(ids, [sequencedScene.id]),
        )
      }
    })
    Logger.info(
      ~module_="SceneOperations",
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
    let finalizedInventory = SceneNaming.syncInventoryNames(updatedInventory, sortedOrder)

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
      nextSceneSequenceId: nextSceneSeq.contents,
      isLinking: false,
      linkDraft: None,
    }

    if wasEmpty && activeIndex == 0 {
      {...nextState, activeYaw: 0.0, activePitch: 0.0}
    } else {
      nextState
    }

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

        // Check for manual baseName override in metadata (from LabelMenu)
        let manualBaseName = switch JSON.Decode.object(metaJson) {
        | Some(obj) =>
          switch Dict.get(obj, "_baseName") {
          | Some(v) => JSON.Decode.string(v)
          | None => None
          }
        | None => None
        }

        let updatedScene = {
          ...scene,
          category: newCategory,
          floor: newFloor,
          label: newLabel,
          isAutoForward: newIsAutoForward,
          categorySet,
        }

        // Check if we need to update filename based on manual base name preservation
        let finalScene = switch manualBaseName {
        | Some(base) if base != "" =>
          let newName = TourLogic.computeSceneFilename(scene.sequenceId, newLabel, base)
          {...updatedScene, name: newName}
        | _ => updatedScene
        }

        let updatedInventory =
          state.inventory->Belt.Map.String.set(targetId, {...entry, scene: finalScene})

        // Sync everything to handle dependencies
        let finalizedInventory = SceneNaming.syncInventoryNames(updatedInventory, state.sceneOrder)

        {
          ...state,
          inventory: finalizedInventory,
          lastUsedCategory: switch meta.category {
          | Some(c) => c
          | None => state.lastUsedCategory
          },
        }

      | None => state
      }
    | None => state
    }
  | _ => state
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
    let newTransition = SceneInventory.calculateTransition(transition)
    let updatedInventory = SceneInventory.updateSceneCategories(
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
      isLinking: false,
      linkDraft: None,
    }
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
      let finalizedInventory = SceneNaming.syncInventoryNames(updatedInventory, state.sceneOrder)
      {...state, inventory: finalizedInventory}
    | None => state
    }
  | None => state
  }
}

let handlePatchSceneThumbnail = (state: state, id: string, file: file): state => {
  switch state.inventory->Belt.Map.String.get(id) {
  | Some(entry) =>
    let updatedScene = {...entry.scene, tinyFile: Some(file)}
    let updatedInventory = state.inventory->Belt.Map.String.set(id, {...entry, scene: updatedScene})
    // Invalidate caches so UI detects the change
    SceneCache.clearThumbUrl(id)
    SceneCache.clearThumbUrl(id ++ "_tiny")
    {...state, inventory: updatedInventory}
  | None => state
  }
}
