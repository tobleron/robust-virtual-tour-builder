open ReBindings
open ViewerTypes
open ViewerState

let loadStartTime = ref(0.0)

external castToString: 'a => string = "%identity"
external castToDict: 'a => dict<'b> = "%identity"
external asDynamic: 'a => {..} = "%identity"

let getPanoramaUrl = (file: Types.file): string => {
  UrlUtils.fileToUrl(file)
}

let rec loadNewScene = (
  capturedPrevSceneId: option<string>,
  anticipatoryTargetIndex: option<int>,
) => {
  let _ = LazyLoad.loadPannellum()->Promise.then(() => {
    let isAnticipatory = Belt.Option.isSome(anticipatoryTargetIndex)
    let targetIndex = switch anticipatoryTargetIndex {
    | Some(i) => i
    | None => GlobalStateBridge.getState().activeIndex
    }

    let performSwapAndCheck = targetScene => {
      SceneTransitionManager.performSwap(targetScene, loadStartTime.contents)

      /* Recovery Check */
      let latestState = GlobalStateBridge.getState()
      switch Belt.Array.get(latestState.scenes, latestState.activeIndex) {
      | Some(latestActiveScene) =>
        if latestActiveScene.id != targetScene.id {
          Logger.warn(
            ~module_="Viewer",
            ~message="LOAD_INTERRUPTED",
            ~data=Some({
              "originalScene": targetScene.name,
              "currentScene": latestActiveScene.name,
              "action": "triggering recovery",
            }),
            (),
          )
          loadNewScene(Some(targetScene.id), None)
        }
      | None => ()
      }
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
      let _inactiveKey = switch state.activeViewerKey {
      | A => B
      | B => A
      }
      let inactiveViewer = getInactiveViewer()
      let containerId = getInactiveContainerId()

      /* Reuse Check */
      let shouldReuse = switch Nullable.toOption(inactiveViewer) {
      | Some(v) =>
        let vDyn = PannellumLifecycle.asCustom(v)
        let vid = vDyn.sceneId
        if vid == targetScene.id {
          if vDyn.isLoaded {
            if GlobalStateBridge.getState().activeIndex == targetIndex && !isAnticipatory {
              performSwapAndCheck(targetScene)
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

      let isIncorrectTarget = switch Nullable.toOption(state.loadingSceneId) {
      | Some(id) => id != targetScene.id
      | None => true
      }

      if !shouldReuse {
        if state.isSceneLoading && !isIncorrectTarget && !isAnticipatory {
          Logger.debug(
            ~module_="Viewer",
            ~message="LOAD_SKIPPED",
            ~data=Some({"reason": "Already loading correct target"}),
            (),
          )
        } else {
          /* Preemptive Load: If target changed while loading, interrupt and restart (v4.7.12) */
          if state.isSceneLoading && isIncorrectTarget {
            Logger.info(
              ~module_="Viewer",
              ~message="LOAD_INTERRUPTED_PREEMPTIVE",
              ~data=Some({"newScene": targetScene.name}),
              (),
            )
          }

          /* Cleanup existing inactive viewer and its pending cleanup timeouts */
          let inactiveKey = switch state.activeViewerKey {
          | A => B
          | B => A
          }
          switch inactiveKey {
          | A =>
            switch Nullable.toOption(state.cleanupTimeoutA) {
            | Some(t) => Window.clearTimeout(t)
            | None => ()
            }
            state.cleanupTimeoutA = Nullable.null
          | B =>
            switch Nullable.toOption(state.cleanupTimeoutB) {
            | Some(t) => Window.clearTimeout(t)
            | None => ()
            }
            state.cleanupTimeoutB = Nullable.null
          }

          switch Nullable.toOption(inactiveViewer) {
          | Some(v) => PannellumLifecycle.destroyViewer(v)
          | None => ()
          }

          loadStartTime := Date.now()
          state.isSceneLoading = true
          state.loadingSceneId = Nullable.make(targetScene.id)

          /* Safety Timeout */
          switch Nullable.toOption(state.loadSafetyTimeout) {
          | Some(t) => Window.clearTimeout(t)
          | None => ()
          }
          state.loadSafetyTimeout = Nullable.make(Window.setTimeout(() => {
              if (
                state.isSceneLoading &&
                Nullable.toOption(state.loadingSceneId) == Some(targetScene.id)
              ) {
                Logger.error(
                  ~module_="Viewer",
                  ~message="SCENE_LOAD_TIMEOUT",
                  ~data=Some({
                    "sceneName": targetScene.name,
                    "timeoutMs": Constants.sceneLoadTimeout,
                  }),
                  (),
                )
                state.isSceneLoading = false
                state.loadingSceneId = Nullable.null
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
          // Progressive loading: Load preview (tinyFile) first, then upgrade to full quality
          // This significantly reduces initial load time and improves AutoPilot performance
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
          let initialHfov = Constants.backendUrl == "" ? Constants.globalHfov : Constants.globalHfov

          // Defer hotspot creation until AFTER load to prevent "Ghost Arrow" artifacts at (0,0)
          // We pass empty array initially, then add them dynamically in the 'load' handler
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
          let newViewer = PannellumLifecycle.initializeViewer(containerId, viewerConfig)
          PannellumLifecycle.asCustom(newViewer).sceneId = targetScene.id
          PannellumLifecycle.asCustom(newViewer).isLoaded = false

          switch state.activeViewerKey {
          | A => state.viewerB = Nullable.make(newViewer)
          | B => state.viewerA = Nullable.make(newViewer)
          }

          /* Event Listeners */
          Viewer.on(newViewer, "load", _ => {
            let loadedSceneId = Viewer.getScene(
              newViewer,
            ) /* returns scene ID string e.g 'master' */
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
                  if Viewer.getScene(newViewer) == "preview" {
                    Viewer.loadScene(
                      newViewer,
                      "master",
                      Viewer.getPitch(newViewer),
                      Viewer.getYaw(newViewer),
                      Viewer.getHfov(newViewer),
                    )
                  }
                },
              )
            } else if !useProgressive || isMaster {
              PannellumLifecycle.asCustom(newViewer).isLoaded = true

              // Inject hotspots now that viewer is stable
              // This prevents them from appearing at (0,0) before the camera is ready
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
                    Viewer.addHotSpot(newViewer, config)
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

              let checkReadyAndSwap = () => {
                let currentActive = GlobalStateBridge.getState().activeIndex
                let matchesIndex = currentActive == targetIndex

                if matchesIndex && !isAnticipatory {
                  performSwapAndCheck(targetScene)
                } else {
                  state.isSceneLoading = false
                  state.loadingSceneId = Nullable.null

                  let latest = GlobalStateBridge.getState()
                  switch Belt.Array.get(latest.scenes, latest.activeIndex) {
                  | Some(latSc) =>
                    if latSc.id != targetScene.id {
                      loadNewScene(Some(targetScene.id), None)
                    }
                  | None => ()
                  }
                }
              }

              if GlobalStateBridge.getState().simulation.status == Running {
                // Reduced from 3 frames to 1 frame to speed up AutoPilot transitions
                // while still allowing a basic pass for texture stabilization
                let frameCount = ref(0)
                let rec waitForDeepRender = () => {
                  frameCount := frameCount.contents + 1
                  if frameCount.contents < 1 {
                    let _ = Window.requestAnimationFrame(waitForDeepRender)
                  } else {
                    checkReadyAndSwap()
                  }
                }
                let _ = Window.requestAnimationFrame(waitForDeepRender)
              } else {
                checkReadyAndSwap()
              }
            }
          })

          Viewer.on(newViewer, "error", err => {
            state.isSceneLoading = false
            state.loadingSceneId = Nullable.null
            let errMsg = castToString(err)
            Logger.error(
              ~module_="Viewer",
              ~message="PANNELLUM_ERROR",
              ~data=Some({"sceneName": targetScene.name, "error": errMsg}),
              (),
            )
          })
        }
      }
    | None => ()
    }
    Promise.resolve()
  })
}
