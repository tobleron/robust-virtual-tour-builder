/* src/systems/Scene/SceneLoader.res */

open Types
open Actions

// --- TYPES & HELPERS ---

let castToString: 'a => string = %raw("(x) => typeof x === 'string' ? x : ''")
let castToDict: 'a => dict<string> = %raw("(x) => (typeof x === 'object' && x !== null) ? x : {}")
external asDynamic: 'a => {..} = "%identity"
external boolToUnknown: bool => unknown = "%identity"
external idToUnknown: string => unknown = "%identity"
@val external setTimeout: (unit => unit, int) => timeoutId = "setTimeout"
@val external clearTimeout: timeoutId => unit = "clearTimeout"

let loadStartTime = ref(0.0)

// --- SUBMODULES (Compatibility) ---

let blankPanorama = SceneLoaderLogic.blankPanorama
let backgroundViewerConfig = SceneLoaderLogic.backgroundViewerConfig

let ensureBackgroundViewer = (~_state: state, ~_dispatch) => {
  ViewerSystem.Pool.getInactive()->Option.forEach(vp => {
    switch vp.instance {
    | Some(_) => ()
    | None =>
      let instance = ViewerSystem.Adapter.initialize(
        vp.containerId,
        backgroundViewerConfig()->asDynamic,
      )
      ViewerSystem.Adapter.setMetaData(instance, "sceneId", idToUnknown(""))
      ViewerSystem.Adapter.setMetaData(instance, "isLoaded", boolToUnknown(false))
      ViewerSystem.Pool.registerInstance(vp.containerId, instance)
    }
  })
}

let toPathRequest = (state: state): pathRequest => {
  {
    type_: "navigation",
    scenes: SceneInventory.getActiveScenes(state.inventory, state.sceneOrder),
    skipAutoForward: state.simulation.skipAutoForwardGlobal,
    timeline: Some(state.timeline),
  }
}

module Reuse = {
  let findReusableInstance = (pathRequest, targetIdx) =>
    SceneLoaderLogic.findReusableInstance(pathRequest, targetIdx)
}

module Events = {
  let onSceneLoad = SceneLoaderLogic.onSceneLoad
  let onSceneError = SceneLoaderLogic.onSceneError
  let isStaleTask = SceneLoaderLogic.isStaleTask
}

// --- MAIN LOGIC ---

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
  ~state: state,
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
  let scenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
  let targetSceneOpt = scenes->Belt.Array.getBy(s => s.id == targetSceneId)

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

    let tIdx = scenes->Belt.Array.getIndexBy(s => s.id == targetSceneId)->Option.getOr(-1)

    switch if isAnticipatory {
      None
    } else {
      Reuse.findReusableInstance(toPathRequest(state), tIdx)
    } {
    | Some(inst) =>
      if !isAnticipatory {
        ViewerSystem.Adapter.setMetaData(inst, "sceneId", idToUnknown(targetScene.id))
        ViewerSystem.Adapter.setMetaData(inst, "isLoaded", boolToUnknown(false))
        let config = SceneLoaderLogic.makeSceneConfig(targetScene, ~state, ~dispatch)

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

        // Safety timeout for reuse path
        let safetyTimeoutId = setTimeout(() => {
          if !Events.isStaleTask(~taskId?, ~signal?) {
            Logger.warn(
              ~module_="SceneLoader",
              ~message="REUSE_LOAD_TIMEOUT",
              ~data=Some({"scene": targetScene.id}),
              (),
            )
            Events.onSceneLoad(~dispatch, inst, targetScene, ~taskId?, ~signal?)
          }
        }, 10000)

        inst->ViewerSystem.Adapter.on("texture-loaded", _ => {
          clearTimeout(safetyTimeoutId)
          Events.onSceneLoad(~dispatch, inst, targetScene, ~taskId?, ~signal?)
        })

        inst->ViewerSystem.Adapter.on("load", _ => {
          clearTimeout(safetyTimeoutId)
          Events.onSceneLoad(~dispatch, inst, targetScene, ~taskId?, ~signal?)
        })

        ViewerSystem.Adapter.addScene(inst, targetScene.id, config->asDynamic)
        ViewerSystem.Adapter.loadScene(inst, targetScene.id, ())

        switch taskId {
        | Some(tid) => NavigationSupervisor.transitionTo(tid, Swapping(tid, targetScene.id))
        | None => ()
        }
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
            let initialConfig = SceneLoaderLogic.makeInitialConfig(targetScene, ~state, ~dispatch)

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
            ensureBackgroundViewer(~_state=state, ~_dispatch=dispatch)
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
