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

let toPathRequest = (state: state): pathRequest => {
  {
    type_: "navigation",
    scenes: state.scenes,
    skipAutoForward: state.simulation.skipAutoForwardGlobal,
    timeline: Some(state.timeline),
  }
}

module Reuse = {
  let findReusableInstance = (pathRequest, targetIdx: int): option<ViewerSystem.Adapter.t> => {
    let targetSceneId = pathRequest.scenes[targetIdx]->Option.map(s => s.id)
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
  let isStaleTask = (
    ~taskId: option<string>=?,
    ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ) => {
    let taskMismatch = switch taskId {
    | Some(tid) => !NavigationSupervisor.isCurrentTaskId(tid)
    | None => false
    }
    let signalAborted = switch signal {
    | Some(s) => BrowserBindings.AbortSignal.aborted(s)
    | None => false
    }
    taskMismatch || signalAborted
  }

  let onSceneLoad = (
    ~dispatch,
    v,
    loadedScene: scene,
    ~taskId: option<string>=?,
    ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ) => {
    if isStaleTask(~taskId?, ~signal?) {
      Logger.debug(
        ~module_="SceneLoader",
        ~message="STALE_SCENE_LOAD_IGNORED",
        ~data=Some({"sceneId": loadedScene.id, "taskId": taskId->Option.getOr("none")}),
        (),
      )
      ()
    } else {
      let vId = castToDict(v)->Dict.get("container")->Option.getOr("")
      let entry = ViewerSystem.Pool.pool.contents->Belt.Array.getBy(e => e.containerId == vId)
      entry->Option.forEach(e => {
        e.instance->Option.forEach(inst => {
          ViewerSystem.Adapter.setMetaData(inst, "isLoaded", boolToUnknown(true))
          ViewerSystem.Adapter.setMetaData(inst, "sceneId", idToUnknown(loadedScene.id))
        })
      })
      ViewerSystem.Pool.setCleanupTimeout(vId, None)

      switch taskId {
      | Some(tid) => NavigationSupervisor.transitionTo(tid, Swapping(tid, loadedScene.id))
      | None => ()
      }

      dispatch(DispatchNavigationFsmEvent(TextureLoaded({targetSceneId: loadedScene.id})))
    }
  }
  let onSceneError = (
    ~dispatch,
    msg,
    targetSceneId,
    ~taskId: option<string>=?,
    ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ) => {
    if isStaleTask(~taskId?, ~signal?) {
      Logger.debug(
        ~module_="SceneLoader",
        ~message="STALE_SCENE_ERROR_IGNORED",
        ~data=Some({"targetId": targetSceneId, "taskId": taskId->Option.getOr("none")}),
        (),
      )
      ()
    } else {
      Logger.error(
        ~module_="SceneLoader",
        ~message="LOAD_ERROR",
        ~data={"error": msg, "targetId": targetSceneId},
        (),
      )

      switch taskId {
      | Some(tid) => NavigationSupervisor.abort(tid)
      | None => ()
      }

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
      dispatch(DispatchNavigationFsmEvent(LoadTimeout))
    }
  }
}

let currentLoadTimeout: ref<option<timeoutId>> = ref(None)

let cleanupLoadTimeout = () => {
  switch currentLoadTimeout.contents {
  | Some(id) =>
    clearTimeout(id)
    currentLoadTimeout := None
  | None => ()
  }
}

let loadNewScene = (
  ~state: pathRequest,
  ~dispatch,
  ~sourceSceneId as _sourceSceneId: option<string>=?,
  ~targetSceneId: string,
  ~isAnticipatory=false,
  ~taskId: option<string>=?,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
) => {
  // Update Supervisor status if taskId is provided (Supervisor mode)
  if !isAnticipatory {
    switch taskId {
    | Some(tid) => NavigationSupervisor.transitionTo(tid, Loading(tid, targetSceneId))
    | None => ()
    }
  }

  cleanupLoadTimeout()
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
      switch taskId {
      | Some(tid) => NavigationSupervisor.abort(tid)
      | None => ()
      }
      dispatch(DispatchNavigationFsmEvent(Aborted))
    }
  | Some(targetScene) =>
    if !isAnticipatory {
      loadStartTime := Date.now()
      dispatch(DispatchNavigationFsmEvent(PreloadStarted({targetSceneId: targetScene.id})))
    }

