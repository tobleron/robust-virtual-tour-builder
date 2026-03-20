/* src/components/LabelMenu.res */
open Types

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

  let (customLabel, setCustomLabel) = React.useState(_ => "")
  let (flickeringLabel, setFlickeringLabel) = React.useState(_ => None)

  let targetIndex = sceneIndex->Option.getOr(state.activeIndex)
  let {currentScene, currentCategory, currentLabel} = LabelMenuRuntime.deriveSceneContext(
    ~state,
    ~targetIndex,
  )

  // Effect to sync custom label input with current scene label
  React.useEffect1(() => {
    setCustomLabel(_ => currentLabel)
    None
  }, [currentLabel])

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

  let handleRemoveAllUntagged = () =>
    LabelMenuRuntime.handleRemoveAllUntagged(~canMutateProject, ~dispatch, ~onClose)

  <div className="flex flex-col w-[230px] max-h-[380px]">
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
  </div>
}
