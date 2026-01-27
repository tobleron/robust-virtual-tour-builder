/* src/systems/SceneLoaderLogicEvents.res */

open ReBindings
open ViewerState
open SceneLoaderTypes

let setupViewerEvents = (newViewer, targetScene: Types.scene, useProgressive, panoramaUrl) => {
  PannellumAdapter.on(newViewer, "load", _ => {
    Logger.debug(
      ~module_="Viewer",
      ~message="PANNELLUM_LOAD_EVENT",
      ~data=Some({"sceneId": targetScene.id}),
      (),
    )
    let loadedSceneId = PannellumAdapter.getScene(newViewer)
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
          if PannellumAdapter.getScene(newViewer) == "preview" {
            PannellumAdapter.loadScene(
              newViewer,
              "master",
              ~pitch=PannellumAdapter.getPitch(newViewer),
              ~yaw=PannellumAdapter.getYaw(newViewer),
              ~hfov=PannellumAdapter.getHfov(newViewer),
              (),
            )
          }
        },
      )

      Dom.addEventListenerNoEv(
        img,
        "error",
        () => {
          Logger.warn(
            ~module_="Viewer",
            ~message="MASTER_PRELOAD_FAILED",
            ~data=Some({"sceneName": targetScene.name}),
            (),
          )
          if PannellumAdapter.getScene(newViewer) == "preview" {
            PannellumAdapter.loadScene(
              newViewer,
              "master",
              ~pitch=PannellumAdapter.getPitch(newViewer),
              ~yaw=PannellumAdapter.getYaw(newViewer),
              ~hfov=PannellumAdapter.getHfov(newViewer),
              (),
            )
          }
        },
      )
    } else if !useProgressive || isMaster {
      PannellumAdapter.asCustom(newViewer).isLoaded = true
      GlobalStateBridge.dispatch(
        DispatchNavigationFsmEvent(TextureLoaded({targetSceneId: targetScene.id})),
      )

      // Inject hotspots
      let currentGlobalState = GlobalStateBridge.getState()
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
            PannellumAdapter.addHotSpot(newViewer, config)
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
    }
  })

  PannellumAdapter.on(newViewer, "error", e => {
    Logger.error(
      ~module_="Viewer",
      ~message="PANNELLUM_ERROR",
      ~data=Some({"error": e}),
      (),
    )
  })
}
