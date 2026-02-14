/* src/systems/Scene/Loader/SceneLoaderConfig.res */
open Types

let getHotspots = (scene: scene, ~state, ~dispatch) =>
  scene.hotspots->Belt.Array.mapWithIndex((idx, h) => {
    HotspotManager.createHotspotConfig(~hotspot=h, ~index=idx, ~state, ~scene, ~dispatch)
  })

let makeSceneConfig = (scene: scene, ~state, ~dispatch) => {
  let url = SceneCache.getSourceUrl(scene.id, scene.file)
  Logger.debug(
    ~module_="SceneLoader",
    ~message="PREPARING_SCENE_INNER",
    ~data={"id": scene.id, "url": url},
    (),
  )
  {
    "panorama": url,
    "hotSpots": getHotspots(scene, ~state, ~dispatch),
  }
}

let makeInitialConfig = (scene: scene, ~state, ~dispatch) => {
  let inner = makeSceneConfig(scene, ~state, ~dispatch)
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

let blankPanorama = "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw=="

let backgroundViewerConfig = () => {
  {
    "panorama": blankPanorama,
    "hotSpots": [],
    "autoLoad": false,
    "hfov": Constants.globalHfov,
    "minHfov": Constants.globalHfov,
    "maxHfov": Constants.globalHfov,
    "mouseZoom": false,
    "doubleClickZoom": false,
    "keyboardZoom": false,
    "showZoomCtrl": false,
  }
}
