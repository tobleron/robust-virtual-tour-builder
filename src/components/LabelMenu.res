/* src/components/LabelMenu.res */
open Types

type tab =
  | SceneTag
  | Sequence

let isUntaggedScene = (scene: scene): bool => {
  LabelMenuSupport.isUntaggedScene(scene)
}

let bulkDeleteBlockReason = (state: state): option<string> => {
  LabelMenuSupport.bulkDeleteBlockReason(state)
}

let notifyInfo = (~message: string) => {
  LabelMenuSupport.notifyInfo(~message)
}

let notifyWarning = (~message: string, ~details: option<string>=?) => {
  LabelMenuSupport.notifyWarning(~message, ~details?)
}

let notifySuccess = (~message: string) => {
  LabelMenuSupport.notifySuccess(~message)
}

@react.component
let make = (~onClose: unit => unit, ~sceneIndex: option<int>=?) => {
  let state = AppContext.useAppState()
  let dispatch = AppContext.useAppDispatch()
  let canMutateProject = Capability.useCapability(CanMutateProject)

  let (activeTab, _setActiveTab) = React.useState(_ => SceneTag)
  let (customLabel, setCustomLabel) = React.useState(_ => "")
  let (flickeringLabel, setFlickeringLabel) = React.useState(_ => None)
  let (sequenceDrafts, setSequenceDrafts) = React.useState(_ => Belt.Map.String.empty)

  let targetIndex = sceneIndex->Option.getOr(state.activeIndex)
  let {currentScene, currentCategory, currentLabel} = LabelMenuRuntime.deriveSceneContext(
    ~state,
    ~targetIndex,
  )

  let orderedHotspots = React.useMemo1(
    () => HotspotSequence.deriveOrderedHotspots(~state),
    [state.structuralRevision],
  )

  // Effect to sync custom label input with current scene label
  React.useEffect1(() => {
    setCustomLabel(_ => currentLabel)
    None
  }, [currentLabel])

  React.useEffect1(() => {
    let drafts = LabelMenuRuntime.buildSequenceDrafts(orderedHotspots)
    setSequenceDrafts(_ => drafts)
    None
  }, [state.structuralRevision])

  let handleSelect = (label, e) =>
    LabelMenuRuntime.handleSelect(
      ~currentScene,
      ~targetIndex,
      ~dispatch,
      ~setFlickeringLabel,
      ~label,
      ~onClose,
      e,
    )

  let handleApplyCustom = () =>
    LabelMenuRuntime.handleApplyCustom(
      ~customLabel,
      ~currentScene,
      ~targetIndex,
      ~dispatch,
      ~onClose,
    )

  let handleClear = () =>
    LabelMenuRuntime.handleClear(~currentScene, ~targetIndex, ~dispatch, ~onClose)

  let handleSetCategory = (cat, e) =>
    LabelMenuRuntime.handleSetCategory(~currentCategory, ~targetIndex, ~dispatch, cat, e)

  let commitSequenceDraft = (~linkId: string, ~currentSequence: int) =>
    LabelMenuRuntime.commitSequenceDraft(
      ~sequenceDrafts,
      ~setSequenceDrafts,
      ~dispatch,
      ~linkId,
      ~currentSequence,
    )

  let handleRemoveAllUntagged = () =>
    LabelMenuRuntime.handleRemoveAllUntagged(~canMutateProject, ~dispatch, ~onClose)

  <div className="flex flex-col w-[230px] max-h-[380px]">
    {switch activeTab {
    | SceneTag =>
      <LabelMenuTabs.SceneTagTab
        currentCategory
        currentLabel
        flickeringLabel
        customLabel
        setCustomLabel
        handleSetCategory
        handleSelect
        handleApplyCustom
        handleClear
        handleRemoveAllUntagged
      />
    | Sequence =>
      <LabelMenuTabs.SequenceTab
        orderedHotspots sequenceDrafts setSequenceDrafts commitSequenceDraft
      />
    }}
  </div>
}
