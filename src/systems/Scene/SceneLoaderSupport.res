// @efficiency-role: service-orchestrator

open Types
open Actions

type viewport = ViewerSystem.Pool.viewport

external asDynamic: 'a => {..} = "%identity"
external boolToUnknown: bool => unknown = "%identity"
external idToUnknown: string => unknown = "%identity"
@val external setTimeout: (unit => unit, int) => timeoutId = "setTimeout"
@val external clearTimeout: timeoutId => unit = "clearTimeout"

let reportTargetNotFound = (~dispatch, ~taskId: option<string>, ~targetSceneId: string) => {
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

let attachReusableLoadListeners = (~inst, ~safetyTimeoutId, ~onReady: unit => unit) => {
  let settle = () => {
    clearTimeout(safetyTimeoutId)
    onReady()
  }

  inst->ViewerSystem.Adapter.on("texture-loaded", _ => settle())
  inst->ViewerSystem.Adapter.on("load", _ => settle())
}

let loadReusableScene = (
  ~inst,
  ~targetScene: scene,
  ~state: state,
  ~dispatch,
  ~taskId: option<string>,
  ~signal: option<BrowserBindings.AbortSignal.t>,
) => {
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

  let safetyTimeoutId = setTimeout(() => {
    if !SceneLoaderLogic.isStaleTask(~taskId?, ~signal?) {
      Logger.warn(
        ~module_="SceneLoader",
        ~message="REUSE_LOAD_TIMEOUT",
        ~data=Some({"scene": targetScene.id}),
        (),
      )
      SceneLoaderLogic.onSceneLoad(~dispatch, inst, targetScene, ~taskId?, ~signal?)
    }
  }, 10000)

  attachReusableLoadListeners(~inst, ~safetyTimeoutId, ~onReady=() =>
    SceneLoaderLogic.onSceneLoad(~dispatch, inst, targetScene, ~taskId?, ~signal?)
  )

  ViewerSystem.Adapter.addScene(inst, targetScene.id, config->asDynamic)
  ViewerSystem.Adapter.loadScene(inst, targetScene.id, ())

  switch taskId {
  | Some(tid) => NavigationSupervisor.transitionTo(tid, Swapping(tid, targetScene.id))
  | None => ()
  }
}

let loadFreshScene = (
  ~viewport: viewport,
  ~targetScene: scene,
  ~state: state,
  ~dispatch,
  ~taskId: option<string>,
  ~signal: option<BrowserBindings.AbortSignal.t>,
  ~setCurrentLoadTimeout: option<timeoutId> => unit,
  ~cleanupLoadTimeout: unit => unit,
  ~ensureBackgroundViewer: unit => unit,
) => {
  viewport.instance->Option.forEach(i => ViewerSystem.Adapter.destroy(i))

  let safetyTimeoutId = setTimeout(() => {
    if SceneLoaderLogic.isStaleTask(~taskId?, ~signal?) {
      setCurrentLoadTimeout(None)
    } else {
      setCurrentLoadTimeout(None)
      Logger.error(
        ~module_="SceneLoader",
        ~message="PANNELLUM_LOAD_TIMEOUT",
        ~data=Some({"scene": targetScene.id}),
        (),
      )
      SceneLoaderLogic.onSceneError(
        ~dispatch,
        "Resource load timeout (Safety)",
        targetScene.id,
        ~taskId?,
        ~signal?,
      )
    }
  }, 60000)
  setCurrentLoadTimeout(Some(safetyTimeoutId))

  let isAborted = switch signal {
  | Some(s) if BrowserBindings.AbortSignal.aborted(s) => true
  | _ => false
  }

  if isAborted {
    Logger.debug(~module_="SceneLoader", ~message="LOAD_ABORTED_BEFORE_VIEWER_CREATION", ())
    clearTimeout(safetyTimeoutId)
    setCurrentLoadTimeout(None)
    switch taskId {
    | Some(tid) => NavigationSupervisor.abort(tid)
    | None => ()
    }
  } else {
    try {
      let initialConfig = SceneLoaderLogic.makeInitialConfig(targetScene, ~state, ~dispatch)

      Logger.debug(
        ~module_="SceneLoader",
        ~message="INITIALIZING_VIEWER_INSTANCE",
        ~data=Some({
          "containerId": viewport.containerId,
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
        viewport.containerId,
        initialConfig->asDynamic,
      )
      ViewerSystem.Adapter.setMetaData(newInstance, "sceneId", idToUnknown(targetScene.id))
      ViewerSystem.Adapter.setMetaData(newInstance, "isLoaded", boolToUnknown(false))

      newInstance->ViewerSystem.Adapter.on("texture-loaded", _ => {
        cleanupLoadTimeout()
        SceneLoaderLogic.onSceneLoad(~dispatch, newInstance, targetScene, ~taskId?, ~signal?)
      })

      newInstance->ViewerSystem.Adapter.on("load", _ => {
        cleanupLoadTimeout()
        SceneLoaderLogic.onSceneLoad(~dispatch, newInstance, targetScene, ~taskId?, ~signal?)
      })

      newInstance->ViewerSystem.Adapter.on("error", msg => {
        cleanupLoadTimeout()
        SceneLoaderLogic.onSceneError(~dispatch, msg, targetScene.id, ~taskId?, ~signal?)
      })

      if ViewerSystem.Adapter.isLoaded(newInstance) {
        cleanupLoadTimeout()
        SceneLoaderLogic.onSceneLoad(~dispatch, newInstance, targetScene, ~taskId?, ~signal?)
      }

      ViewerSystem.Pool.registerInstance(viewport.containerId, newInstance)

      Logger.debug(
        ~module_="SceneLoader",
        ~message="VIEWER_INITIALIZED_SUCCESS",
        ~data=Some({
          "containerId": viewport.containerId,
          "targetSceneId": targetScene.id,
        }),
        (),
      )
      ensureBackgroundViewer()
    } catch {
    | exn =>
      clearTimeout(safetyTimeoutId)
      let (errMsg, errStack) = Logger.getErrorDetails(exn)
      Logger.error(
        ~module_="SceneLoader",
        ~message="VIEWER_INITIALIZATION_ERROR",
        ~data=Some({
          "containerId": viewport.containerId,
          "targetSceneId": targetScene.id,
          "error": errMsg,
          "stack": errStack,
        }),
        (),
      )
      SceneLoaderLogic.onSceneError(
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
}
