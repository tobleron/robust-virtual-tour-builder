/* src/core/SceneHelpersParser.res */

open Types

let parseViewFrame = (json: option<JSON.t>): option<viewFrame> => {
  json
  ->Option.flatMap(JSON.Decode.object)
  ->Option.map(obj => {
    {
      yaw: obj->Dict.get("yaw")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0),
      pitch: obj->Dict.get("pitch")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0),
      hfov: obj->Dict.get("hfov")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0),
    }
  })
}

let parseHotspot = (json: JSON.t): hotspot => {
  let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
  {
    linkId: obj->Dict.get("linkId")->Option.flatMap(JSON.Decode.string)->Option.getOr(""),
    yaw: obj->Dict.get("yaw")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0),
    pitch: obj->Dict.get("pitch")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0),
    target: obj->Dict.get("target")->Option.flatMap(JSON.Decode.string)->Option.getOr(""),
    targetYaw: obj->Dict.get("targetYaw")->Option.flatMap(JSON.Decode.float),
    targetPitch: obj->Dict.get("targetPitch")->Option.flatMap(JSON.Decode.float),
    targetHfov: obj->Dict.get("targetHfov")->Option.flatMap(JSON.Decode.float),
    startYaw: obj->Dict.get("startYaw")->Option.flatMap(JSON.Decode.float),
    startPitch: obj->Dict.get("startPitch")->Option.flatMap(JSON.Decode.float),
    startHfov: obj->Dict.get("startHfov")->Option.flatMap(JSON.Decode.float),
    isReturnLink: obj->Dict.get("isReturnLink")->Option.flatMap(JSON.Decode.bool),
    viewFrame: parseViewFrame(obj->Dict.get("viewFrame")),
    returnViewFrame: parseViewFrame(obj->Dict.get("returnViewFrame")),
    waypoints: obj
    ->Dict.get("waypoints")
    ->Option.flatMap(JSON.Decode.array)
    ->Option.map(arr => arr->Belt.Array.keepMap(item => parseViewFrame(Some(item)))),
    displayPitch: obj->Dict.get("displayPitch")->Option.flatMap(JSON.Decode.float),
    transition: obj->Dict.get("transition")->Option.flatMap(JSON.Decode.string),
    duration: obj
    ->Dict.get("duration")
    ->Option.flatMap(JSON.Decode.float)
    ->Option.map(Belt.Float.toInt),
  }
}

let parseScene = (dataJson: JSON.t): scene => {
  switch Schemas.parse(dataJson, Schemas.Domain.scene) {
  | Ok(data) => data
  | Error(_) => {
      let obj = dataJson->JSON.Decode.object->Option.getOr(Dict.make())
      let name = obj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("unknown")
      let fileStr = obj->Dict.get("file")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
      {
        id: obj
        ->Dict.get("id")
        ->Option.flatMap(JSON.Decode.string)
        ->Option.getOr("legacy_" ++ name),
        name,
        file: Url(fileStr),
        tinyFile: obj
        ->Dict.get("tinyFile")
        ->Option.flatMap(JSON.Decode.string)
        ->Option.map(s => Url(s)),
        originalFile: obj
        ->Dict.get("originalFile")
        ->Option.flatMap(JSON.Decode.string)
        ->Option.map(s => Url(s)),
        hotspots: obj
        ->Dict.get("hotspots")
        ->Option.flatMap(JSON.Decode.array)
        ->Option.getOr([])
        ->Belt.Array.map(parseHotspot),
        category: obj
        ->Dict.get("category")
        ->Option.flatMap(JSON.Decode.string)
        ->Option.getOr("outdoor"),
        floor: obj->Dict.get("floor")->Option.flatMap(JSON.Decode.string)->Option.getOr("ground"),
        label: obj->Dict.get("label")->Option.flatMap(JSON.Decode.string)->Option.getOr(""),
        quality: obj->Dict.get("quality"),
        colorGroup: obj->Dict.get("colorGroup")->Option.flatMap(JSON.Decode.string),
        _metadataSource: obj
        ->Dict.get("_metadataSource")
        ->Option.flatMap(JSON.Decode.string)
        ->Option.getOr("user"),
        categorySet: obj
        ->Dict.get("categorySet")
        ->Option.flatMap(JSON.Decode.bool)
        ->Option.getOr(false),
        labelSet: obj->Dict.get("labelSet")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false),
        isAutoForward: obj
        ->Dict.get("isAutoForward")
        ->Option.flatMap(JSON.Decode.bool)
        ->Option.getOr(false),
      }
    }
  }
}

