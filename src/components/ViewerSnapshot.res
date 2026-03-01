open ReBindings
open ViewerState
open InteractionPolicies

let performSnapshot = (~getState: unit => Types.state=AppContext.getBridgeState) => {
  Promise.make((resolve, _reject) => {
    let viewer = ViewerSystem.getActiveViewer()

    switch Nullable.toOption(viewer) {
    | Some(_) =>
      let containerId = ViewerSystem.getActiveContainerId()

      let container = Dom.getElementById(containerId)
      let canvas = switch Nullable.toOption(container) {
      | Some(el) => Dom.querySelector(el, "canvas")
      | None => Nullable.null
      }

      switch Nullable.toOption(canvas) {
      | Some(c) =>
        let toBlob: (Dom.element, Nullable.t<Blob.t> => unit, string, float) => unit = %raw(
          "(el, cb, type, q) => el.toBlob(cb, type, q)"
        )

        toBlob(
          c,
          blob => {
            switch Nullable.toOption(blob) {
            | Some(b) =>
              let snapshotUrl = UrlUtils.safeCreateObjectURL(b)
              let storeState = getState()
              let activeIndex = storeState.activeIndex

              let activeScenes = SceneInventory.getActiveScenes(
                storeState.inventory,
                storeState.sceneOrder,
              )
              switch Belt.Array.get(activeScenes, activeIndex) {
              | Some(currentScene) =>
                // cleanup old
                SceneCache.setSnapshot(currentScene.id, snapshotUrl)
                Logger.debug(
                  ~module_="Viewer",
                  ~message="SNAPSHOT_CAPTURED",
                  ~data=Some({"sceneName": currentScene.name}),
                  (),
                )
              | None => ()
              }
            | None => ()
            }
            resolve()
          },
          "image/webp",
          0.7,
        )
      | None => resolve()
      }

    | None => resolve()
    }
  })
}

let snapshotGetterRef = ref(AppContext.getBridgeState)
let lastRateLimitedToastAt = ref(0.0)

let dispatchRateLimitedToast = () => {
  let now = Date.now()
  if now -. lastRateLimitedToastAt.contents >= Constants.Snapshot.rateLimitToastCooldownMs {
    lastRateLimitedToastAt := now
    NotificationManager.dispatch({
      id: "",
      importance: Info,
      context: Operation("viewer_snapshot"),
      message: "Rendering...please wait",
      details: None,
      action: None,
      duration: NotificationTypes.defaultTimeoutMs(Info),
      dismissible: true,
      createdAt: now,
    })
  } else {
    Logger.debug(
      ~module_="ViewerSnapshot",
      ~message="SNAPSHOT_RATE_LIMITED_TOAST_COOLDOWN_ACTIVE",
      (),
    )
  }
}

let debouncedSnapshot = Debounce.make(~fn=() => {
  switch InteractionGuard.attempt(
    "viewer_snapshot_limit",
    SlidingWindow(
      Constants.Snapshot.rateLimitMaxCalls,
      Constants.Snapshot.rateLimitWindowMs,
      Constants.Snapshot.rateLimitMinIntervalMs,
    ),
    () => performSnapshot(~getState=snapshotGetterRef.contents),
  ) {
  | Ok(p) => p
  | Error("Rate limited") =>
    Logger.debug(~module_="ViewerSnapshot", ~message="SNAPSHOT_RATE_LIMITED", ())
    dispatchRateLimitedToast()
    Promise.resolve()
  | Error("Throttled") =>
    Logger.debug(~module_="ViewerSnapshot", ~message="SNAPSHOT_MIN_INTERVAL_THROTTLED", ())
    Promise.resolve()
  | Error(msg) =>
    Logger.debug(
      ~module_="ViewerSnapshot",
      ~message="SNAPSHOT_CAPTURE_SUPPRESSED",
      ~data=Some({"reason": msg}),
      (),
    )
    Promise.resolve()
  }
}, ~wait=Constants.Snapshot.debounceWaitMs, ~leading=false, ~trailing=true)

let requestIdleSnapshot = (~getState: unit => Types.state=AppContext.getBridgeState) => {
  switch Nullable.toOption(state.contents.idleSnapshotTimeout) {
  | Some(t) => Window.clearTimeout(t)
  | None => ()
  }

  state := {...state.contents, idleSnapshotTimeout: Nullable.null}
  snapshotGetterRef := getState

  let _ = debouncedSnapshot.call()
}
