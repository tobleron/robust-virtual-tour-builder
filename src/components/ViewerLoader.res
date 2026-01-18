open ReBindings
open ViewerTypes
open ViewerState

external castToString: 'a => string = "%identity"
external castToBlob: 'a => Blob.t = "%identity"
external castToDict: 'a => dict<'b> = "%identity"
external asDynamic: 'a => {..} = "%identity"

let getComputedOpacity = el => {
  switch Nullable.toOption(el) {
  | Some(e) =>
    let style = Window.getComputedStyle(e)
    Float.parseFloat(Dom.getPropertyValue(style, "opacity"))
  | None => 1.0
  }
}

let getPanoramaUrl = (file: Types.file): string => {
  switch file {
  | Url(s) => s
  | Blob(b) =>
    let isBlob: bool = %raw("b instanceof Blob")
    if isBlob {
      let url = URL.createObjectURL(b)
      Logger.debug(
        ~module_="Viewer",
        ~message="GENERATING_BLOB_URL",
        ~data=Some({"size": Blob.size(b), "type": Blob.type_(b), "url": url}),
        (),
      )
      url
    } else {
      let type_ = %raw("typeof b")
      Logger.error(~module_="Viewer", ~message="INVALID_BLOB_TYPE", ~data=Some({"type": type_}), ())
      ""
    }
  | File(b) =>
    let isFile: bool = %raw("b instanceof File || b instanceof Blob")
    if isFile {
      let url = URL.createObjectURL(castToBlob(b))
      Logger.debug(
        ~module_="Viewer",
        ~message="GENERATING_FILE_URL",
        ~data=Some({"size": File.size(b), "type": File.type_(b), "url": url}),
        (),
      )
      url
    } else {
      let type_ = %raw("typeof b")
      Logger.error(~module_="Viewer", ~message="INVALID_FILE_TYPE", ~data=Some({"type": type_}), ())
      ""
    }
  }
}

module Loader = {
  let loadStartTime = ref(0.0)

  let initializeViewer = (containerId: string, config: {..}) => {
    Pannellum.viewer(containerId, config)
  }

  let destroyViewer = (v: ReBindings.Viewer.t) => {
    try {
      Viewer.destroy(v)
    } catch {
    | _ => ()
    }
  }

  let rec performSwap = (loadedScene: Types.scene) => {
    let _swapStartTime = Date.now()
    let inactiveKey = switch state.activeViewerKey {
    | A => B
    | B => A
    }
    let activeContainerId = getActiveContainerId()
    let inactiveContainerId = getInactiveContainerId()

    let activeEl = Dom.getElementById(activeContainerId)
    let inactiveEl = Dom.getElementById(inactiveContainerId)

    let oldViewer = getActiveViewer()
    let newViewer = getInactiveViewer()

    state.activeViewerKey = inactiveKey

    let assignGlobal: Nullable.t<ReBindings.Viewer.t> => unit = %raw(
      "(v) => window.pannellumViewer = v"
    )
    assignGlobal(newViewer)

    let vOpt = getActiveViewer()
    switch Nullable.toOption(vOpt) {
    | Some(v) =>
      let mouseEv = switch Nullable.toOption(state.lastMouseEvent) {
      | Some(e) => Some(e)
      | None => None
      }
      HotspotLine.updateLines(v, GlobalStateBridge.getState(), ~mouseEvent=?mouseEv, ())
      let _ = Window.setTimeout(() => {
        HotspotLine.updateLines(v, GlobalStateBridge.getState(), ())
      }, 0)
    | None => ()
    }

    /* Transition */
    let isCut = switch GlobalStateBridge.getState().transition.type_ {
    | Some("cut") => true
    | _ => false
    }

    switch (Nullable.toOption(activeEl), Nullable.toOption(inactiveEl)) {
    | (Some(act), Some(inact)) =>
      if isCut {
        Dom.setTransition(act, "none")
        Dom.setTransition(inact, "none")
      } else {
        Dom.setTransition(act, "")
        Dom.setTransition(inact, "")
      }

      Dom.remove(act, "active")
      Dom.add(inact, "active")

      if isCut {
        let _ = Window.setTimeout(() => {
          Dom.setTransition(act, "")
          Dom.setTransition(inact, "")
        }, 50)
      }
    | _ => ()
    }

    /* Cleanup old viewer */
    let _ = Window.setTimeout(() => {
      switch Nullable.toOption(oldViewer) {
      | Some(v) =>
        destroyViewer(v)
        switch state.activeViewerKey {
        | B => state.viewerA = Nullable.null
        | A => state.viewerB = Nullable.null
        }
      | None => ()
      }
    }, 500)

    /* Snapshot */
    let snapshot = Dom.getElementById("viewer-snapshot-overlay")
    let isSim = GlobalStateBridge.getState().isSimulationMode

    switch Nullable.toOption(snapshot) {
    | Some(s) =>
      if !isSim {
        Dom.remove(s, "snapshot-visible")
        let _ = Window.setTimeout(() => {
          if !(Dom.classList(s)->Dom.ClassList.contains("snapshot-visible")) {
            Dom.setBackgroundImage(s, "none")
          }
        }, 450)
      } else {
        Dom.remove(s, "snapshot-visible")
        Dom.setBackgroundImage(s, "none")
      }
    | None => ()
    }

    if !isSim {
      ViewerSnapshot.requestIdleSnapshot()
    }

    state.isSceneLoading = false
    state.loadingSceneId = Nullable.null

    /* Recovery Check */
    let latestState = GlobalStateBridge.getState()
    switch Belt.Array.get(latestState.scenes, latestState.activeIndex) {
    | Some(latestActiveScene) =>
      if latestActiveScene.id != loadedScene.id {
        Logger.warn(
          ~module_="Viewer",
          ~message="LOAD_INTERRUPTED",
          ~data=Some({
            "originalScene": loadedScene.name,
            "currentScene": latestActiveScene.name,
            "action": "triggering recovery",
          }),
          (),
        )
        loadNewScene(Some(loadedScene.id), None)
      }
    | None => ()
    }

    Logger.endOperation(
      ~module_="Viewer",
      ~operation="SCENE_LOAD",
      ~data=Some({
        "sceneName": loadedScene.name,
        "durationMs": Date.now() -. loadStartTime.contents,
      }),
      (),
    )
  }

