/* src/systems/SceneLoaderLogic.res */

open ReBindings
open ViewerState
open SceneLoaderTypes
open SceneLoaderLogicReuse
open SceneLoaderLogicConfig
open SceneLoaderLogicEvents

let loadNewScene = (
  capturedPrevSceneId: option<string>,
  targetIndexOpt: option<int>,
  ~isAnticipatory: bool=false,
) => {
  let _ = LazyLoad.loadPannellum()->Promise.then(() => {
    let currentState = GlobalStateBridge.getState()
    let targetIndex = switch targetIndexOpt {
    | Some(i) => i
    | None => currentState.activeIndex
    }

    switch Belt.Array.get(currentState.scenes, targetIndex) {
    | Some(targetScene) =>
      Logger.debug(
        ~module_="Viewer",
        ~message="SCENE_LOAD_START",
        ~data=Some({
          "sceneName": targetScene.name,
          "sceneIndex": targetIndex,
          "isAnticipatory": isAnticipatory,
        }),
        (),
      )

      let inactiveViewport = ViewerPool.getInactive()
      let inactiveViewer = getInactiveViewer()

      switch inactiveViewport {
      | Some(ivp) =>
        let containerId = ivp.containerId

        if !checkShouldReuse(targetScene.id, targetIndex, isAnticipatory) {
          /* Preload Interruption Check */
          let isFsmPreloading = switch currentState.navigationFsm {
          | Preloading(_) => true
          | _ => false
          }
          let incorrectTarget = switch currentState.navigationFsm {
          | Preloading({targetSceneId}) => targetSceneId != targetScene.id
          | _ => true
          }

          if isFsmPreloading && incorrectTarget {
            Logger.info(
              ~module_="Viewer",
              ~message="LOAD_INTERRUPTED_PREEMPTIVE",
              ~data=Some({"newScene": targetScene.name}),
              (),
            )
          }

          /* Cleanup */
          ViewerPool.clearCleanupTimeout(ivp.id)
          switch Nullable.toOption(inactiveViewer) {
          | Some(v) => PannellumAdapter.destroy(v)
          | None => ()
          }

          loadStartTime := Date.now()
          GlobalStateBridge.dispatch(
            DispatchNavigationFsmEvent(PreloadStarted({targetSceneId: targetScene.id})),
          )

          /* Safety Timeout */
          switch Nullable.toOption(state.loadSafetyTimeout) {
          | Some(t) => Window.clearTimeout(t)
          | None => ()
          }
          state.loadSafetyTimeout = Nullable.make(Window.setTimeout(() => {
              let fsmState = GlobalStateBridge.getState().navigationFsm
              let isLoadingCorrect = switch fsmState {
              | Preloading({targetSceneId}) => targetSceneId == targetScene.id
              | _ => false
              }

              if isLoadingCorrect {
                Logger.error(
                  ~module_="Viewer",
                  ~message="SCENE_LOAD_TIMEOUT",
                  ~data=Some({
                    "sceneName": targetScene.name,
                    "timeoutMs": Constants.sceneLoadTimeout,
                  }),
                  (),
                )
                GlobalStateBridge.dispatch(DispatchNavigationFsmEvent(LoadTimeout))
              }
            }, Constants.sceneLoadTimeout))

          /* Snapshot transition handling */
          let snapshot = Dom.getElementById("viewer-snapshot-overlay")
          switch (capturedPrevSceneId, Nullable.toOption(snapshot)) {
          | (Some(prevId), Some(snapEl)) =>
            let prevScene = Belt.Array.getBy(currentState.scenes, s => s.id == prevId)
            switch prevScene {
            | Some(ps) =>
              switch SceneCache.getSnapshot(ps.id) {
              | Some(url) =>
                let isCut = switch currentState.transition.type_ {
                | Cut => true
                | _ => false
                }
                if !isCut {
                  Dom.setBackgroundImage(snapEl, "url(" ++ url ++ ")")
                  Dom.add(snapEl, "snapshot-visible")
                }
                SceneCache.removeKeyOnly(ps.id)
                let _ = Window.setTimeout(() => URL.revokeObjectURL(url), 1000)
              | None => ()
              }
            | None => ()
            }
          | _ => ()
          }

          /* Initialization */
          let panoramaUrl = getPanoramaUrl(targetScene.file)
          let useProgressive =
            Belt.Option.isSome(targetScene.tinyFile) &&
            !currentState.isTeasing &&
            !isAnticipatory

          let tinyUrl = if useProgressive {
            switch targetScene.tinyFile {
            | Some(f) => getPanoramaUrl(f)
            | None => ""
            }
          } else {
            ""
          }

          let viewerConfig = createViewerConfig(useProgressive, panoramaUrl, tinyUrl)

          let _el = Dom.getElementById(containerId)
          switch Nullable.toOption(_el) {
          | Some(_) =>
            try {
              Logger.debug(
                ~module_="Viewer",
                ~message="PANNELLUM_INIT_START",
                ~data=Some({
                  "containerId": containerId,
                  "url": panoramaUrl,
                  "sceneId": targetScene.id,
                }),
                (),
              )
              let newViewer = PannellumAdapter.initialize(containerId, viewerConfig)

              PannellumAdapter.asCustom(newViewer).sceneId = targetScene.id
              PannellumAdapter.asCustom(newViewer).isLoaded = false

              ViewerPool.registerInstance(containerId, newViewer)

              setupViewerEvents(newViewer, targetScene, useProgressive, panoramaUrl)
            } catch {
            | JsExn(e) =>
              Logger.error(
                ~module_="Viewer",
                ~message="INIT_CRASH",
                ~data=Some({"error": JsExn.message(e)}),
                (),
              )
            | _ => ()
            }
          | None =>
            Logger.error(
              ~module_="Viewer",
              ~message="CONTAINER_NOT_FOUND",
              ~data=Some({"id": containerId}),
              (),
            )
          }
        }
      | None => ()
      }
    | None => ()
    }
    Promise.resolve()
  })
}