    let tIdx = state.scenes->Belt.Array.getIndexBy(s => s.id == targetSceneId)->Option.getOr(-1)

    switch if isAnticipatory {
      None
    } else {
      Reuse.findReusableInstance(state, tIdx)
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

        switch taskId {
        | Some(tid) => NavigationSupervisor.transitionTo(tid, Swapping(tid, targetScene.id))
        | None => ()
        }

        dispatch(DispatchNavigationFsmEvent(TextureLoaded({targetSceneId: targetScene.id})))
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
          if Events.isStaleTask(~taskId?, ~signal?) {
            currentLoadTimeout := None
          } else {
            currentLoadTimeout := None
            Logger.error(
              ~module_="SceneLoader",
              ~message="PANNELLUM_LOAD_TIMEOUT",
              ~data=Some({"scene": targetScene.id}),
              (),
            )
            Events.onSceneError(
              ~dispatch,
              "Resource load timeout (Safety)",
              targetScene.id,
              ~taskId?,
              ~signal?,
            )
          }
        }, 60000)
        currentLoadTimeout := Some(safetyTimeoutId)

        // Before creating a new Pannellum viewer instance (the expensive operation):
        let isAborted = switch signal {
        | Some(s) if BrowserBindings.AbortSignal.aborted(s) => true
        | _ => false
        }

        if isAborted {
          Logger.info(~module_="SceneLoader", ~message="LOAD_ABORTED_BEFORE_VIEWER_CREATION", ())
          clearTimeout(safetyTimeoutId)
          currentLoadTimeout := None
          switch taskId {
          | Some(tid) => NavigationSupervisor.abort(tid)
          | None => ()
          }
        } else {
          try {
            let initialConfig = Config.makeInitialConfig(targetScene)

            Logger.info(
              ~module_="SceneLoader",
              ~message="INITIALIZING_VIEWER_INSTANCE",
              ~data=Some({
                "containerId": v.containerId,
                "targetSceneId": targetScene.id,
                "panorama": SceneCache.getSourceUrl(targetScene.id, targetScene.file),
                "fileType": switch targetScene.file {
                | Url(_) => "Url"
                | Blob(b) => "Blob(" ++ Float.toString(ReBindings.Blob.size(b)) ++ ")"
                | File(f) => "File(" ++ Float.toString(ReBindings.File.size(f)) ++ ")"
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
              cleanupLoadTimeout()
              Events.onSceneLoad(~dispatch, newInstance, targetScene, ~taskId?, ~signal?)
            })

            newInstance->ViewerSystem.Adapter.on("load", _ => {
              cleanupLoadTimeout()
              Events.onSceneLoad(~dispatch, newInstance, targetScene, ~taskId?, ~signal?)
            })

            newInstance->ViewerSystem.Adapter.on("error", msg => {
              cleanupLoadTimeout()
              Events.onSceneError(~dispatch, msg, targetScene.id, ~taskId?, ~signal?)
            })

            if ViewerSystem.Adapter.isLoaded(newInstance) {
              cleanupLoadTimeout()
              Events.onSceneLoad(~dispatch, newInstance, targetScene, ~taskId?, ~signal?)
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
            Events.onSceneError(
              ~dispatch,
              "Failed to initialize viewer: " ++ errMsg,
              targetScene.id,
              ~taskId?,
              ~signal?,
            )
            switch taskId {
            | Some(tid) => NavigationSupervisor.abort(tid)
            | None => ()
            }
          }
        }
      })
    }
  }
}
