/* src/core/SchemaDefinitions.res */

open RescriptSchema

module Shared = {
  open SharedTypes

  external identity: 'a => 'b = "%identity"

  let jsonSchema: S.t<JSON.t> = S.unknown->S.transform(_ => {
    parser: (v: unknown) => v->identity,
    serializer: (v: JSON.t) => v->identity,
  })

  let toNullable = (schema: S.t<option<'a>>): S.t<Nullable.t<'a>> => {
    schema->S.transform(_ => {
      parser: (opt: option<'a>) => opt->Nullable.fromOption,
      serializer: (nul: Nullable.t<'a>) => nul->Nullable.toOption,
    })
  }

  let gpsData: S.t<gpsData> = S.object((s): gpsData => {
    {
      lat: s.field("lat", S.float),
      lon: s.field("lon", S.float),
    }
  })

  let exifMetadata: S.t<exifMetadata> = S.object(s => {
    {
      dateTime: s.field("date", S.nullable(S.string)->toNullable),
      gps: s.field("gps", S.nullable(gpsData)->toNullable),
      make: s.field("cameraModel", S.nullable(S.string)->toNullable),
      model: s.field("lensModel", S.nullable(S.string)->toNullable),
      width: 0,
      height: 0,
      focalLength: s.field("focalLength", S.nullable(S.float)->toNullable),
      aperture: s.field("fNumber", S.nullable(S.float)->toNullable),
      iso: s.field("iso", S.nullable(S.int)->toNullable),
    }
  })

  let colorHist: S.t<colorHist> = S.object((s): colorHist => {
    {
      r: s.field("r", S.array(S.int)),
      g: s.field("g", S.array(S.int)),
      b: s.field("b", S.array(S.int)),
    }
  })

  let qualityStats: S.t<qualityStats> = S.object(s => {
    {
      avgLuminance: s.field("avgLuminance", S.int),
      blackClipping: s.field("blackClipping", S.float),
      whiteClipping: s.field("whiteClipping", S.float),
      sharpnessVariance: s.field("sharpnessVariance", S.int),
    }
  })

  let qualityAnalysis: S.t<qualityAnalysis> = S.object(s => {
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

  let metadataResponse: S.t<metadataResponse> = S.object(s => {
    {
      exif: s.field("exif", exifMetadata),
      quality: s.field("quality", qualityAnalysis),
      isOptimized: s.field("isOptimized", S.bool),
      checksum: s.field("checksum", S.string),
      suggestedName: s.field("suggestedName", S.nullable(S.string)->toNullable),
    }
  })

  let similarityResult: S.t<similarityResult> = S.object(s => {
    {
      idA: s.field("sceneId", S.string),
      idB: "",
      similarity: s.field("score", S.float),
    }
  })

  let similarityResponse: S.t<similarityResponse> = S.object(s => {
    {
      results: s.field("results", S.array(similarityResult)),
      durationMs: s.field("durationMs", S.float),
    }
  })

  let validationReport: S.t<validationReport> = S.object(s => {
    {
      brokenLinksRemoved: s.field("brokenLinksRemoved", S.int),
      orphanedScenes: s.field("orphanedScenes", S.array(S.string)),
      unusedFiles: s.field("unusedFiles", S.array(S.string)),
      warnings: s.field("warnings", S.array(S.string)),
      errors: s.field("errors", S.array(S.string)),
    }
  })

  let geocodeResponse: S.t<string> = S.object(s => s.field("address", S.string))

  let geocodeRequest: S.t<geocodeRequest> = S.object((s): geocodeRequest => {
    {
      lat: s.field("lat", S.float),
      lon: s.field("lon", S.float),
    }
  })

  let importResponse: S.t<(string, JSON.t)> = S.object(s => {
    (s.field("sessionId", S.string), s.field("projectData", jsonSchema))
  })
}

module Domain = {
  open Types

  external identity: 'a => 'b = "%identity"

  let jsonSchema: S.t<JSON.t> = S.unknown->S.transform(_ => {
    parser: (v: unknown) => v->identity,
    serializer: (v: JSON.t) => v->identity,
  })

  let file = S.string->S.transform(_ => {
    parser: (s: string) => Url(s),
    serializer: (f: file) =>
      switch f {
      | Url(s) => s
      | Blob(_) | File(_) => ""
      },
  })

  let viewFrame = S.object(s => {
    {
      yaw: s.field("yaw", S.option(S.float)->S.Option.getOr(0.0)),
      pitch: s.field("pitch", S.option(S.float)->S.Option.getOr(0.0)),
      hfov: s.field("hfov", S.option(S.float)->S.Option.getOr(0.0)),
    }
  })

  let hotspot = S.object(s => {
    {
      linkId: s.field("linkId", S.option(S.string)->S.Option.getOr("")),
      yaw: s.field("yaw", S.option(S.float)->S.Option.getOr(0.0)),
      pitch: s.field("pitch", S.option(S.float)->S.Option.getOr(0.0)),
      target: s.field("target", S.option(S.string)->S.Option.getOr("")),
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
        S.option(S.float)->S.transform(_ => {
          parser: o => o->Option.map(Belt.Float.toInt),
          serializer: o => o->Option.map(Belt.Int.toFloat),
        }),
      ),
    }
  })

  let scene = S.object(s => {
    {
      id: s.field("id", S.option(S.string)->S.Option.getOr("")),
      name: s.field("name", S.option(S.string)->S.Option.getOr("unknown")),
      file: s.field("file", file),
      tinyFile: s.field("tinyFile", S.option(file)),
      originalFile: s.field("originalFile", S.option(file)),
      hotspots: s.field("hotspots", S.option(S.array(hotspot))->S.Option.getOr([])),
      category: s.field("category", S.option(S.string)->S.Option.getOr("outdoor")),
      floor: s.field("floor", S.option(S.string)->S.Option.getOr("ground")),
      label: s.field("label", S.option(S.string)->S.Option.getOr("")),
      quality: s.field("quality", S.option(jsonSchema)),
      colorGroup: s.field("colorGroup", S.option(S.string)),
      _metadataSource: s.field("_metadataSource", S.option(S.string)->S.Option.getOr("user")),
      categorySet: s.field("categorySet", S.option(S.bool)->S.Option.getOr(false)),
      labelSet: s.field("labelSet", S.option(S.bool)->S.Option.getOr(false)),
      isAutoForward: s.field("isAutoForward", S.option(S.bool)->S.Option.getOr(false)),
    }
  })

  let timelineItem = S.object(s => {
    {
      id: s.field("id", S.option(S.string)->S.Option.getOr("")),
      linkId: s.field("linkId", S.option(S.string)->S.Option.getOr("")),
      sceneId: s.field("sceneId", S.option(S.string)->S.Option.getOr("")),
      targetScene: s.field("targetScene", S.option(S.string)->S.Option.getOr("")),
      transition: s.field("transition", S.option(S.string)->S.Option.getOr("")),
      duration: s.field(
        "duration",
        S.option(S.float)->S.transform(_ => {
          parser: o => o->Option.map(Belt.Float.toInt)->Option.getOr(0),
          serializer: i => Some(Belt.Int.toFloat(i)),
        }),
      ),
    }
  })

  let project: S.t<Types.project> = S.object(s => {
    {
      tourName: s.field("tourName", S.option(S.string)->S.Option.getOr("Tour Name")),
      scenes: s.field("scenes", S.option(S.array(scene))->S.Option.getOr([])),
      lastUsedCategory: s.field("lastUsedCategory", S.option(S.string)->S.Option.getOr("outdoor")),
      exifReport: s.field("exifReport", S.option(jsonSchema)),
      sessionId: s.field("sessionId", S.option(S.string)),
      deletedSceneIds: s.field("deletedSceneIds", S.option(S.array(S.string))->S.Option.getOr([])),
      timeline: s.field("timeline", S.option(S.array(timelineItem))->S.Option.getOr([])),
    }
  })

  let transitionTarget = S.object(s => {
    {
      Types.yaw: s.field("yaw", S.float),
      pitch: s.field("pitch", S.float),
      targetName: s.field("targetName", S.string),
      timelineItemId: s.field("timelineItemId", S.option(S.string)),
    }
  })

  let arrivalViewSchema = S.object(s => {
    {
      Types.yaw: s.field("yaw", S.float),
      pitch: s.field("pitch", S.float),
    }
  })

  let step: S.t<Types.step> = S.object(s => {
    {
      idx: s.field("idx", S.int),
      transitionTarget: s.field("transitionTarget", S.option(transitionTarget)),
      arrivalView: s.field("arrivalView", arrivalViewSchema),
    }
  })

  let importScene = S.object(s => {
    {
      id: s.field("id", S.option(S.string)->S.Option.getOr("")),
      name: s.field("name", S.option(S.string)->S.Option.getOr("unknown")),
      file: s.field("file", S.option(file)->S.Option.getOr(Types.Url(""))),
      tinyFile: s.field("tinyFile", S.option(file)),
      originalFile: s.field("originalFile", S.option(file)),
      hotspots: s.field("hotspots", S.option(S.array(hotspot))->S.Option.getOr([])),
      category: "outdoor",
      floor: "ground",
      label: "",
      quality: s.field("quality", S.option(jsonSchema)),
      colorGroup: s.field("colorGroup", S.option(S.string)),
      _metadataSource: "default",
      categorySet: false,
      labelSet: false,
      isAutoForward: false,
    }
  })

  let updateMetadata = S.object(s => {
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
      duration: s.field(
        "duration",
        S.option(S.null(S.float))->S.transform(_ => {
          parser: o => o->Option.map(innerOpt => innerOpt->Option.map(Belt.Float.toInt)),
          serializer: o => o->Option.map(innerOpt => innerOpt->Option.map(Belt.Int.toFloat)),
        }),
      ),
    }
  })

  let pathRequest: S.t<Types.pathRequest> = S.object((s): Types.pathRequest => {
    {
      type_: s.field("type", S.string),
      scenes: s.field("scenes", S.array(scene)),
      skipAutoForward: s.field("skipAutoForward", S.bool),
      timeline: s.field("timeline", S.option(S.array(timelineItem))),
    }
  })

  let sessionState: S.t<Types.sessionState> = S.object((s): Types.sessionState => {
    {
      tourName: s.field("tourName", S.string),
      activeIndex: s.field("activeIndex", S.int),
      activeYaw: s.field("activeYaw", S.float),
      activePitch: s.field("activePitch", S.float),
      isLinking: s.field("isLinking", S.bool),
      isTeasing: s.field("isTeasing", S.bool),
    }
  })
}
