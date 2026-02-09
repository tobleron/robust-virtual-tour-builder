/* src/systems/Scene/SceneLoader.res */

open Types
open Actions

let castToString: 'a => string = %raw("(x) => typeof x === 'string' ? x : ''")
let castToDict: 'a => dict<string> = %raw("(x) => (typeof x === 'object' && x !== null) ? x : {}")
external asDynamic: 'a => {..} = "%identity"
external boolToUnknown: bool => unknown = "%identity"
external idToUnknown: string => unknown = "%identity"
@val external setTimeout: (unit => unit, int) => timeoutId = "setTimeout"
@val external clearTimeout: timeoutId => unit = "clearTimeout"

let loadStartTime = ref(0.0)

module Config = {
  let getHotspots = (scene: scene) =>
    scene.hotspots->Belt.Array.mapWithIndex((idx, h) => {
      let pitch = h.displayPitch->Option.getOr(h.pitch)
      {
        "id": "hs_" ++ Belt.Int.toString(idx),
        "pitch": pitch,
        "yaw": h.yaw,
        "type": "info",
        "cssClass": "pnlm-hotspot flat-arrow arrow-gold",
        "createTooltipArgs": {
          "targetSceneId": h.target,
        },
      }
    })
  let makeSceneConfig = (scene: scene) => {
    let url = SceneCache.getSourceUrl(scene.id, scene.file)
    Logger.debug(
      ~module_="SceneLoader",
      ~message="PREPARING_SCENE_INNER",
      ~data={"id": scene.id, "url": url},
      (),
    )
    {
      "panorama": url,
      "hotSpots": getHotspots(scene),
    }
  }

  let makeInitialConfig = (scene: scene) => {
    let inner = makeSceneConfig(scene)
    {
      "default": {"firstScene": scene.id},
      "scenes": Dict.fromArray([(scene.id, inner)]),
      "autoLoad": true,
      "hfov": Constants.globalHfov,
      "minHfov": Constants.globalHfov,
      "maxHfov": Constants.globalHfov,
      "mouseZoom": false,
      "doubleClickZoom": false,
      "keyboardZoom": false,
      "showZoomCtrl": false,
    }
  }
}

module Reuse = {
  let findReusableInstance = (targetIdx: int): option<ViewerSystem.Adapter.t> => {
    let targetSceneId = GlobalStateBridge.getState().scenes[targetIdx]->Option.map(s => s.id)
    ViewerSystem.Pool.pool.contents
    ->Belt.Array.getBy(v => {
      v.instance
      ->Option.map(inst => {
        let metaId = ViewerSystem.Adapter.getMetaData(inst, "sceneId")
        metaId == targetSceneId->Option.map(idToUnknown)
      })
      ->Option.getOr(false)
    })
    ->Option.flatMap(v => v.instance)
  }
}

module Events = {
  let onSceneLoad = (v, loadedScene: scene) => {
    let vId = castToDict(v)->Dict.get("container")->Option.getOr("")
    let entry = ViewerSystem.Pool.pool.contents->Belt.Array.getBy(e => e.containerId == vId)
    entry->Option.forEach(e => {
      e.instance->Option.forEach(inst => {
        ViewerSystem.Adapter.setMetaData(inst, "isLoaded", boolToUnknown(true))
        ViewerSystem.Adapter.setMetaData(inst, "sceneId", idToUnknown(loadedScene.id))
      })
    })
    ViewerSystem.Pool.setCleanupTimeout(vId, None)
    GlobalStateBridge.dispatch(
      DispatchNavigationFsmEvent(TextureLoaded({targetSceneId: loadedScene.id})),
    )
  }
  let onSceneError = (msg, targetSceneId) => {
    Logger.error(
      ~module_="SceneLoader",
      ~message="LOAD_ERROR",
      ~data={"error": msg, "targetId": targetSceneId},
      (),
    )
    TransitionLock.releaseIf("SceneLoader_Error", p => {
      switch p {
      | Loading(id) => id == targetSceneId
      | _ => false
      }
    })
    NotificationManager.dispatch({
      id: "",
      importance: Error,
      context: Operation("scene_loader"),
      message: msg,
      details: None,
      action: None,
      duration: NotificationTypes.defaultTimeoutMs(Error),
      dismissible: true,
      createdAt: Date.now(),
    })
    GlobalStateBridge.dispatch(DispatchNavigationFsmEvent(LoadTimeout))
  }
}

