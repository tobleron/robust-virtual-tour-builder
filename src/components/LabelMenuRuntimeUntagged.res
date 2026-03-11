open Actions

let executeRemoveAllUntagged = (~dispatch: action => unit, ~onClose: unit => unit) => {
  let liveState = AppContext.getBridgeState()
  switch LabelMenuSupport.bulkDeleteBlockReason(liveState) {
  | Some(reason) =>
    LabelMenuSupport.notifyWarning(~message="Cannot remove untagged scenes now", ~details=reason)
  | None =>
    let activeScenes = SceneInventory.getActiveScenes(liveState.inventory, liveState.sceneOrder)
    let untaggedIds =
      activeScenes
      ->Belt.Array.keep(LabelMenuSupport.isUntaggedScene)
      ->Belt.Array.map(scene => scene.id)

    if untaggedIds->Belt.Array.length == 0 {
      LabelMenuSupport.notifyInfo(~message="No untagged scenes found")
    } else {
      let indicesDescending =
        untaggedIds
        ->Belt.Array.keepMap(id => activeScenes->Belt.Array.getIndexBy(scene => scene.id == id))
        ->Belt.SortArray.stableSortBy((a, b) => b - a)

      if indicesDescending->Belt.Array.length == 0 {
        LabelMenuSupport.notifyInfo(~message="No untagged scenes found")
      } else {
        let deleteActions = indicesDescending->Belt.Array.map(idx => DeleteScene(idx))
        let actions = Belt.Array.concat(deleteActions, [CleanupTimeline])
        dispatch(Batch(actions))
        LabelMenuSupport.notifySuccess(
          ~message="Removed " ++
          Belt.Int.toString(indicesDescending->Belt.Array.length) ++ " untagged scenes",
        )
        onClose()
      }
    }
  }
}

let handleRemoveAllUntagged = (
  ~canMutateProject: bool,
  ~dispatch: action => unit,
  ~onClose: unit => unit,
) => {
  if !canMutateProject {
    LabelMenuSupport.notifyWarning(~message="Project is currently locked")
  } else {
    let liveState = AppContext.getBridgeState()
    switch LabelMenuSupport.bulkDeleteBlockReason(liveState) {
    | Some(reason) =>
      LabelMenuSupport.notifyWarning(~message="Cannot remove untagged scenes now", ~details=reason)
    | None =>
      let untaggedCount =
        SceneInventory.getActiveScenes(liveState.inventory, liveState.sceneOrder)
        ->Belt.Array.keep(LabelMenuSupport.isUntaggedScene)
        ->Belt.Array.length

      if untaggedCount == 0 {
        LabelMenuSupport.notifyInfo(~message="No untagged scenes found")
      } else {
        EventBus.dispatch(
          EventBus.ShowModal({
            title: "Remove Untagged Scenes",
            description: Some(
              "This will permanently delete " ++
              Belt.Int.toString(untaggedCount) ++ " untagged scenes from the project.",
            ),
            icon: Some("warning"),
            content: Some(
              <div className="text-[12px] text-white/80 leading-relaxed">
                {React.string("This action cannot be undone.")}
              </div>,
            ),
            allowClose: Some(true),
            onClose: None,
            className: Some("modal-blue"),
            buttons: [
              {
                label: "Cancel",
                class_: "bg-slate-100/10 text-white hover:bg-white/20",
                onClick: () => (),
                autoClose: Some(true),
              },
              {
                label: "Delete Untagged",
                class_: "bg-red-500/20 text-white hover:bg-red-500/40",
                onClick: () => executeRemoveAllUntagged(~dispatch, ~onClose),
                autoClose: Some(true),
              },
            ],
          }),
        )
      }
    }
  }
}
