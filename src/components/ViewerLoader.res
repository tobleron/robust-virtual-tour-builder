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
  UrlUtils.fileToUrl(file)
}

module Loader = {
  let loadStartTime = ref(0.0)

  type customViewerProps = {
    @as("_sceneId") mutable sceneId: string,
    @as("_isLoaded") mutable isLoaded: bool,
  }
  external asCustom: ReBindings.Viewer.t => customViewerProps = "%identity"

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

    // CRITICAL: Set swap lock FIRST to prevent render loop from drawing during swap
    // This prevents race condition where render loop uses mismatched viewer/state
    state.isSwapping = true

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

    // Clear SVG overlay immediately before swap to prevent stale arrows
    // This prevents arrows calculated from old viewer camera data from appearing
    let svgOpt = Dom.getElementById("viewer-hotspot-lines")
    switch Nullable.toOption(svgOpt) {
    | Some(svg) => Dom.setTextContent(svg, "")
    | None => ()
    }

    // Delay hotspot line update to ensure new viewer is fully stable
    // This prevents race condition where camera values are read before initialization
    let _ = Window.setTimeout(() => {
      let vOpt = getActiveViewer()
      switch Nullable.toOption(vOpt) {
      | Some(v) =>
        // Only update if viewer is valid AND active (proper camera data)
        if HotspotLine.isViewerReady(v) {
          let mouseEv = switch Nullable.toOption(state.lastMouseEvent) {
          | Some(e) => Some(e)
          | None => None
          }
          HotspotLine.updateLines(v, GlobalStateBridge.getState(), ~mouseEvent=?mouseEv, ())
        }

        // Release swap lock after viewer is ready and lines are updated
        state.isSwapping = false
      | None =>
        // Release lock even if viewer is not available
        state.isSwapping = false
      }
    }, 50)

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

    switch Nullable.toOption(snapshot) {
    | Some(s) =>
      // Unified smooth fade-out for snapshots in all modes
      Dom.remove(s, "snapshot-visible")
      let _ = Window.setTimeout(() => {
        if !(Dom.classList(s)->Dom.ClassList.contains("snapshot-visible")) {
          Dom.setBackgroundImage(s, "none")
        }
      }, 450)
    | None => ()
    }

    // Enable snapshot capture during simulation to provide visual continuity for subsequent jumps
    ViewerSnapshot.requestIdleSnapshot()

    state.isSceneLoading = false
    state.loadingSceneId = Nullable.null
    state.lastSceneId = Nullable.make(loadedScene.id)

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
          let vDyn = asCustom(v)
          let vid = vDyn.sceneId
          if vid == targetScene.id {
            if vDyn.isLoaded {
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
            let initialHfov =
              Constants.backendUrl == "" ? Constants.globalHfov : Constants.globalHfov

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
            asCustom(newViewer).sceneId = targetScene.id
            asCustom(newViewer).isLoaded = false

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
                asCustom(newViewer).isLoaded = true

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

            /* Capture the assigned key to check against active key later */
            let assignedKey = switch state.activeViewerKey {
            | A => B
            | B => A
            }

            let isRafPending = ref(false)
            Viewer.on(newViewer, "viewchange", _ => {
              /* CRITICAL: Skip updates during swap AND verify viewer is ready
               * This prevents the "ghost arrow" artifact at (0,0) which occurs when:
               * 1. viewchange fires before the new viewer's camera is fully initialized
               * 2. viewchange fires during the swap transition when state is inconsistent
               */
              if assignedKey == state.activeViewerKey && !state.isSwapping {
                if !isRafPending.contents {
                  isRafPending := true
                  let _ = Window.requestAnimationFrame(
                    () => {
                      isRafPending := false

                      // Verify viewer is still active and swapping hasn't started since RAF was requested
                      if assignedKey == state.activeViewerKey && !state.isSwapping {
                        if HotspotLine.isViewerReady(newViewer) {
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
                      }
                    },
                  )
                }
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
