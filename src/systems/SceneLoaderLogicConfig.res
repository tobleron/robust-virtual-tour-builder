/* src/systems/SceneLoaderLogicConfig.res */

open ReBindings
open SceneLoaderTypes

let getPanoramaUrl = (file: Types.file): string => {
  UrlUtils.fileToUrl(file)
}

let createViewerConfig = (useProgressive, panoramaUrl, tinyUrl) => {
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
  let initialHfov = Constants.globalHfov

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
        "friction": 0.15,
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
        "friction": 0.15,
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
  
  viewerConfig
}
