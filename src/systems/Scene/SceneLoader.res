/* src/systems/Scene/SceneLoader.res */

open ReBindings
open Types
open Actions

let castToString: 'a => string = %raw("(x) => typeof x === 'string' ? x : ''")
let castToDict: 'a => dict<string> = %raw("(x) => (typeof x === 'object' && x !== null) ? x : {}")
external asDynamic: 'a => {..} = "%identity"
external boolToUnknown: bool => unknown = "%identity"
external idToUnknown: string => unknown = "%identity"

let loadStartTime = ref(0.0)

module Config = {
  let getHotspots = (scene: scene) =>
    scene.hotspots->Belt.Array.mapWithIndex((idx, h) => {
      let pitch = h.displayPitch->Option.getOr(h.pitch)
      {
        "pitch": pitch,
        "yaw": h.yaw,
        "type": "info",
        "cssClass": "flat-arrow",
        "createTooltipFunc": HotspotLine.renderGoldArrow,
        "createTooltipArgs": {
          "i": idx,
          "targetSceneId": h.target,
          "pitch": pitch,
          "yaw": h.yaw,
          "truePitch": h.pitch,
          "viewFrame": h.viewFrame,
          "targetYaw": h.targetYaw,
          "targetPitch": h.targetPitch,
          "isReturnLink": h.isReturnLink,
          "returnViewFrame": h.returnViewFrame,
        },
      }
    })
  let makeSceneConfig = (scene: scene) =>
    {"panorama": scene.file->Types.fileToUrl, "autoLoad": true, "hotSpots": getHotspots(scene)}
}

module Reuse = {
  let findReusableInstance = (targetIdx: int): option<Dom.element> => {
    let targetSceneId = GlobalStateBridge.getState().scenes[targetIdx]->Option.map(s => s.id)
    ViewerSystem.Pool.pool.contents
    ->Belt.Array.getBy(v =>
      v.instance
      ->Option.map(inst =>
        ViewerSystem.Adapter.getMetaData(inst, "sceneId") ==
          targetSceneId->Option.map(id => idToUnknown(id))
      )
      ->Option.getOr(false)
    )
    ->Option.map(v => Dom.getElementById(v.containerId)->Nullable.toOption)
    ->Option.flatMap(x => x)
  }
}

module Events = {
  let onSceneLoad = (v, loadedScene: scene) => {
    let vId = castToDict(v)->Dict.get("container")->Option.getOr("")
    let entry = ViewerSystem.Pool.pool.contents->Belt.Array.getBy(e => e.containerId == vId)
    entry->Option.forEach(e => {
      e.instance->Option.forEach(inst =>
        ViewerSystem.Adapter.setMetaData(inst, "isLoaded", boolToUnknown(true))
      )
    })
    ViewerSystem.Pool.setCleanupTimeout(vId, None)
    GlobalStateBridge.dispatch(
      DispatchNavigationFsmEvent(NavigationFSM.TextureLoaded({targetSceneId: loadedScene.id})),
    )
  }
  let onSceneError = msg => {
    Logger.error(~module_="SceneLoader", ~message="LOAD_ERROR", ~data={"error": msg}, ())
    EventBus.dispatch(ShowNotification(msg, #Error, Some(Logger.castToJson({"error": msg}))))
  }
}

let loadNewScene = (_prevIndex: option<int>, targetIndex: option<int>, ~isAnticipatory=false) => {
  targetIndex->Option.forEach(tIdx => {
    let state = GlobalStateBridge.getState()
    state.scenes[tIdx]->Option.forEach(targetScene => {
      if !isAnticipatory {
        loadStartTime := Date.now()
        GlobalStateBridge.dispatch(
          DispatchNavigationFsmEvent(NavigationFSM.PreloadStarted({targetSceneId: targetScene.id})),
        )
      }
      switch if isAnticipatory {
        None
      } else {
        Reuse.findReusableInstance(tIdx)
      } {
      | Some(_) =>
        if !isAnticipatory {
          GlobalStateBridge.dispatch(
            DispatchNavigationFsmEvent(
              NavigationFSM.TextureLoaded({targetSceneId: targetScene.id}),
            ),
          )
        }
      | None =>
        let vp = if isAnticipatory {
          ViewerSystem.Pool.getInactive()
        } else {
          ViewerSystem.Pool.getInactive()
        }
        vp->Option.forEach(
          v => {
            let config = Config.makeSceneConfig(targetScene)
            let newInstance = ViewerSystem.Adapter.initialize(v.containerId, config)

            // Hook up events
            ViewerSystem.Adapter.on(
              newInstance,
              "load",
              _ => Events.onSceneLoad(newInstance, targetScene),
            )
            ViewerSystem.Adapter.on(newInstance, "error", msg => Events.onSceneError(msg))

            // RE-CHECK: If already loaded (e.g. from cache), trigger it manually
            if ViewerSystem.Adapter.isLoaded(newInstance) {
              Events.onSceneLoad(newInstance, targetScene)
            }

            ViewerSystem.Pool.registerInstance(v.containerId, newInstance)
          },
        )
      }
    })
  })
}
