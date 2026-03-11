open Types
open Actions

let recoverBaseName = (~currentScene: option<scene>): string =>
  switch currentScene {
  | Some(scene) => TourLogic.recoverBaseName(scene.name, scene.label)
  | None => ""
  }

let dispatchLabelUpdate = (
  ~dispatch: action => unit,
  ~targetIndex: int,
  ~label: string,
  ~baseName: string,
) => {
  dispatch(
    UpdateSceneMetadata(
      targetIndex,
      Logger.castToJson({
        "label": label,
        "_baseName": baseName,
      }),
    ),
  )
}

let normalizeWord = (word: string): string => {
  let len = String.length(word)
  if len > 0 {
    String.toUpperCase(String.substring(word, ~start=0, ~end=1)) ++
    String.toLowerCase(String.substring(word, ~start=1, ~end=len))
  } else {
    word
  }
}

let normalizeCustomLabel = (rawValue: string): string => {
  let trimmed = rawValue->String.trim
  let isAllCaps = String.toUpperCase(trimmed) == trimmed && String.toLowerCase(trimmed) != trimmed

  if isAllCaps {
    trimmed->String.split(" ")->Belt.Array.map(normalizeWord)->Array.joinUnsafe(" ")
  } else {
    trimmed
  }
}

let handleSelect = (
  ~currentScene: option<scene>,
  ~targetIndex: int,
  ~dispatch: action => unit,
  ~setFlickeringLabel: (option<string> => option<string>) => unit,
  ~label: string,
  ~onClose: unit => unit,
  e: JsxEvent.Mouse.t,
) => {
  JsxEvent.Mouse.preventDefault(e)
  setFlickeringLabel(_ => Some(label))

  let baseName = recoverBaseName(~currentScene)

  let _ = ReBindings.Window.setTimeout(() => {
    setFlickeringLabel(_ => None)
    dispatchLabelUpdate(~dispatch, ~targetIndex, ~label, ~baseName)
    Logger.info(
      ~module_="LabelMenu",
      ~message="LABEL_SET",
      ~data=Some({"label": label, "index": targetIndex, "preservedBase": baseName}),
      (),
    )
    LabelMenuSupport.notifySuccess(~message="Label Set: " ++ label)
    onClose()
  }, 800)
}

let handleApplyCustom = (
  ~customLabel: string,
  ~currentScene: option<scene>,
  ~targetIndex: int,
  ~dispatch: action => unit,
  ~onClose: unit => unit,
) => {
  let value = normalizeCustomLabel(customLabel)
  if value != "" {
    let baseName = recoverBaseName(~currentScene)
    dispatchLabelUpdate(~dispatch, ~targetIndex, ~label=value, ~baseName)
    Logger.info(
      ~module_="LabelMenu",
      ~message="LABEL_SET_CUSTOM",
      ~data=Some({"label": value, "index": targetIndex}),
      (),
    )
    LabelMenuSupport.notifySuccess(~message="Label Set: " ++ value)
    onClose()
  }
}

let handleClear = (
  ~currentScene: option<scene>,
  ~targetIndex: int,
  ~dispatch: action => unit,
  ~onClose: unit => unit,
) => {
  let baseName = recoverBaseName(~currentScene)
  dispatchLabelUpdate(~dispatch, ~targetIndex, ~label="", ~baseName)
  LabelMenuSupport.notifyWarning(~message="Label Cleared")
  onClose()
}

let handleSetCategory = (
  ~currentCategory: string,
  ~targetIndex: int,
  ~dispatch: action => unit,
  cat: string,
  e: JsxEvent.Mouse.t,
) => {
  JsxEvent.Mouse.preventDefault(e)
  if currentCategory != cat {
    dispatch(UpdateSceneMetadata(targetIndex, Logger.castToJson({"category": cat})))
  }
}
