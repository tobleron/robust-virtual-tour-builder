open RescriptSchema

module Shared = SchemasShared
module Domain = SchemasDomain

let toNullable = SchemasShared.toNullable

/* --- API Response Cast Helpers --- */

let parse = (json: JSON.t, schema: S.t<'a>): result<'a, string> => {
  let _name = S.name(schema)
  try {
    Ok(S.parseOrThrow(json, schema))
  } catch {
  | exn => {
      let msg = S.Error.message(Obj.magic(exn))
      /* Logger.error(
        ~module_="Schemas",
        ~message="PARSE_FAILED",
        ~data=Logger.castToJson({"schema": name, "error": msg}),
        (),
      ) */
      Error(msg)
    }
  }
}

let castToValidationReport = (json: JSON.t): SharedTypes.validationReport => {
  switch JSON.Decode.object(json) {
  | Some(obj) => {
      brokenLinksRemoved: obj
      ->Dict.get("brokenLinksRemoved")
      ->Option.flatMap(JSON.Decode.float)
      ->Option.map(Belt.Float.toInt)
      ->Option.getOr(0),
      orphanedScenes: obj
      ->Dict.get("orphanedScenes")
      ->Option.flatMap(JSON.Decode.array)
      ->Option.getOr([])
      ->Belt.Array.keepMap(JSON.Decode.string),
      unusedFiles: obj
      ->Dict.get("unusedFiles")
      ->Option.flatMap(JSON.Decode.array)
      ->Option.getOr([])
      ->Belt.Array.keepMap(JSON.Decode.string),
      warnings: obj
      ->Dict.get("warnings")
      ->Option.flatMap(JSON.Decode.array)
      ->Option.getOr([])
      ->Belt.Array.keepMap(JSON.Decode.string),
      errors: obj
      ->Dict.get("errors")
      ->Option.flatMap(JSON.Decode.array)
      ->Option.getOr([])
      ->Belt.Array.keepMap(JSON.Decode.string),
    }
  | None => {
      brokenLinksRemoved: 0,
      orphanedScenes: [],
      unusedFiles: [],
      warnings: [],
      errors: [],
    }
  }
}

let castToMetadataResponse = (json: JSON.t): SharedTypes.metadataResponse =>
  switch parse(json, Shared.metadataResponse) {
  | Ok(v) => v
  | Error(_) => {
      exif: SharedTypes.defaultExif,
      quality: SharedTypes.defaultQuality("Parsing failed"),
      isOptimized: false,
      checksum: "",
      suggestedName: Nullable.null,
    }
  }

let castToQualityAnalysis = (json: JSON.t): SharedTypes.qualityAnalysis =>
  switch JSON.Decode.object(json) {
  | Some(obj) => {
      score: obj->Dict.get("score")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0),
      histogram: obj
      ->Dict.get("histogram")
      ->Option.flatMap(JSON.Decode.array)
      ->Option.getOr([])
      ->Belt.Array.keepMap(JSON.Decode.float)
      ->Belt.Array.map(Belt.Float.toInt),
      colorHist: {
        r: [],
        g: [],
        b: [],
      },
      stats: {
        avgLuminance: 0,
        blackClipping: 0.0,
        whiteClipping: 0.0,
        sharpnessVariance: 0,
      },
      isBlurry: obj->Dict.get("isBlurry")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false),
      isSoft: obj->Dict.get("isSoft")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false),
      isSeverelyDark: obj
      ->Dict.get("isSeverelyDark")
      ->Option.flatMap(JSON.Decode.bool)
      ->Option.getOr(false),
      isSeverelyBright: obj
      ->Dict.get("isSeverelyBright")
      ->Option.flatMap(JSON.Decode.bool)
      ->Option.getOr(false),
      isDim: obj->Dict.get("isDim")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false),
      hasBlackClipping: obj
      ->Dict.get("hasBlackClipping")
      ->Option.flatMap(JSON.Decode.bool)
      ->Option.getOr(false),
      hasWhiteClipping: obj
      ->Dict.get("hasWhiteClipping")
      ->Option.flatMap(JSON.Decode.bool)
      ->Option.getOr(false),
      issues: obj
      ->Dict.get("issues")
      ->Option.flatMap(JSON.Decode.float)
      ->Option.map(Belt.Float.toInt)
      ->Option.getOr(0),
      warnings: obj
      ->Dict.get("warnings")
      ->Option.flatMap(JSON.Decode.float)
      ->Option.map(Belt.Float.toInt)
      ->Option.getOr(0),
      analysis: obj
      ->Dict.get("analysis")
      ->Option.flatMap(JSON.Decode.string)
      ->Option.map((s): Nullable.t<string> => Obj.magic(s))
      ->Option.getOr(Nullable.null),
    }
  | None => SharedTypes.defaultQuality("Parsing failed")
  }

