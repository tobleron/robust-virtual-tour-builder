open ReBindings
open ViewerState

let requestIdleSnapshot = () => {
  switch Nullable.toOption(state.contents.idleSnapshotTimeout) {
  | Some(t) => Window.clearTimeout(t)
  | None => ()
  }

  state := {
    ...state.contents,
    idleSnapshotTimeout: Nullable.make(Window.setTimeout(() => {
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
              },
              "image/webp",
              0.7,
            )
          | None => ()
          }

        | None => ()
        }
        state := {...state.contents, idleSnapshotTimeout: Nullable.null}
      }, Constants.idleSnapshotDelay))
  }
}
