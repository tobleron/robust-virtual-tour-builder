open Types
open Actions

type sceneContext = {
  currentScene: option<scene>,
  currentCategory: string,
  currentLabel: string,
}

let deriveSceneContext = (~state: state, ~targetIndex: int): sceneContext => {
  let currentScene = Belt.Array.get(
    SceneInventory.getActiveScenes(state.inventory, state.sceneOrder),
    targetIndex,
  )

  {
    currentScene,
    currentCategory: switch currentScene {
    | Some(scene) => scene.category == "" ? "outdoor" : scene.category
    | None => "outdoor"
    },
    currentLabel: switch currentScene {
    | Some(scene) => scene.label
    | None => ""
    },
  }
}

let buildSequenceDrafts = (
  orderedHotspots: array<HotspotSequence.orderedHotspot>,
): Belt.Map.String.t<string> => LabelMenuRuntimeSequence.buildSequenceDrafts(orderedHotspots)

let recoverBaseName = (~currentScene: option<scene>): string =>
  LabelMenuRuntimeLabels.recoverBaseName(~currentScene)

let dispatchLabelUpdate = (~dispatch, ~targetIndex: int, ~label: string, ~baseName: string) =>
  LabelMenuRuntimeLabels.dispatchLabelUpdate(~dispatch, ~targetIndex, ~label, ~baseName)

let normalizeCustomLabel = (rawValue: string): string =>
  LabelMenuRuntimeLabels.normalizeCustomLabel(rawValue)

let handleSelect = (
  ~currentScene: option<scene>,
  ~targetIndex: int,
  ~dispatch,
  ~setFlickeringLabel: ((option<string> => option<string>)) => unit,
  ~label: string,
  ~onClose: unit => unit,
  e,
) =>
  LabelMenuRuntimeLabels.handleSelect(
    ~currentScene,
    ~targetIndex,
    ~dispatch,
    ~setFlickeringLabel,
    ~label,
    ~onClose,
    e,
  )

let handleApplyCustom = (
  ~customLabel: string,
  ~currentScene: option<scene>,
  ~targetIndex: int,
  ~dispatch,
  ~onClose: unit => unit,
) =>
  LabelMenuRuntimeLabels.handleApplyCustom(
    ~customLabel,
    ~currentScene,
    ~targetIndex,
    ~dispatch,
    ~onClose,
  )

let handleClear = (
  ~currentScene: option<scene>,
  ~targetIndex: int,
  ~dispatch,
  ~onClose: unit => unit,
) =>
  LabelMenuRuntimeLabels.handleClear(~currentScene, ~targetIndex, ~dispatch, ~onClose)

let handleSetCategory = (
  ~currentCategory: string,
  ~targetIndex: int,
  ~dispatch,
  cat: string,
  e,
) => LabelMenuRuntimeLabels.handleSetCategory(~currentCategory, ~targetIndex, ~dispatch, cat, e)

let applySequenceReorder = (
  ~dispatch,
  ~linkId: string,
  ~desiredOrder: int,
) => LabelMenuRuntimeSequence.applySequenceReorder(~dispatch, ~linkId, ~desiredOrder)

let commitSequenceDraft = (
  ~sequenceDrafts: Belt.Map.String.t<string>,
  ~setSequenceDrafts: ((Belt.Map.String.t<string> => Belt.Map.String.t<string>)) => unit,
  ~dispatch,
  ~linkId: string,
  ~currentSequence: int,
) =>
  LabelMenuRuntimeSequence.commitSequenceDraft(
    ~sequenceDrafts,
    ~setSequenceDrafts,
    ~dispatch,
    ~linkId,
    ~currentSequence,
  )

let executeRemoveAllUntagged = (~dispatch: action => unit, ~onClose: unit => unit) =>
  LabelMenuRuntimeUntagged.executeRemoveAllUntagged(~dispatch, ~onClose)

let handleRemoveAllUntagged = (
  ~canMutateProject: bool,
  ~dispatch,
  ~onClose: unit => unit,
) => LabelMenuRuntimeUntagged.handleRemoveAllUntagged(~canMutateProject, ~dispatch, ~onClose)
