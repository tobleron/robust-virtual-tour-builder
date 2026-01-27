open RescriptSchema

let toNullable = (schema: S.t<option<'a>>): S.t<Nullable.t<'a>> => {
  schema->S.transform(_ => {
    parser: (opt: option<'a>) => opt->Nullable.fromOption,
    serializer: (nul: Nullable.t<'a>) => nul->Nullable.toOption,
  })
}

module Shared = {
  let gpsData = S.object(s => {
    open SharedTypes
    {
      lat: s.field("lat", S.float),
      lon: s.field("lon", S.float),
    }
  })

  let exifMetadata = S.object(s => {
    open SharedTypes
    {
      make: s.field("make", S.nullable(S.string)->toNullable),
      model: s.field("model", S.nullable(S.string)->toNullable),
      dateTime: s.field("dateTime", S.nullable(S.string)->toNullable),
      gps: s.field("gps", S.nullable(gpsData)->toNullable),
      width: s.field("width", S.int),
      height: s.field("height", S.int),
      focalLength: s.field("focalLength", S.nullable(S.float)->toNullable),
      aperture: s.field("aperture", S.nullable(S.float)->toNullable),
      iso: s.field("iso", S.nullable(S.int)->toNullable),
    }
  })

  let colorHist: S.t<SharedTypes.colorHist> = S.object((s): SharedTypes.colorHist => {
    {
      r: s.field("r", S.array(S.int)),
      g: s.field("g", S.array(S.int)),
      b: s.field("b", S.array(S.int)),
    }
  })

  let qualityStats: S.t<SharedTypes.qualityStats> = S.object(s => {
    open SharedTypes
    {
      avgLuminance: s.field("avgLuminance", S.int),
      blackClipping: s.field("blackClipping", S.float),
      whiteClipping: s.field("whiteClipping", S.float),
      sharpnessVariance: s.field("sharpnessVariance", S.int),
    }
  })

  let qualityAnalysis = S.object(s => {
    open SharedTypes
    {
      score: s.field("score", S.float),
      histogram: s.field("histogram", S.array(S.int)),
      colorHist: s.field("colorHist", colorHist),
      stats: s.field("stats", qualityStats),
      isBlurry: s.field("isBlurry", S.bool),
      isSoft: s.field("isSoft", S.bool),
      isSeverelyDark: s.field("isSeverelyDark", S.bool),
      isSeverelyBright: s.field("isSeverelyBright", S.bool),
      isDim: s.field("isDim", S.bool),
      hasBlackClipping: s.field("hasBlackClipping", S.bool),
      hasWhiteClipping: s.field("hasWhiteClipping", S.bool),
      issues: s.field("issues", S.int),
      warnings: s.field("warnings", S.int),
      analysis: s.field("analysis", S.nullable(S.string)->toNullable),
    }
  })

  let metadataResponse = S.object(s => {
    open SharedTypes
    {
      exif: s.field("exif", exifMetadata),
      quality: s.field("quality", qualityAnalysis),
      isOptimized: s.field("isOptimized", S.bool),
      checksum: s.field("checksum", S.string),
      suggestedName: s.field("suggestedName", S.nullable(S.string)->toNullable),
    }
  })

  let similarityResult = S.object(s => {
    open SharedTypes
    {
      idA: s.field("idA", S.string),
      idB: s.field("idB", S.string),
      similarity: s.field("similarity", S.float),
    }
  })

  let similarityResponse = S.object(s => {
    open SharedTypes
    {
      results: s.field("results", S.array(similarityResult)),
      durationMs: s.field("durationMs", S.float),
    }
  })

  let validationReport = S.object(s => {
    open SharedTypes
    {
      brokenLinksRemoved: s.field("brokenLinksRemoved", S.int),
      orphanedScenes: s.field("orphanedScenes", S.array(S.string)),
      unusedFiles: s.field("unusedFiles", S.array(S.string)),
      warnings: s.field("warnings", S.array(S.string)),
      errors: s.field("errors", S.array(S.string)),
    }
  })

  let importResponse = S.object(s => {
    (s.field("sessionId", S.string), s.field("projectData", S.json(~validate=false)))
  })->S.setName("import response")

  let geocodeResponse = S.object(s => {
    s.field("address", S.string)
  })->S.setName("geocode response")
}

module Domain = {
  open Types

  let file = S.string->S.transform(_ => {
    parser: s => Url(s),
    serializer: f =>
      switch f {
      | Url(s) => s
      | Blob(_) | File(_) => "" // Should not happen for API responses
      },
  })

  let viewFrame = S.object(s => {
    {
      yaw: s.field("yaw", S.float),
      pitch: s.field("pitch", S.float),
      hfov: s.field("hfov", S.float),
    }
  })

  let hotspot = S.object(s => {
    {
      linkId: s.field("linkId", S.option(S.string)->S.Option.getOr("")),
      yaw: s.field("yaw", S.float),
      pitch: s.field("pitch", S.float),
      target: s.field("target", S.string),
      targetYaw: s.field("targetYaw", S.option(S.float)),
      targetPitch: s.field("targetPitch", S.option(S.float)),
      targetHfov: s.field("targetHfov", S.option(S.float)),
      startYaw: s.field("startYaw", S.option(S.float)),
      startPitch: s.field("startPitch", S.option(S.float)),
      startHfov: s.field("startHfov", S.option(S.float)),
      isReturnLink: s.field("isReturnLink", S.option(S.bool)),
      viewFrame: s.field("viewFrame", S.option(viewFrame)),
      returnViewFrame: s.field("returnViewFrame", S.option(viewFrame)),
      waypoints: s.field("waypoints", S.option(S.array(viewFrame))),
      displayPitch: s.field("displayPitch", S.option(S.float)),
      transition: s.field("transition", S.option(S.string)),
      duration: s.field(
        "duration",
        S.option(S.float)
        ->S.Option.getOr(0.0)
        ->S.transform(_ => {
          parser: d => Belt.Float.toInt(d),
          serializer: i => Belt.Int.toFloat(i),
        })
        ->S.option,
      ),
    }
  })

  let scene = S.object(s => {
    {
      id: s.field("id", S.option(S.string)->S.Option.getOr("")),
      name: s.field("name", S.string),
      file: s.field("file", file),
      tinyFile: s.field("tinyFile", S.option(file)),
      originalFile: s.field("originalFile", S.option(file)),
      hotspots: s.field("hotspots", S.option(S.array(hotspot))->S.Option.getOr([])),
      category: s.field("category", S.option(S.string)->S.Option.getOr("outdoor")),
      floor: s.field("floor", S.option(S.string)->S.Option.getOr("ground")),
      label: s.field("label", S.option(S.string)->S.Option.getOr("")),
      quality: s.field("quality", S.option(S.json(~validate=false))),
      colorGroup: s.field("colorGroup", S.option(S.string)),
      _metadataSource: s.field("_metadataSource", S.option(S.string)->S.Option.getOr("user")),
      categorySet: s.field("categorySet", S.option(S.bool)->S.Option.getOr(false)),
      labelSet: s.field("labelSet", S.option(S.bool)->S.Option.getOr(false)),
      isAutoForward: s.field("isAutoForward", S.option(S.bool)->S.Option.getOr(false)),
    }
  })->S.transform(_ => {
    parser: s => {
      if s.id == "" {
        {...s, id: "legacy_" ++ s.name}
      } else {
        s
      }
    },
    serializer: s => s,
  })

  let project: S.t<Types.project> = S.object(s => {
    {
      tourName: s.field("tourName", S.option(S.string)->S.Option.getOr("Tour Name")),
      scenes: s.field("scenes", S.array(scene)),
      lastUsedCategory: s.field("lastUsedCategory", S.option(S.string)->S.Option.getOr("outdoor")),
      exifReport: s.field("exifReport", S.option(S.json(~validate=false))),
      sessionId: s.field("sessionId", S.option(S.string)),
    }
  })

  let importScene = S.object(s => {
    {
      id: s.field("id", S.string),
      name: s.field("name", S.string),
      file: s.field("preview", file),
      tinyFile: s.field("tiny", S.option(file)),
      originalFile: s.field("original", S.option(file)),
      hotspots: [],
      category: "outdoor",
      floor: "ground",
      label: "",
      quality: s.field("quality", S.option(S.json(~validate=false))),
      colorGroup: s.field("colorGroup", S.option(S.string)),
      _metadataSource: "default",
      categorySet: false,
      labelSet: false,
      isAutoForward: false,
    }
  })

  let timelineItem = S.object(s => {
    {
      id: s.field("id", S.string),
      linkId: s.field("linkId", S.string),
      sceneId: s.field("sceneId", S.string),
      targetScene: s.field("targetScene", S.string),
      transition: s.field("transition", S.string),
      duration: s.field("duration", S.int),
    }
  })

  let updateMetadata: S.t<Types.updateMetadata> = S.object(s => {
    {
      category: s.field("category", S.option(S.string)),
      floor: s.field("floor", S.option(S.string)),
      label: s.field("label", S.option(S.string)),
      isAutoForward: s.field("isAutoForward", S.option(S.bool)),
    }
  })

  let timelineUpdate: S.t<Types.timelineUpdate> = S.object(s => {
    {
      transition: s.field("transition", S.option(S.string)),
      duration: s.field("duration", S.option(S.option(S.int))),
    }
  })

  let transitionTarget = S.object(s => {
    {
      yaw: s.field("yaw", S.float),
      pitch: s.field("pitch", S.float),
      targetName: s.field("targetName", S.string),
      timelineItemId: s.field("timelineItemId", S.option(S.string)),
    }
  })

  let arrivalView = S.object(s => {
    {
      yaw: s.field("yaw", S.float),
      pitch: s.field("pitch", S.float),
    }
  })

  let step = S.object(s => {
    {
      idx: s.field("idx", S.int),
      transitionTarget: s.field("transitionTarget", S.option(transitionTarget)),
      arrivalView: s.field("arrivalView", arrivalView),
    }
  })
}

/* --- API Response Cast Helpers --- */

let parse = (json: JSON.t, schema: S.t<'a>): result<'a, string> => {
  try {
    Ok(S.parseOrThrow(json, schema))
  } catch {
  | exn => Error(S.Error.message(Obj.magic(exn)))
  }
}

let castToValidationReport = (json: JSON.t): SharedTypes.validationReport =>
  try {
    S.parseOrThrow(json, Shared.validationReport)
  } catch {
  | _ => {
      brokenLinksRemoved: 0,
      orphanedScenes: [],
      unusedFiles: [],
      warnings: [],
      errors: [],
    }
  }

let castToMetadataResponse = (json: JSON.t): SharedTypes.metadataResponse =>
  try {
    S.parseOrThrow(json, Shared.metadataResponse)
  } catch {
  | _ => {
      exif: SharedTypes.defaultExif,
      quality: SharedTypes.defaultQuality("Parsing failed"),
      isOptimized: false,
      checksum: "",
      suggestedName: Nullable.null,
    }
  }

let castToQualityAnalysis = (json: JSON.t): SharedTypes.qualityAnalysis =>
  try {
    S.parseOrThrow(json, Shared.qualityAnalysis)
  } catch {
  | _ => SharedTypes.defaultQuality("Parsing failed")
  }

let castToSimilarityResponse = (json: JSON.t): SharedTypes.similarityResponse =>
  try {
    S.parseOrThrow(json, Shared.similarityResponse)
  } catch {
  | _ => {
      results: [],
      durationMs: 0.0,
    }
  }

let castToExifMetadata = (json: JSON.t): SharedTypes.exifMetadata =>
  try {
    S.parseOrThrow(json, Shared.exifMetadata)
  } catch {
  | _ => SharedTypes.defaultExif
  }

let castToProject = (json: JSON.t): Types.state => {
  try {
    let pd = S.parseOrThrow(json, Domain.project)
    {
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
    }
  } catch {
  | _ => State.initialState
  }
}

let castToSteps = (json: JSON.t): array<Types.step> =>
  try {
    S.parseOrThrow(json, S.array(Domain.step))
  } catch {
  | _ => []
  }

let castToImportScene = (json: JSON.t): Types.scene =>
  try {
    S.parseOrThrow(json, Domain.importScene)
  } catch {
  | _ => {
      id: "error",
      name: "invalid",
      file: Url(""),
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

let castToProjectScene = (json: JSON.t): Types.scene =>
  try {
    S.parseOrThrow(json, Domain.scene)
  } catch {
  | _ => {
      id: "error",
      name: "invalid",
      file: Url(""),
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
