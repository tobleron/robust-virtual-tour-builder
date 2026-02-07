open ReBindings
open ViewerState
open InteractionPolicies

let performSnapshot = () => {
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
              let storeState = GlobalStateBridge.getState()
              let activeIndex = storeState.activeIndex

              switch Belt.Array.get(storeState.scenes, activeIndex) {
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

let debouncedSnapshot = Debounce.make(~fn=() => {
  switch InteractionGuard.attempt(
    "viewer_snapshot_limit",
    SlidingWindow(10, 60000, 2000),
    performSnapshot,
  ) {
  | Ok(p) => p
  | Error(_) =>
    Logger.warn(~module_="ViewerSnapshot", ~message="SNAPSHOT_RATE_LIMITED", ())
    NotificationManager.dispatch({
      id: "",
      importance: Info,
      context: Operation("viewer_snapshot"),
      message: "Please wait before taking another snapshot",
      details: None,
      action: None,
      duration: NotificationTypes.defaultTimeoutMs(Info),
      dismissible: true,
      createdAt: Date.now(),
    })
    Promise.resolve()
  }
}, ~wait=1000, ~leading=false, ~trailing=true)

let requestIdleSnapshot = () => {
  switch Nullable.toOption(state.contents.idleSnapshotTimeout) {
  | Some(t) => Window.clearTimeout(t)
  | None => ()
  }

  state := {...state.contents, idleSnapshotTimeout: Nullable.null}

  let _ = debouncedSnapshot.call()
}
