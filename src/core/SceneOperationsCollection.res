// @efficiency-role: domain-logic

open Types

let handleReorderScenes = (state: state, fromIndex: int, toIndex: int): state => {
  switch state.appMode {
  | Interactive(_) =>
    if fromIndex != toIndex {
      switch Belt.Array.get(state.sceneOrder, fromIndex) {
      | Some(movedId) =>
        let rest = state.sceneOrder->Belt.Array.keepWithIndex((_, index) => index != fromIndex)
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

let appModeLabel = appMode => {
  switch appMode {
  | Interactive(_) => "Interactive"
  | SystemBlocking(Uploading(_)) => "Uploading"
  | SystemBlocking(ProjectLoading(_)) => "ProjectLoading"
  | SystemBlocking(Exporting(_)) => "Exporting"
  | SystemBlocking(Summary(_)) => "Summary"
  | SystemBlocking(CriticalError(_)) => "CriticalError"
  | Initializing => "Initializing"
  }
}

let handleAddScenes = (state: state, scenesData: array<JSON.t>): state => {
  Logger.info(
    ~module_="SceneOperations",
    ~message="ADD_SCENES_CALLED count=" ++
    Belt.Int.toString(Belt.Array.length(scenesData)) ++
    " appMode=" ++
    appModeLabel(state.appMode),
    (),
  )

  switch state.appMode {
  | Interactive(_)
  | SystemBlocking(Uploading(_))
  | Initializing =>
    let wasEmpty = Belt.Map.String.isEmpty(state.inventory)
    let nextSceneSeq = ref(state.nextSceneSequenceId)

    Logger.info(
      ~module_="SceneOperations",
      ~message="ADD_SCENES_START",
      ~data=Some({"count": Belt.Array.length(scenesData)}),
      (),
    )

    let (updatedInventory, addedIds) = scenesData->Belt.Array.reduce((state.inventory, []), (
      (inventory, ids),
      dataJson,
    ) => {
      let newScene = SceneHelpers.parseScene(dataJson)
      let finalSeq = if newScene.sequenceId > 0 {
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
      if inventory->Belt.Map.String.has(sequencedScene.id) {
        (inventory, ids)
      } else {
        (
          inventory->Belt.Map.String.set(
            sequencedScene.id,
            {scene: sequencedScene, status: Active},
          ),
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

    let mergedOrder = Belt.Array.concat(state.sceneOrder, addedIds)
    let sortedOrder = if wasEmpty {
      let sorted = Array.copy(mergedOrder)
      Array.sort(sorted, (leftId, rightId) => {
        let nameA = switch updatedInventory->Belt.Map.String.get(leftId) {
        | Some(entry) => entry.scene.name
        | None => ""
        }
        let nameB = switch updatedInventory->Belt.Map.String.get(rightId) {
        | Some(entry) => entry.scene.name
        | None => ""
        }
        String.localeCompare(nameA, nameB)
      })
      sorted
    } else {
      mergedOrder
    }

    let finalizedInventory = SceneNaming.syncInventoryNames(updatedInventory, sortedOrder)

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
