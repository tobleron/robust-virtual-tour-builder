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

let calculateTransition = (transition: option<transition>): transition => {
  switch transition {
  | Some(t) => t
  | None => {type_: Fade, targetHotspotIndex: -1, fromSceneName: None}
  }
}
