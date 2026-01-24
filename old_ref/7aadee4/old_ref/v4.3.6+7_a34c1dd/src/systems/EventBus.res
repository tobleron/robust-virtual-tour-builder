open Types

type navStartPayload = {
  journeyId: int,
  targetIndex: int,
  sourceIndex: int,
  hotspotIndex: int,
  previewOnly: bool,
  pathData: pathData,
}

type button = {
  label: string,
  class_: string,
  onClick: unit => unit,
  autoClose: option<bool>,
}

type modalConfig = {
  title: string,
  description: option<string>,
  contentHtml: option<string>,
  buttons: array<button>,
  icon: option<string>,
  allowClose: option<bool>,
  onClose: option<unit => unit>,
}

type event =
  | NavStart(navStartPayload)
  | NavCompleted(journeyData)
  | NavCancelled
  | NavProgress(float)
  | SceneArrived(string)
  | ClearSimUi
  | LinkPreviewStart(string)
  | LinkPreviewEnd
  | ShowNotification(string, [#Info | #Success | #Error | #Warning])
  | ShowModal(modalConfig)
  | CloseModal
  | UpdateProcessing(
      {"active": bool, "progress": float, "message": string, "phase": string, "error": bool},
    )

type subscription = unit => unit

let listeners: ref<array<event => unit>> = ref([])

let subscribe = (callback: event => unit): subscription => {
  listeners := Belt.Array.concat(listeners.contents, [callback])
  () => {
    listeners := Belt.Array.keep(listeners.contents, cb => cb !== callback)
  }
}

let dispatch = (evt: event) => {
  listeners.contents->Belt.Array.forEach(cb => {
    try {
      cb(evt)
    } catch {
    | JsExn(e) =>
      Logger.error(
        ~module_="EventBus",
        ~message=`EventBus Error: ${(Obj.magic(e): JsExn.t)
          ->JsExn.message
          ->Option.getOr("Unknown")}`,
        (),
      )
    | _ => Logger.error(~module_="EventBus", ~message="Unknown EventBus Error", ())
    }
  })
}
