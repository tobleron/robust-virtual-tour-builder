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
  | ShowNotification(string, [#Info | #Success | #Error | #Warning], option<JSON.t>)
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

type subscription = unit => unit

let listeners: ref<array<event => unit>> = ref([])

let subscribe = (callback: event => unit): subscription => {
  listeners := Belt.Array.concat(listeners.contents, [callback])
  () => {
    listeners := Belt.Array.keep(listeners.contents, cb => cb !== callback)
  }
}

let dispatch = (evt: event) => {
  // --- Auto-Logging Interceptor ---
  // Ensures UI feedback is mirrored in backend telemetry
  switch evt {
  | ShowNotification(msg, type_, data) =>
    let module_ = "UI:Notification"
    switch type_ {
    | #Error => Logger.error(~module_, ~message=msg, ~data?, ())
    | #Warning => Logger.warn(~module_, ~message=msg, ~data?, ())
    | #Success => Logger.info(~module_, ~message=`SUCCESS: ${msg}`, ~data?, ())
    | #Info => Logger.info(~module_, ~message=`INFO: ${msg}`, ~data?, ())
    }
  | ShowModal(config) =>
    Logger.info(
      ~module_="Modal",
      ~message=`Opening Modal: ${config.title}`,
      ~data=Logger.castToJson(config.description),
      (),
    )
  | UpdateProcessing(status) =>
    if status["error"] {
      Logger.error(
        ~module_="Processing",
        ~message=`Processing Error: ${status["message"]}`,
        ~data=Logger.castToJson(status),
        (),
      )
    }
  | NavStart(payload) =>
    Logger.info(
      ~module_="Navigation",
      ~message=`Navigating to Journey ${Belt.Int.toString(payload.journeyId)}`,
      (),
    )
  | _ => () // Ignore high-frequency events like NavProgress
  }

  listeners.contents->Belt.Array.forEach(cb => {
    try {
      cb(evt)
    } catch {
    | JsExn(e) =>
      Logger.error(
        ~module_="EventBus",
        ~message=`EventBus Error: ${JsExn.message(e)->Option.getOr("Unknown")}`,
        (),
      )
    | _ => Logger.error(~module_="EventBus", ~message="Unknown EventBus Error", ())
    }
  })
}
