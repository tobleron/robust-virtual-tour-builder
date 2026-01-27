/* src/core/SceneHelpersParser.res */

open Types
open UiHelpers

let parseHotspots = (hss: array<JsonTypes.hotspotJson>): array<hotspot> => {
  Belt.Array.map(hss, hs => {
    {
      linkId: switch Nullable.toOption(hs.linkId) {
      | Some(id) => id
      | None => ""
      },
      yaw: hs.yaw,
      pitch: hs.pitch,
      target: hs.target,
      targetYaw: Nullable.toOption(hs.targetYaw),
      targetPitch: Nullable.toOption(hs.targetPitch),
      targetHfov: Nullable.toOption(hs.targetHfov),
      startYaw: Nullable.toOption(hs.startYaw),
      startPitch: Nullable.toOption(hs.startPitch),
      startHfov: Nullable.toOption(hs.startHfov),
      isReturnLink: Nullable.toOption(hs.isReturnLink),
      viewFrame: switch Nullable.toOption(hs.viewFrame) {
      | Some(vf) => Some(({yaw: vf.yaw, pitch: vf.pitch, hfov: vf.hfov}: viewFrame))
      | None => None
      },
      returnViewFrame: switch Nullable.toOption(hs.returnViewFrame) {
      | Some(vf) => Some(({yaw: vf.yaw, pitch: vf.pitch, hfov: vf.hfov}: viewFrame))
      | None => None
      },
      waypoints: switch Nullable.toOption(hs.waypoints) {
      | Some(wps) =>
        Some(Belt.Array.map(wps, (wp): viewFrame => {yaw: wp.yaw, pitch: wp.pitch, hfov: wp.hfov}))
      | None => None
      },
      displayPitch: Nullable.toOption(hs.displayPitch),
      transition: Nullable.toOption(hs.transition),
      duration: switch Nullable.toOption(hs.duration) {
      | Some(d) => Some(Belt.Float.toInt(d))
      | None => None
      },
    }
  })
}

let parseScene = (dataJson: JSON.t): scene => {
  let data = switch JsonTypes.decodeImportScene(dataJson) {
  | Ok(d) => d
  | Error(msg) =>
    Logger.error(
      ~module_="SceneHelpersParser",
      ~message="SCHEMA_PARSE_ERROR_SCENE",
      ~data=Logger.castToJson({"error": msg, "json": dataJson}),
      (),
    )
    (
      {
        id: "error_" ++ Float.toString(Date.now()),
        name: "invalid.webp",
        preview: JSON.Encode.null,
        tiny: Nullable.null,
        original: Nullable.null,
        quality: Nullable.null,
        colorGroup: Nullable.null,
      }: JsonTypes.importSceneJson
    )
  }
  {
    id: data.id,
    name: data.name,
    file: decodeFile(data.preview),
    tinyFile: Nullable.toOption(data.tiny)->Option.map(decodeFile),
    originalFile: Nullable.toOption(data.original)->Option.map(decodeFile),
    hotspots: [],
    category: "outdoor",
    floor: "ground",
    label: "",
    quality: Nullable.toOption(data.quality),
    colorGroup: Nullable.toOption(data.colorGroup),
    _metadataSource: "default",
    categorySet: false,
    labelSet: false,
    isAutoForward: false,
  }
}

let parseProject = (projectDataJson: JSON.t): state => {
  let pd = switch JsonTypes.decodeProject(projectDataJson) {
  | Ok(p) => p
  | Error(msg) =>
    Logger.error(
      ~module_="SceneHelpersParser",
      ~message="SCHEMA_PARSE_ERROR_PROJECT",
      ~data=Logger.castToJson({"error": msg}),
      (),
    )
    (
      {
        tourName: Nullable.null,
        scenes: [],
        lastUsedCategory: Nullable.null,
        exifReport: Nullable.null,
        sessionId: Nullable.null,
      }: JsonTypes.projectJson
    )
  }
  let tourName = switch Nullable.toOption(pd.tourName) {
  | Some(tn) if !TourLogic.isUnknownName(tn) => tn
  | _ => "Tour Name"
  }

  let scenes = Belt.Array.map(pd.scenes, sc => {
    {
      id: switch Nullable.toOption(sc.id) {
      | Some(id) => id
      | None => "legacy_" ++ sc.name
      },
      name: sc.name,
      file: decodeFile(sc.file),
      tinyFile: Nullable.toOption(sc.tinyFile)->Option.map(decodeFile),
      originalFile: Nullable.toOption(sc.originalFile)->Option.map(decodeFile),
      hotspots: switch Nullable.toOption(sc.hotspots) {
      | Some(hss) => parseHotspots(hss)
      | None => []
      },
      category: switch Nullable.toOption(sc.category) {
      | Some(c) => c
      | None => "outdoor"
      },
      floor: switch Nullable.toOption(sc.floor) {
      | Some(f) => f
      | None => "ground"
      },
      label: switch Nullable.toOption(sc.label) {
      | Some(l) => l
      | None => ""
      },
      quality: Nullable.toOption(sc.quality),
      colorGroup: Nullable.toOption(sc.colorGroup),
      _metadataSource: switch Nullable.toOption(sc.metadataSource) {
      | Some(m) => m
      | None => "user"
      },
      categorySet: switch Nullable.toOption(sc.categorySet) {
      | Some(cs) => cs
      | None => false
      },
      labelSet: switch Nullable.toOption(sc.labelSet) {
      | Some(ls) => ls
      | None => false
      },
      isAutoForward: switch Nullable.toOption(sc.isAutoForward) {
      | Some(af) => af
      | None => false
      },
    }
  })

  let lastUsedCategory = switch Nullable.toOption(pd.lastUsedCategory) {
  | Some(c) => c
  | None => "outdoor"
  }
  let exifReport = switch Nullable.toOption(pd.exifReport) {
  | Some(er) => Some(er)
  | None => None
  }

  {
    ...State.initialState,
    tourName,
    scenes,
    activeIndex: if Array.length(scenes) > 0 {
      0
    } else {
      -1
    },
    lastUsedCategory,
    exifReport,
    sessionId: Nullable.toOption(pd.sessionId),
  }
}
