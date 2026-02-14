/* src/systems/Scene/Loader/SceneLoaderEvents.res */
open Types
open Actions

let isStaleTask = (~taskId: option<string>=?, ~signal: option<BrowserBindings.AbortSignal.t>=?) => {
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

let castToDict: 'a => dict<string> = %raw("(x) => (typeof x === 'object' && x !== null) ? x : {}")
external boolToUnknown: bool => unknown = "%identity"
external idToUnknown: string => unknown = "%identity"

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
