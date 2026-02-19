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
  content: option<React.element>,
  buttons: array<button>,
  icon: option<string>,
  allowClose: option<bool>,
  onClose: option<unit => unit>,
  className: option<string>,
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
  | ShowModal(modalConfig)
  | CloseModal
  | UpdateProcessing(
      {
        "active": bool,
        "progress": float,
        "message": string,
        "phase": string,
        "error": bool,
        "onCancel": unit => unit,
      },
    )
  | OpenHotspotMenu({"anchor": Dom.element, "hotspot": Types.hotspot, "index": int})
  | ForceHotspotSync
  | TriggerUpload
  | PreviewLinkId(string)
  | NetworkStatusChanged(bool)
  | CancelActiveOperation
  | RateLimitBackoff(int)

type subscription = unit => unit

let listeners: ref<array<event => unit>> = ref([])

let subscribe = (callback: event => unit): subscription => {
  listeners := Belt.Array.concat(listeners.contents, [callback])
  () => {
    listeners := Belt.Array.keep(listeners.contents, cb => cb !== callback)
  }
}

let dispatch = (evt: event) => {
  // --- Auto-Logging Moved to Logger via Subscription ---

  listeners.contents->Belt.Array.forEach(cb => {
    try {
      cb(evt)
    } catch {
    | JsExn(e) => Console.error2("EventBus Error: ", JsExn.message(e)->Option.getOr("Unknown"))
    | _ => Console.error("Unknown EventBus Error")
    }
  })
}
