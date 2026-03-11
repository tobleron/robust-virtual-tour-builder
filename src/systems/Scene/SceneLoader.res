/* src/systems/Scene/SceneLoader.res */

open Types
open Actions

external asDynamic: 'a => {..} = "%identity"
external boolToUnknown: bool => unknown = "%identity"
external idToUnknown: string => unknown = "%identity"
@val external clearTimeout: timeoutId => unit = "clearTimeout"

let loadStartTime = ref(0.0)

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
      SceneLoaderSupport.reportTargetNotFound(~dispatch, ~taskId, ~targetSceneId)
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
        SceneLoaderSupport.loadReusableScene(
          ~inst,
          ~targetScene,
          ~state,
          ~dispatch,
          ~taskId,
          ~signal,
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
        SceneLoaderSupport.loadFreshScene(
          ~viewport=v,
          ~targetScene,
          ~state,
          ~dispatch,
          ~taskId,
          ~signal,
          ~setCurrentLoadTimeout=next => currentLoadTimeout := next,
          ~cleanupLoadTimeout,
          ~ensureBackgroundViewer=() => ensureBackgroundViewer(~_state=state, ~_dispatch=dispatch),
        )
      })
    }
  }
}
