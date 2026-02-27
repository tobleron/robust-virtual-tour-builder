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

type eventChannel =
  | Navigation
  | Upload
  | Ui
  | System

let allListeners: ref<array<event => unit>> = ref([])
let navigationListeners: ref<array<event => unit>> = ref([])
let uploadListeners: ref<array<event => unit>> = ref([])
let uiListeners: ref<array<event => unit>> = ref([])
let systemListeners: ref<array<event => unit>> = ref([])

let leakWarnThreshold = 50

let classifyChannel = (evt: event): eventChannel =>
  switch evt {
  | NavStart(_) | NavCompleted(_) | NavCancelled | NavProgress(_) | SceneArrived(_) | LinkPreviewStart(_)
  | LinkPreviewEnd | PreviewLinkId(_) =>
    Navigation
  | TriggerUpload | UpdateProcessing(_) => Upload
  | ShowModal(_) | CloseModal | OpenHotspotMenu(_) | ForceHotspotSync | ClearSimUi => Ui
  | NetworkStatusChanged(_) | CancelActiveOperation | RateLimitBackoff(_) => System
  }

let listenersRefForChannel = (channel: eventChannel) =>
  switch channel {
  | Navigation => navigationListeners
  | Upload => uploadListeners
  | Ui => uiListeners
  | System => systemListeners
  }

let subscriptionCount = () =>
  Belt.Array.length(allListeners.contents) +
  Belt.Array.length(navigationListeners.contents) +
  Belt.Array.length(uploadListeners.contents) +
  Belt.Array.length(uiListeners.contents) +
  Belt.Array.length(systemListeners.contents)

let warnIfTooManySubscriptions = () => {
  let total = subscriptionCount()
  if total > leakWarnThreshold {
    Console.warn2("[EventBus] SUBSCRIPTION_LEAK_SENTINEL", total)
  }
}

let subscribe = (callback: event => unit): subscription => {
  allListeners := Belt.Array.concat(allListeners.contents, [callback])
  warnIfTooManySubscriptions()
  () => {
    allListeners := Belt.Array.keep(allListeners.contents, cb => cb !== callback)
  }
}

let subscribeOn = (~channel: eventChannel, callback: event => unit): subscription => {
  let listenersRef = listenersRefForChannel(channel)
  listenersRef := Belt.Array.concat(listenersRef.contents, [callback])
  warnIfTooManySubscriptions()
  () => {
    listenersRef := Belt.Array.keep(listenersRef.contents, cb => cb !== callback)
  }
}

let dispatchToListeners = (listeners: array<event => unit>, evt: event) => {
  listeners->Belt.Array.forEach(cb => {
    try {
      cb(evt)
    } catch {
    | JsExn(e) => Console.error2("EventBus Error: ", JsExn.message(e)->Option.getOr("Unknown"))
    | _ => Console.error("Unknown EventBus Error")
    }
  })
}

let dispatch = (evt: event) => {
  // --- Auto-Logging Moved to Logger via Subscription ---
  dispatchToListeners(allListeners.contents, evt)
  let channelRef = evt->classifyChannel->listenersRefForChannel
  dispatchToListeners(channelRef.contents, evt)
}