let parseProject = (projectDataJson: JSON.t): state => {
  switch Schemas.parse(projectDataJson, Schemas.Domain.project) {
  | Ok(pd) => {
      ...State.initialState,
      tourName: pd.tourName,
      scenes: pd.scenes,
      activeIndex: if Array.length(pd.scenes) > 0 {
        0
      } else {
        -1
      },
      lastUsedCategory: pd.lastUsedCategory,
      exifReport: pd.exifReport,
      sessionId: pd.sessionId,
      deletedSceneIds: pd.deletedSceneIds,
      timeline: pd.timeline,
    }
  | Error(msg) => {
      // MANUAL FALLBACK
      let obj = projectDataJson->JSON.Decode.object->Option.getOr(Dict.make())
      let keys = obj->Dict.keysToArray
      let scenesVal = obj->Dict.get("scenes")

      Logger.warn(
        ~module_="SceneHelpersParser",
        ~message="DOMAIN_PROJECT_SCHEMA_FAIL_FALLBACK_ACTIVE",
        ~data=Logger.castToJson({
          "error": msg,
          "availableKeys": keys,
          "hasScenes": Option.isSome(scenesVal),
        }),
        (),
      )

      let scenes =
        scenesVal
        ->Option.flatMap(JSON.Decode.array)
        ->Option.getOr([])
        ->Belt.Array.map(parseScene)

      Logger.info(
        ~module_="SceneHelpersParser",
        ~message="MANUAL_FALLBACK_EXTRACTED_SCENES",
        ~data=Logger.castToJson({"count": Array.length(scenes)}),
        (),
      )

      {
        ...State.initialState,
        tourName: obj
        ->Dict.get("tourName")
        ->Option.flatMap(JSON.Decode.string)
        ->Option.getOr("Tour Name"),
        scenes,
        activeIndex: if Array.length(scenes) > 0 {
          0
        } else {
          -1
        },
        lastUsedCategory: obj
        ->Dict.get("lastUsedCategory")
        ->Option.flatMap(JSON.Decode.string)
        ->Option.getOr("outdoor"),
        exifReport: obj->Dict.get("exifReport"),
        sessionId: obj->Dict.get("sessionId")->Option.flatMap(JSON.Decode.string),
        deletedSceneIds: obj
        ->Dict.get("deletedSceneIds")
        ->Option.flatMap(JSON.Decode.array)
        ->Option.getOr([])
        ->Belt.Array.keepMap(JSON.Decode.string),
        timeline: obj
        ->Dict.get("timeline")
        ->Option.flatMap(JSON.Decode.array)
        ->Option.getOr([])
        ->Belt.Array.keepMap(item => {
          let itemObj = item->JSON.Decode.object->Option.getOr(Dict.make())
          Some({
            Types.id: itemObj->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr(""),
            linkId: itemObj
            ->Dict.get("linkId")
            ->Option.flatMap(JSON.Decode.string)
            ->Option.getOr(""),
            sceneId: itemObj
            ->Dict.get("sceneId")
            ->Option.flatMap(JSON.Decode.string)
            ->Option.getOr(""),
            targetScene: itemObj
            ->Dict.get("targetScene")
            ->Option.flatMap(JSON.Decode.string)
            ->Option.getOr(""),
            transition: itemObj
            ->Dict.get("transition")
            ->Option.flatMap(JSON.Decode.string)
            ->Option.getOr(""),
            duration: itemObj
            ->Dict.get("duration")
            ->Option.flatMap(JSON.Decode.float)
            ->Option.map(Belt.Float.toInt)
            ->Option.getOr(0),
          })
        }),
      }
    }
  }
}