let castToSimilarityResponse = (json: JSON.t): SharedTypes.similarityResponse =>
  switch parse(json, Shared.similarityResponse) {
  | Ok(v) => v
  | Error(_) => {
      results: [],
      durationMs: 0.0,
    }
  }

let castToExifMetadata = (json: JSON.t): SharedTypes.exifMetadata =>
  switch parse(json, Shared.exifMetadata) {
  | Ok(v) => v
  | Error(_) => SharedTypes.defaultExif
  }

let parseViewFrame = (json: option<JSON.t>): option<Types.viewFrame> => {
  json
  ->Option.flatMap(JSON.Decode.object)
  ->Option.map(obj => {
    {
      Types.yaw: obj->Dict.get("yaw")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0),
      pitch: obj->Dict.get("pitch")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0),
      hfov: obj->Dict.get("hfov")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0),
    }
  })
}

let parseHotspot = (json: JSON.t): Types.hotspot => {
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

let castToProjectScene = (json: JSON.t): Types.scene =>
  switch parse(json, Domain.scene) {
  | Ok(v) => v
  | Error(_) => {
      let obj = json->JSON.Decode.object->Option.getOr(Dict.make())
      let name = obj->Dict.get("name")->Option.flatMap(JSON.Decode.string)->Option.getOr("unknown")
      let fileStr = obj->Dict.get("file")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
      {
        id: obj
        ->Dict.get("id")
        ->Option.flatMap(JSON.Decode.string)
        ->Option.getOr("legacy_" ++ name),
        name,
        file: Types.Url(fileStr),
        tinyFile: obj
        ->Dict.get("tinyFile")
        ->Option.flatMap(JSON.Decode.string)
        ->Option.map(s => Types.Url(s)),
        originalFile: obj
        ->Dict.get("originalFile")
        ->Option.flatMap(JSON.Decode.string)
        ->Option.map(s => Types.Url(s)),
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

let castToProject = (json: JSON.t): Types.state => {
  switch parse(json, Domain.project) {
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
  | Error(_) =>
    // Emergency Fallback: Manual extraction of basic fields if schema fails
    switch JSON.Decode.object(json) {
    | Some(obj) => {
        let scenes =
          obj
          ->Dict.get("scenes")
          ->Option.flatMap(JSON.Decode.array)
          ->Option.getOr([])
          ->Belt.Array.map(castToProjectScene)

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
          sessionId: obj->Dict.get("sessionId")->Option.flatMap(JSON.Decode.string),
          lastUsedCategory: obj
          ->Dict.get("lastUsedCategory")
          ->Option.flatMap(JSON.Decode.string)
          ->Option.getOr("outdoor"),
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
              Types.id: itemObj
              ->Dict.get("id")
              ->Option.flatMap(JSON.Decode.string)
              ->Option.getOr(""),
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
    | None => State.initialState
    }
  }
}

let castToSteps = (json: JSON.t): array<Types.step> =>
  switch parse(json, S.array(Domain.step)) {
  | Ok(v) => v
  | Error(_) => []
  }

let castToImportScene = (json: JSON.t): Types.scene =>
  switch parse(json, Domain.importScene) {
  | Ok(v) => v
  | Error(_) => {
      id: "error",
      name: "invalid",
      file: Types.Url(""),
      tinyFile: None,
      originalFile: None,
      hotspots: [],
      category: "outdoor",
      floor: "ground",
      label: "",
      quality: None,
      colorGroup: None,
      _metadataSource: "default",
      categorySet: false,
      labelSet: false,
      isAutoForward: false,
    }
  }
