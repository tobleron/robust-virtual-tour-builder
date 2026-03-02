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
        "cancellable": bool,
        "eta": option<string>,
      },
    )
  | OpenHotspotMenu({"anchor": Dom.element, "hotspot": Types.hotspot, "index": int})
  | ForceHotspotSync
  | TriggerUpload
  | PreviewLinkId(string)
  | TriggerRetargetModal(Types.linkDraft)
  | NetworkStatusChanged(bool)
  | CancelActiveOperation
  | RateLimitBackoff(int)

type subscription = unit => unit
type listenerId = int
type weakRef<'a>
type loggerWarnHook = (string, string, JSON.t) => unit
type listenerEntry = {
  id: listenerId,
  strongCallback: option<event => unit>,
  weakCallback: option<weakRef<event => unit>>,
}

@new external makeWeakRef: (event => unit) => weakRef<event => unit> = "WeakRef"
@send external weakRefDeref: weakRef<event => unit> => Nullable.t<event => unit> = "deref"
@val external loggerWarnHook: option<loggerWarnHook> = "__vtbLoggerWarn"
let hasWeakRefSupport: unit => bool = %raw(`function() { return typeof WeakRef === "function"; }`)

type eventChannel =
  | Navigation
  | Upload
  | Ui
  | System

let allListeners: ref<array<listenerEntry>> = ref([])
let navigationListeners: ref<array<listenerEntry>> = ref([])
let uploadListeners: ref<array<listenerEntry>> = ref([])
let uiListeners: ref<array<listenerEntry>> = ref([])
let systemListeners: ref<array<listenerEntry>> = ref([])
let nextListenerId = ref(1)

let leakWarnThreshold = 50

let classifyChannel = (evt: event): eventChannel =>
  switch evt {
  | NavStart(_)
  | NavCompleted(_)
  | NavCancelled
  | NavProgress(_)
  | SceneArrived(_)
  | LinkPreviewStart(_)
  | LinkPreviewEnd
  | PreviewLinkId(_) =>
    Navigation
  | TriggerUpload | UpdateProcessing(_) => Upload
  | ShowModal(_)
  | CloseModal
  | OpenHotspotMenu(_)
  | ForceHotspotSync
  | ClearSimUi
  | TriggerRetargetModal(_) =>
    Ui
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
    let payload = JsonCombinators.Json.Encode.object([
      ("totalSubscriptions", JsonCombinators.Json.Encode.int(total)),
    ])
    switch loggerWarnHook {
    | Some(loggerWarn) => loggerWarn("EventBus", "SUBSCRIPTION_LEAK_SENTINEL", payload)
    | None => Console.warn2("[EventBus] SUBSCRIPTION_LEAK_SENTINEL", total)
    }
  }
}

let makeListenerEntry = (callback: event => unit): listenerEntry => {
  let id = nextListenerId.contents
  nextListenerId := id + 1

  if hasWeakRefSupport() {
    // Keep strong retention for active app subscriptions; weak ref is only supplemental.
    {id, strongCallback: Some(callback), weakCallback: Some(makeWeakRef(callback))}
  } else {
    {id, strongCallback: Some(callback), weakCallback: None}
  }
}

let getCallback = (entry: listenerEntry): option<event => unit> =>
  switch entry.strongCallback {
  | Some(cb) => Some(cb)
  | None =>
    switch entry.weakCallback {
    | Some(ref_) => weakRefDeref(ref_)->Nullable.toOption
    | None => None
    }
  }

let subscribe = (callback: event => unit): subscription => {
  let entry = makeListenerEntry(callback)
  allListeners := Belt.Array.concat(allListeners.contents, [entry])
  warnIfTooManySubscriptions()
  () => {
    allListeners := Belt.Array.keep(allListeners.contents, e => e.id != entry.id)
  }
}

let subscribeOn = (~channel: eventChannel, callback: event => unit): subscription => {
  let entry = makeListenerEntry(callback)
  let listenersRef = listenersRefForChannel(channel)
  listenersRef := Belt.Array.concat(listenersRef.contents, [entry])
  warnIfTooManySubscriptions()
  () => {
    listenersRef := Belt.Array.keep(listenersRef.contents, e => e.id != entry.id)
  }
}

let dispatchToListeners = (listenersRef: ref<array<listenerEntry>>, evt: event) => {
  let alive = ref([])
  listenersRef.contents->Belt.Array.forEach(entry => {
    switch getCallback(entry) {
    | Some(cb) =>
      alive := Belt.Array.concat(alive.contents, [entry])
      try {
        cb(evt)
      } catch {
      | JsExn(e) => Console.error2("EventBus Error: ", JsExn.message(e)->Option.getOr("Unknown"))
      | _ => Console.error("Unknown EventBus Error")
      }
    | None => ()
    }
  })
  listenersRef := alive.contents
}

let dispatch = (evt: event) => {
  // --- Auto-Logging Moved to Logger via Subscription ---
  dispatchToListeners(allListeners, evt)
  let channelRef = evt->classifyChannel->listenersRefForChannel
  dispatchToListeners(channelRef, evt)
}