let retryScheduled: ref<option<timeoutId>> = ref(None)

let rec loadNewScene = (
  ~sourceSceneId as _sourceSceneId: option<string>=?,
  ~targetSceneId: string,
  ~isAnticipatory=false,
) => {
  let canProceed = if isAnticipatory {
    Ok()
  } else {
    let result = TransitionLock.acquire("SceneLoader", Loading(targetSceneId))
    switch result {
    | Error(_) =>
      // Pre-emption logic: if the lock is held by a different LOADING phase, we can override it
      // because the FSM has moved on to a new target.
      switch TransitionLock.current.contents {
      | Loading(otherId) if otherId != targetSceneId =>
        Logger.info(
          ~module_="SceneLoader",
          ~message="PREEMPTING_OBSOLETE_LOADING_LOCK",
          ~data=Some({"oldTarget": otherId, "newTarget": targetSceneId}),
          (),
        )
        TransitionLock.preempt("SceneLoader")
        TransitionLock.acquire("SceneLoader", Loading(targetSceneId))
      | Cleanup(_) =>
        Logger.info(
          ~module_="SceneLoader",
          ~message="PREEMPTING_CLEANUP_LOCK",
          ~data=Some({"newTarget": targetSceneId}),
          (),
        )
        TransitionLock.preempt("SceneLoader")
        TransitionLock.acquire("SceneLoader", Loading(targetSceneId))
      | _ => result
      }
    | Ok() => result
    }
  }

  switch canProceed {
  | Error(_msg) =>
    if !isAnticipatory {
      // Log at DEBUG level - acquire failure is expected when lock is held
      // (not a warning condition, just normal during rapid scene clicks)
      Logger.debug(
        ~module_="SceneLoader",
        ~message="LOCK_ACQUIRE_FAILED_RETRY_SCHEDULED",
        ~data=Some({
          "targetId": targetSceneId,
        }),
        (),
      )
      // Schedule a retry after 100ms to allow previous operation to finish
      switch retryScheduled.contents {
      | Some(id) => clearTimeout(id)
      | None => ()
      }
      let retryId = setTimeout(() => {
        retryScheduled := None
        let state = GlobalStateBridge.getState()
        let isRelevant = switch state.navigationFsm {
        | Preloading({targetSceneId: activeTarget}) => activeTarget == targetSceneId
        | _ => false
        }

        if isRelevant {
          loadNewScene(~targetSceneId, ~isAnticipatory)
        } else {
          Logger.debug(
            ~module_="SceneLoader",
            ~message="ABORTING_OBSOLETE_RETRY",
            ~data=Some({"targetId": targetSceneId}),
            (),
          )
        }
      }, 100)
      retryScheduled := Some(retryId)
    }
  | Ok() =>
    let state = GlobalStateBridge.getState()
    let targetSceneOpt = state.scenes->Belt.Array.getBy(s => s.id == targetSceneId)

    switch targetSceneOpt {
    | None =>
      if !isAnticipatory {
        Logger.warn(
          ~module_="SceneLoader",
          ~message="TARGET_SCENE_NOT_FOUND",
          ~data=Some({"targetId": targetSceneId}),
          (),
        )
        TransitionLock.release("SceneLoader_NotFound")
        GlobalStateBridge.dispatch(DispatchNavigationFsmEvent(Aborted))
      }
    | Some(targetScene) =>
      if !isAnticipatory {
        loadStartTime := Date.now()
        GlobalStateBridge.dispatch(
          DispatchNavigationFsmEvent(PreloadStarted({targetSceneId: targetScene.id})),
        )
      }

      let tIdx = state.scenes->Belt.Array.getIndexBy(s => s.id == targetSceneId)->Option.getOr(-1)

      switch if isAnticipatory {
        None
      } else {
        Reuse.findReusableInstance(tIdx)
      } {
      | Some(inst) =>
        if !isAnticipatory {
          ViewerSystem.Adapter.setMetaData(inst, "sceneId", idToUnknown(targetScene.id))
          let config = Config.makeSceneConfig(targetScene)

          Logger.debug(
            ~module_="SceneLoader",
            ~message="LOADING_SCENE_IN_REUSABLE_INSTANCE",
            ~data=Some({
              "targetSceneId": targetScene.id,
              "panorama": config["panorama"],
              "fileType": switch targetScene.file {
              | Url(_) => "Url"
              | Blob(_) => "Blob"
              | File(_) => "File"
              },
            }),
            (),
          )

          ViewerSystem.Adapter.addScene(inst, targetScene.id, config->asDynamic)
          ViewerSystem.Adapter.loadScene(inst, targetScene.id, ())
          GlobalStateBridge.dispatch(
            DispatchNavigationFsmEvent(TextureLoaded({targetSceneId: targetScene.id})),
          )
        }
      | None =>
        let activeVp = ViewerSystem.Pool.getActive()
        let inactiveVp = ViewerSystem.Pool.getInactive()

        let vp = switch activeVp {
        | Some(v) if v.instance == None => activeVp
        | _ => inactiveVp
        }

        vp->Option.forEach(v => {
          v.instance->Option.forEach(i => ViewerSystem.Adapter.destroy(i))

          // Safety timeout to prevent permanent hangs if Pannellum fails to fire events
          let safetyTimeoutId = setTimeout(() => {
            Logger.error(
              ~module_="SceneLoader",
              ~message="PANNELLUM_LOAD_TIMEOUT",
              ~data=Some({"scene": targetScene.id}),
              (),
            )
            Events.onSceneError("Resource load timeout (Safety)", targetScene.id)
          }, 60000)

          try {
            let initialConfig = Config.makeInitialConfig(targetScene)

            Logger.debug(
              ~module_="SceneLoader",
              ~message="INITIALIZING_VIEWER_INSTANCE",
              ~data=Some({
                "containerId": v.containerId,
                "targetSceneId": targetScene.id,
                "panorama": SceneCache.getSourceUrl(targetScene.id, targetScene.file),
                "fileType": switch targetScene.file {
                | Url(_) => "Url"
                | Blob(_) => "Blob"
                | File(_) => "File"
                },
              }),
              (),
            )

            let newInstance = ViewerSystem.Adapter.initialize(
              v.containerId,
              initialConfig->asDynamic,
            )
            ViewerSystem.Adapter.setMetaData(newInstance, "sceneId", idToUnknown(targetScene.id))
            ViewerSystem.Adapter.setMetaData(newInstance, "isLoaded", boolToUnknown(false))

            newInstance->ViewerSystem.Adapter.on("texture-loaded", _ => {
            clearTimeout(safetyTimeoutId)
              Events.onSceneLoad(newInstance, targetScene)
            })

            newInstance->ViewerSystem.Adapter.on("error", msg => {
            clearTimeout(safetyTimeoutId)
              Events.onSceneError(msg, targetScene.id)
            })

            if ViewerSystem.Adapter.isLoaded(newInstance) {
            clearTimeout(safetyTimeoutId)
              Events.onSceneLoad(newInstance, targetScene)
            }

            ViewerSystem.Pool.registerInstance(v.containerId, newInstance)

            Logger.info(
              ~module_="SceneLoader",
              ~message="VIEWER_INITIALIZED_SUCCESS",
              ~data=Some({
                "containerId": v.containerId,
                "targetSceneId": targetScene.id,
              }),
              (),
            )
          } catch {
          | exn =>
            clearTimeout(safetyTimeoutId)
            let (errMsg, errStack) = Logger.getErrorDetails(exn)
            Logger.error(
              ~module_="SceneLoader",
              ~message="VIEWER_INITIALIZATION_ERROR",
              ~data=Some({
                "containerId": v.containerId,
                "targetSceneId": targetScene.id,
                "error": errMsg,
                "stack": errStack,
              }),
              (),
            )
            Events.onSceneError("Failed to initialize viewer: " ++ errMsg, targetScene.id)
            TransitionLock.releaseIf("SceneLoader_InitError", p => {
              switch p {
              | Loading(id) => id == targetScene.id
              | _ => false
              }
            })
          }
        })
      }
    }
  }
}
