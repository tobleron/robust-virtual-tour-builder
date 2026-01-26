/* src/systems/SceneLoader.res */

open ReBindings
open ViewerState

let loadStartTime = ref(0.0)

external castToString: 'a => string = "%identity"
external castToDict: 'a => dict<'b> = "%identity"
external asDynamic: 'a => {..} = "%identity"

let getPanoramaUrl = (file: Types.file): string => {
  UrlUtils.fileToUrl(file)
}

let loadNewScene = (
  capturedPrevSceneId: option<string>,
  targetIndexOpt: option<int>,
  ~isAnticipatory: bool=false,
) => {
  let _ = LazyLoad.loadPannellum()->Promise.then(() => {
    let targetIndex = switch targetIndexOpt {
    | Some(i) => i
    | None => GlobalStateBridge.getState().activeIndex
    }

    switch Belt.Array.get(GlobalStateBridge.getState().scenes, targetIndex) {
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

        /* Reuse Check */
        let shouldReuse = switch Nullable.toOption(inactiveViewer) {
        | Some(v) =>
          let vDyn = PannellumAdapter.asCustom(v)
          let vid = vDyn.sceneId
          if vid == targetScene.id {
            if vDyn.isLoaded {
              if GlobalStateBridge.getState().activeIndex == targetIndex && !isAnticipatory {
                GlobalStateBridge.dispatch(
                  DispatchNavigationFsmEvent(TextureLoaded({targetSceneId: targetScene.id})),
                )
                true
              } else {
                true /* Loaded but waiting */
              }
            } else {
              true /* Already loading this scene */
            }
          } else {
            false
          }
        | None => false
        }

        let loadingSceneIdFromFsm = switch GlobalStateBridge.getState().navigationFsm {
        | Preloading({targetSceneId}) => Some(targetSceneId)
        | _ => None
        }
        let isIncorrectTarget = switch loadingSceneIdFromFsm {
        | Some(id) => id != targetScene.id
        | None => true
        }

        let isFsmLoading = switch GlobalStateBridge.getState().navigationFsm {
        | Preloading(_) => true
        | _ => false
        }

        if !shouldReuse {
          /* Preemptive Load: If target changed while loading, interrupt and restart */
          if isFsmLoading && isIncorrectTarget {
            Logger.info(
              ~module_="Viewer",
              ~message="LOAD_INTERRUPTED_PREEMPTIVE",
              ~data=Some({"newScene": targetScene.name}),
              (),
            )
          }

          /* Cleanup existing inactive viewport and its pending cleanup timeouts */
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

          /* Pre-calc snapshot check */
          let snapshot = Dom.getElementById("viewer-snapshot-overlay")
          switch (capturedPrevSceneId, Nullable.toOption(snapshot)) {
          | (Some(prevId), Some(snapEl)) =>
            let prevScene = Belt.Array.getBy(GlobalStateBridge.getState().scenes, s =>
              s.id == prevId
            )
            switch prevScene {
            | Some(ps) =>
              switch SceneCache.getSnapshot(ps.id) {
              | Some(url) =>
                let isCut = switch GlobalStateBridge.getState().transition.type_ {
                | Cut => true
                | _ => false
                }
                if !isCut {
                  Dom.setBackgroundImage(snapEl, "url(" ++ url ++ ")")
                  Dom.add(snapEl, "snapshot-visible")
                }
                // Remove from cache to avoid reusing it, but delay revocation so DOM has time to render
                SceneCache.removeKeyOnly(ps.id)
                let _ = Window.setTimeout(() => URL.revokeObjectURL(url), 1000)
              | None => ()
              }
            | None => ()
            }
          | _ => ()
          }

          let panoramaUrl = getPanoramaUrl(targetScene.file)
          let currentGlobalState = GlobalStateBridge.getState()
          let useProgressive =
            Belt.Option.isSome(targetScene.tinyFile) &&
            !currentGlobalState.isTeasing &&
            !isAnticipatory

          let tinyUrl = if useProgressive {
            switch targetScene.tinyFile {
            | Some(f) => getPanoramaUrl(f)
            | None => ""
            }
          } else {
            ""
          }

          let storeState = GlobalStateBridge.getState()
          let initialPitch = if Float.isFinite(storeState.activePitch) {
            storeState.activePitch
          } else {
            0.0
          }
          let initialYaw = if Float.isFinite(storeState.activeYaw) {
            storeState.activeYaw
          } else {
            0.0
          }
          let initialHfov = Constants.globalHfov

          let hotspotsArr = []

          let viewerConfig = {
            "default": {
              "firstScene": if useProgressive {
                "preview"
              } else {
                "master"
              },
            },
            "scenes": {
              "preview": {
                "type": "equirectangular",
                "panorama": tinyUrl,
                "autoLoad": true,
                "pitch": initialPitch,
                "yaw": initialYaw,
                "hfov": initialHfov,
                "minHfov": 90.0,
                "maxHfov": 90.0,
                "mouseZoom": false,
                "friction": 0.15,
                "hotSpots": hotspotsArr,
              },
              "master": {
                "type": "equirectangular",
                "panorama": panoramaUrl,
                "autoLoad": true,
                "pitch": initialPitch,
                "yaw": initialYaw,
                "hfov": initialHfov,
                "minHfov": 90.0,
                "maxHfov": 90.0,
                "mouseZoom": false,
                "friction": 0.15,
                "hotSpots": hotspotsArr,
              },
            },
          }

          if !useProgressive {
            let configDict = castToDict(viewerConfig)
            switch Dict.get(configDict, "scenes") {
            | Some(scenes) =>
              let scenesDict = castToDict(scenes)
              Dict.delete(scenesDict, "preview")
            | None => ()
            }

            switch Dict.get(configDict, "default") {
            | Some(def) =>
              let defDyn = asDynamic(def)
              defDyn["firstScene"] = "master"
            | None => ()
            }
          }

          let _startLoadTime = Date.now()

          let el = Dom.getElementById(containerId)
          switch Nullable.toOption(el) {
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

              /* Event Listeners */
              PannellumAdapter.on(newViewer, "load", _ => {
                Logger.debug(
                  ~module_="Viewer",
                  ~message="PANNELLUM_LOAD_EVENT",
                  ~data=Some({"sceneId": targetScene.id}),
                  (),
                )
                let loadedSceneId = PannellumAdapter.getScene(newViewer)
                let isTiny = loadedSceneId == "preview"
                let isMaster = loadedSceneId == "master"

                if useProgressive && isTiny {
                  Logger.debug(
                    ~module_="Viewer",
                    ~message="PREVIEW_LOADED",
                    ~data=Some({"sceneName": targetScene.name}),
                    (),
                  )

                  let img = Dom.document["createElement"]("img")
                  Dom.setAttribute(img, "src", panoramaUrl)
                  Dom.addEventListenerNoEv(
                    img,
                    "load",
                    () => {
                      Logger.debug(
                        ~module_="Viewer",
                        ~message="MASTER_PRELOADED",
                        ~data=Some({"sceneName": targetScene.name}),
                        (),
                      )
                      if PannellumAdapter.getScene(newViewer) == "preview" {
                        PannellumAdapter.loadScene(
                          newViewer,
                          "master",
                          ~pitch=PannellumAdapter.getPitch(newViewer),
                          ~yaw=PannellumAdapter.getYaw(newViewer),
                          ~hfov=PannellumAdapter.getHfov(newViewer),
                          (),
                        )
                      }
                    },
                  )

                  Dom.addEventListenerNoEv(
                    img,
                    "error",
                    () => {
                      Logger.warn(
                        ~module_="Viewer",
                        ~message="MASTER_PRELOAD_FAILED",
                        ~data=Some({"sceneName": targetScene.name}),
                        (),
                      )
                      if PannellumAdapter.getScene(newViewer) == "preview" {
                        PannellumAdapter.loadScene(
                          newViewer,
                          "master",
                          ~pitch=PannellumAdapter.getPitch(newViewer),
                          ~yaw=PannellumAdapter.getYaw(newViewer),
                          ~hfov=PannellumAdapter.getHfov(newViewer),
                          (),
                        )
                      }
                    },
                  )
                } else if !useProgressive || isMaster {
                  PannellumAdapter.asCustom(newViewer).isLoaded = true
                  GlobalStateBridge.dispatch(
                    DispatchNavigationFsmEvent(TextureLoaded({targetSceneId: targetScene.id})),
                  )

                  // Inject hotspots
                  Belt.Array.forEachWithIndex(
                    targetScene.hotspots,
                    (i, h) => {
                      let config = HotspotManager.createHotspotConfig(
                        ~hotspot=h,
                        ~index=i,
                        ~state=currentGlobalState,
                        ~scene=targetScene,
                        ~dispatch=GlobalStateBridge.dispatch,
                      )
                      try {
                        PannellumAdapter.addHotSpot(newViewer, config)
                      } catch {
                      | _ => ()
                      }
                    },
                  )

                  Logger.info(
                    ~module_="Viewer",
                    ~message="TEXTURE_LOADED",
                    ~data=Some({
                      "sceneName": targetScene.name,
                      "quality": isMaster ? "4k" : "standard",
                    }),
                    (),
                  )
                }
              })

              PannellumAdapter.on(newViewer, "error", e => {
                Logger.error(
                  ~module_="Viewer",
                  ~message="PANNELLUM_ERROR",
                  ~data=Some({"error": e}),
                  (),
                )
                // If critical error, maybe trigger timeout/reset?
                // specific handling depends on error type, but logging is step 1.
              })
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