  and loadNewScene = (
    capturedPrevSceneId: option<string>,
    anticipatoryTargetIndex: option<int>,
  ) => {
    let _ = LazyLoad.loadPannellum()->Promise.then(() => {
      let isAnticipatory = Belt.Option.isSome(anticipatoryTargetIndex)
      let targetIndex = switch anticipatoryTargetIndex {
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
        let _inactiveKey = switch state.activeViewerKey {
        | A => B
        | B => A
        }
        let inactiveViewer = getInactiveViewer()
        let containerId = getInactiveContainerId()

        /* Reuse Check */
        let shouldReuse = switch Nullable.toOption(inactiveViewer) {
        | Some(v) =>
          let vDyn = asDynamic(v)
          let vid: string = vDyn["_sceneId"]
          if vid == targetScene.id {
            if vDyn["_isLoaded"] {
              if GlobalStateBridge.getState().activeIndex == targetIndex && !isAnticipatory {
                performSwap(targetScene)
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

        if !shouldReuse {
          if state.isSceneLoading && !isAnticipatory {
            Logger.debug(
              ~module_="Viewer",
              ~message="LOAD_QUEUED",
              ~data=Some({"sceneName": targetScene.name}),
              (),
            )
          } else {
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
                switch ps.preCalculatedSnapshot {
                | Some(url) =>
                  let isCut = switch GlobalStateBridge.getState().transition.type_ {
                  | Some("cut") => true
                  | _ => false
                  }
                  if !isCut {
                    Dom.setBackgroundImage(snapEl, "url(" ++ url ++ ")")
                    Dom.add(snapEl, "snapshot-visible")
                  }
                  ps.preCalculatedSnapshot = None
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
              !currentGlobalState.isSimulationMode &&
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
            let initialHfov =
              Constants.backendUrl == "" ? Constants.globalHfov : Constants.globalHfov

            let hotspotsArr = Belt.Array.mapWithIndex(targetScene.hotspots, (i, h) => {
              HotspotManager.createHotspotConfig(
                ~hotspot=h,
                ~index=i,
                ~state=currentGlobalState,
                ~scene=targetScene,
                ~dispatch=GlobalStateBridge.dispatch,
              )
            })

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
                  "friction": 0.05,
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
                  "friction": 0.05,
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
            let newViewer = initializeViewer(containerId, viewerConfig)
            asDynamic(newViewer)["_sceneId"] = targetScene.id
            asDynamic(newViewer)["_isLoaded"] = false

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
                /* Preload master logic - simplified for migration: rely on pannellum loading master next if implicit?
                 No, JS code manually preloads Image and then calls loadScene. */

                /* Simplified: just load master immediately or implement Image preload */
                /* Implementing Image preload using %raw or bindings is tricky quickly. */
                /* I'll trigger loadScene directly which handles it internally in Pannellum usually? 
                      No, Pannellum doesn't auto upgrade.
                      User JS code: new Image(), onload -> newViewer.loadScene('master', ...) */

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
                asDynamic(newViewer)["_isLoaded"] = true
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
                    performSwap(targetScene)
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

                if GlobalStateBridge.getState().isSimulationMode {
                  let frameCount = ref(0)
                  let rec waitForDeepRender = () => {
                    frameCount := frameCount.contents + 1
                    if frameCount.contents < 3 {
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

            /* More events: animatefinished, viewchange */
            /* Capture the assigned key to check against active key later */
            let assignedKey = switch state.activeViewerKey {
            | A => B
            | B => A
            }

            Viewer.on(newViewer, "viewchange", _ => {
              /* If this viewer corresponds to the currently active key, update lines */
              if assignedKey == state.activeViewerKey {
                let mouseEv = switch Nullable.toOption(state.lastMouseEvent) {
                | Some(e) => Some(e)
                | None => None
                }
                HotspotLine.updateLines(
                  newViewer,
                  GlobalStateBridge.getState(),
                  ~mouseEvent=?mouseEv,
                  (),
                )
              }
            })
          }
        }
      | None => ()
      }
      Promise.resolve()
    })
  }
}
