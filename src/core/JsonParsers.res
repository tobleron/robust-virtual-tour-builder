/* src/core/JsonParsers.res */

open JsonCombinators.Json

module Shared = {
  // Aliases to avoid shadowing
  let object = Decode.object
  let field = Decode.field
  let array = Decode.array
  let int = Decode.int
  let float = Decode.float
  let string = Decode.string
  let bool = Decode.bool
  let option = Decode.option
  let map = Decode.map
  let id = Decode.id

  // Custom nullable decoder: maps option(decoder) to Nullable.t
  let toNullable = decoder => {
    map(option(decoder), Nullable.fromOption)
  }

  let gpsData = object(field => {
    {
      SharedTypes.lat: field.optional("lat", option(float))
      ->Option.flatMap(x => x)
      ->Option.getOr(0.0),
      lon: field.optional("lon", option(float))->Option.flatMap(x => x)->Option.getOr(0.0),
    }
  })

  let exifMetadata = object(field => {
    {
      SharedTypes.dateTime: field.optional("date", option(string))
      ->Option.flatMap(x => x)
      ->Nullable.fromOption,
      gps: field.optional("gps", option(gpsData))->Option.flatMap(x => x)->Nullable.fromOption,
      make: field.optional("cameraModel", option(string))
      ->Option.flatMap(x => x)
      ->Nullable.fromOption,
      model: field.optional("lensModel", option(string))
      ->Option.flatMap(x => x)
      ->Nullable.fromOption,
      width: 0,
      height: 0,
      focalLength: field.optional("focalLength", option(float))
      ->Option.flatMap(x => x)
      ->Nullable.fromOption,
      aperture: field.optional("fNumber", option(float))
      ->Option.flatMap(x => x)
      ->Nullable.fromOption,
      iso: field.optional("iso", option(int))->Option.flatMap(x => x)->Nullable.fromOption,
    }
  })

  let colorHist = object(field => {
    let res: SharedTypes.colorHist = {
      r: field.optional("r", option(array(int)))->Option.flatMap(x => x)->Option.getOr([]),
      g: field.optional("g", option(array(int)))->Option.flatMap(x => x)->Option.getOr([]),
      b: field.optional("b", option(array(int)))->Option.flatMap(x => x)->Option.getOr([]),
    }
    res
  })

  let qualityStats = object(field => {
    {
      SharedTypes.avgLuminance: field.optional("avgLuminance", option(int))
      ->Option.flatMap(x => x)
      ->Option.getOr(0),
      blackClipping: field.optional("blackClipping", option(float))
      ->Option.flatMap(x => x)
      ->Option.getOr(0.0),
      whiteClipping: field.optional("whiteClipping", option(float))
      ->Option.flatMap(x => x)
      ->Option.getOr(0.0),
      sharpnessVariance: field.optional("sharpnessVariance", option(int))
      ->Option.flatMap(x => x)
      ->Option.getOr(0),
    }
  })

  let qualityAnalysis = object(field => {
    {
      SharedTypes.score: field.optional("score", option(float))
      ->Option.flatMap(x => x)
      ->Option.getOr(0.0),
      histogram: field.optional("histogram", option(array(int)))
      ->Option.flatMap(x => x)
      ->Option.getOr([]),
      colorHist: field.optional("colorHist", option(colorHist))
      ->Option.flatMap(x => x)
      ->Option.getOr({r: [], g: [], b: []}),
      stats: field.optional("stats", option(qualityStats))
      ->Option.flatMap(x => x)
      ->Option.getOr({
        avgLuminance: 0,
        blackClipping: 0.0,
        whiteClipping: 0.0,
        sharpnessVariance: 0,
      }),
      isBlurry: field.optional("isBlurry", option(bool))
      ->Option.flatMap(x => x)
      ->Option.getOr(false),
      isSoft: field.optional("isSoft", option(bool))->Option.flatMap(x => x)->Option.getOr(false),
      isSeverelyDark: field.optional("isSeverelyDark", option(bool))
      ->Option.flatMap(x => x)
      ->Option.getOr(false),
      isSeverelyBright: field.optional("isSeverelyBright", option(bool))
      ->Option.flatMap(x => x)
      ->Option.getOr(false),
      isDim: field.optional("isDim", option(bool))->Option.flatMap(x => x)->Option.getOr(false),
      hasBlackClipping: field.optional("hasBlackClipping", option(bool))
      ->Option.flatMap(x => x)
      ->Option.getOr(false),
      hasWhiteClipping: field.optional("hasWhiteClipping", option(bool))
      ->Option.flatMap(x => x)
      ->Option.getOr(false),
      issues: field.optional("issues", option(int))->Option.flatMap(x => x)->Option.getOr(0),
      warnings: field.optional("warnings", option(int))->Option.flatMap(x => x)->Option.getOr(0),
      analysis: field.optional("analysis", option(string))
      ->Option.flatMap(x => x)
      ->Nullable.fromOption,
    }
  })

  let metadataResponse = object(field => {
    {
      SharedTypes.exif: field.required("exif", exifMetadata),
      quality: field.required("quality", qualityAnalysis),
      isOptimized: field.optional("isOptimized", bool)->Option.getOr(false),
      checksum: field.optional("checksum", string)->Option.getOr(""),
      suggestedName: field.optional("suggestedName", option(string))
      ->Option.flatMap(x => x)
      ->Nullable.fromOption,
    }
  })

  let similarityResult = object(field => {
    {
      SharedTypes.idA: field.required("sceneId", string),
      idB: "",
      similarity: field.required("score", float),
    }
  })

  let similarityResponse = object(field => {
    {
      SharedTypes.results: field.required("results", array(similarityResult)),
      durationMs: field.required("durationMs", float),
    }
  })

  let validationReport = object(field => {
    {
      SharedTypes.brokenLinksRemoved: field.required("brokenLinksRemoved", int),
      orphanedScenes: field.required("orphanedScenes", array(string)),
      unusedFiles: field.required("unusedFiles", array(string)),
      warnings: field.required("warnings", array(string)),
      errors: field.required("errors", array(string)),
    }
  })

  let geocodeResponse = object(field => {
    {
      SharedTypes.address: field.required("address", string),
    }
  })

  let importResponse = object(field => {
    {
      SharedTypes.sessionId: field.required("sessionId", string),
      projectData: field.required("projectData", id),
    }
  })
}

module Domain = {
  // Aliases
  let object = Decode.object
  let field = Decode.field
  let array = Decode.array
  let int = Decode.int
  let float = Decode.float
  let string = Decode.string
  let bool = Decode.bool
  let option = Decode.option
  let map = Decode.map
  let id = Decode.id

  let file = string->map(s => Types.Url(s))

  let viewFrame = object(field => {
    {
      Types.yaw: field.optional("yaw", option(float))->Option.flatMap(x => x)->Option.getOr(0.0),
      pitch: field.optional("pitch", option(float))->Option.flatMap(x => x)->Option.getOr(0.0),
      hfov: field.optional("hfov", option(float))->Option.flatMap(x => x)->Option.getOr(0.0),
    }
  })

  let hotspot = object(field => {
    {
      Types.linkId: field.optional("linkId", option(string))
      ->Option.flatMap(x => x)
      ->Option.getOr(""),
      yaw: field.optional("yaw", option(float))->Option.flatMap(x => x)->Option.getOr(0.0),
      pitch: field.optional("pitch", option(float))->Option.flatMap(x => x)->Option.getOr(0.0),
      target: field.optional("target", option(string))->Option.flatMap(x => x)->Option.getOr(""),
      targetYaw: field.optional("targetYaw", option(float))->Option.flatMap(x => x),
      targetPitch: field.optional("targetPitch", option(float))->Option.flatMap(x => x),
      targetHfov: field.optional("targetHfov", option(float))->Option.flatMap(x => x),
      startYaw: field.optional("startYaw", option(float))->Option.flatMap(x => x),
      startPitch: field.optional("startPitch", option(float))->Option.flatMap(x => x),
      startHfov: field.optional("startHfov", option(float))->Option.flatMap(x => x),
      isReturnLink: field.optional("isReturnLink", option(bool))->Option.flatMap(x => x),
      viewFrame: field.optional("viewFrame", option(viewFrame))->Option.flatMap(x => x),
      returnViewFrame: field.optional("returnViewFrame", option(viewFrame))->Option.flatMap(x => x),
      waypoints: field.optional("waypoints", option(array(viewFrame)))->Option.flatMap(x => x),
      displayPitch: field.optional("displayPitch", option(float))->Option.flatMap(x => x),
      transition: field.optional("transition", option(string))->Option.flatMap(x => x),
      duration: field.optional("duration", option(float))
      ->Option.flatMap(x => x)
      ->Option.map(Belt.Float.toInt),
    }
  })

  let scene = object(field => {
    {
      Types.id: field.optional("id", option(string))->Option.flatMap(x => x)->Option.getOr(""),
      name: field.optional("name", option(string))->Option.flatMap(x => x)->Option.getOr("unknown"),
      file: field.optional("file", option(file))
      ->Option.flatMap(x => x)
      ->Option.getOr(Types.Url("")),
      tinyFile: field.optional("tinyFile", option(file))->Option.flatMap(x => x),
      originalFile: field.optional("originalFile", option(file))->Option.flatMap(x => x),
      hotspots: field.optional("hotspots", option(array(hotspot)))
      ->Option.flatMap(x => x)
      ->Option.getOr([]),
      category: field.optional("category", option(string))
      ->Option.flatMap(x => x)
      ->Option.getOr("outdoor"),
      floor: field.optional("floor", option(string))
      ->Option.flatMap(x => x)
      ->Option.getOr("ground"),
      label: field.optional("label", option(string))->Option.flatMap(x => x)->Option.getOr(""),
      quality: field.optional("quality", id),
      colorGroup: field.optional("colorGroup", option(string))->Option.flatMap(x => x),
      _metadataSource: field.optional("_metadataSource", option(string))
      ->Option.flatMap(x => x)
      ->Option.getOr("user"),
      categorySet: field.optional("categorySet", option(bool))
      ->Option.flatMap(x => x)
      ->Option.getOr(false),
      labelSet: field.optional("labelSet", option(bool))
      ->Option.flatMap(x => x)
      ->Option.getOr(false),
      isAutoForward: field.optional("isAutoForward", option(bool))
      ->Option.flatMap(x => x)
      ->Option.getOr(false),
    }
  })

  let timelineItem = object(field => {
    {
      Types.id: field.optional("id", option(string))->Option.flatMap(x => x)->Option.getOr(""),
      linkId: field.optional("linkId", option(string))->Option.flatMap(x => x)->Option.getOr(""),
      sceneId: field.optional("sceneId", option(string))->Option.flatMap(x => x)->Option.getOr(""),
      targetScene: field.optional("targetScene", option(string))
      ->Option.flatMap(x => x)
      ->Option.getOr(""),
      transition: field.optional("transition", option(string))
      ->Option.flatMap(x => x)
      ->Option.getOr(""),
      duration: field.optional("duration", option(float))
      ->Option.flatMap(x => x)
      ->Option.map(Belt.Float.toInt)
      ->Option.getOr(0),
    }
  })

  let project = object(field => {
    {
      Types.tourName: field.optional("tourName", option(string))
      ->Option.flatMap(x => x)
      ->Option.getOr("Tour Name"),
      scenes: field.optional("scenes", option(array(scene)))
      ->Option.flatMap(x => x)
      ->Option.getOr([]),
      lastUsedCategory: field.optional("lastUsedCategory", option(string))
      ->Option.flatMap(x => x)
      ->Option.getOr("outdoor"),
      exifReport: field.optional("exifReport", id),
      sessionId: field.optional("sessionId", option(string))->Option.flatMap(x => x),
      deletedSceneIds: field.optional("deletedSceneIds", option(array(string)))
      ->Option.flatMap(x => x)
      ->Option.getOr([]),
      timeline: field.optional("timeline", option(array(timelineItem)))
      ->Option.flatMap(x => x)
      ->Option.getOr([]),
    }
  })

  let transitionTarget = object(field => {
    {
      Types.yaw: field.required("yaw", float),
      pitch: field.required("pitch", float),
      targetName: field.required("targetName", string),
      timelineItemId: field.optional("timelineItemId", option(string))->Option.flatMap(x => x),
    }
  })

  let arrivalView = object(field => {
    {
      Types.yaw: field.required("yaw", float),
      pitch: field.required("pitch", float),
    }
  })

  let step = object(field => {
    {
      Types.idx: field.required("idx", int),
      transitionTarget: field.optional(
        "transitionTarget",
        option(transitionTarget),
      )->Option.flatMap(x => x),
      arrivalView: field.required("arrivalView", arrivalView),
    }
  })

  let steps = array(step)

  let importScene = object(field => {
    {
      Types.id: field.optional("id", option(string))->Option.flatMap(x => x)->Option.getOr(""),
      name: field.optional("name", option(string))->Option.flatMap(x => x)->Option.getOr("unknown"),
      file: field.optional("file", option(file))
      ->Option.flatMap(x => x)
      ->Option.getOr(Types.Url("")),
      tinyFile: field.optional("tinyFile", option(file))->Option.flatMap(x => x),
      originalFile: field.optional("originalFile", option(file))->Option.flatMap(x => x),
      hotspots: field.optional("hotspots", option(array(hotspot)))
      ->Option.flatMap(x => x)
      ->Option.getOr([]),
      category: "outdoor",
      floor: "ground",
      label: "",
      quality: field.optional("quality", id),
      colorGroup: field.optional("colorGroup", option(string))->Option.flatMap(x => x),
      _metadataSource: "default",
      categorySet: false,
      labelSet: false,
      isAutoForward: false,
    }
  })

  let updateMetadata = object(field => {
    {
      Types.category: field.optional("category", option(string))->Option.flatMap(x => x),
      floor: field.optional("floor", option(string))->Option.flatMap(x => x),
      label: field.optional("label", option(string))->Option.flatMap(x => x),
      isAutoForward: field.optional("isAutoForward", option(bool))->Option.flatMap(x => x),
    }
  })

  // SessionState Encoders & Decoders

  module SessionState = {
    let decode = object(field => {
      {
        Types.tourName: field.required("tourName", string),
        activeIndex: field.required("activeIndex", int),
        activeYaw: field.required("activeYaw", float),
        activePitch: field.required("activePitch", float),
        isLinking: field.required("isLinking", bool),
        isTeasing: field.required("isTeasing", bool),
      }
    })

    let encode = (state: Types.sessionState) => {
      Encode.object([
        ("tourName", Encode.string(state.tourName)),
        ("activeIndex", Encode.int(state.activeIndex)),
        ("activeYaw", Encode.float(state.activeYaw)),
        ("activePitch", Encode.float(state.activePitch)),
        ("isLinking", Encode.bool(state.isLinking)),
        ("isTeasing", Encode.bool(state.isTeasing)),
      ])
    }
  }
}

// Encoders for Types (needed for replacements)
module Encoders = {
  let value = (v: JSON.t) => v

  let nullable = (encoder, v: Nullable.t<'a>) => {
    switch Nullable.toOption(v) {
    | Some(x) => encoder(x)
    | None => Encode.null
    }
  }

  let file = (f: Types.file) => {
    switch f {
    | Url(u) => Encode.string(u)
    | Blob(_) | File(_) => Encode.string("")
    }
  }

  let viewFrame = (v: Types.viewFrame) => {
    Encode.object([
      ("yaw", Encode.float(v.yaw)),
      ("pitch", Encode.float(v.pitch)),
      ("hfov", Encode.float(v.hfov)),
    ])
  }

  let hotspot = (h: Types.hotspot) => {
    Encode.object([
      ("linkId", Encode.string(h.linkId)),
      ("yaw", Encode.float(h.yaw)),
      ("pitch", Encode.float(h.pitch)),
      ("target", Encode.string(h.target)),
      ("targetYaw", Encode.option(Encode.float)(h.targetYaw)),
      ("targetPitch", Encode.option(Encode.float)(h.targetPitch)),
      ("targetHfov", Encode.option(Encode.float)(h.targetHfov)),
      ("startYaw", Encode.option(Encode.float)(h.startYaw)),
      ("startPitch", Encode.option(Encode.float)(h.startPitch)),
      ("startHfov", Encode.option(Encode.float)(h.startHfov)),
      ("isReturnLink", Encode.option(Encode.bool)(h.isReturnLink)),
      ("viewFrame", Encode.option(viewFrame)(h.viewFrame)),
      ("returnViewFrame", Encode.option(viewFrame)(h.returnViewFrame)),
      ("waypoints", Encode.option(Encode.array(viewFrame))(h.waypoints)),
      ("displayPitch", Encode.option(Encode.float)(h.displayPitch)),
      ("transition", Encode.option(Encode.string)(h.transition)),
      ("duration", Encode.option(i => Encode.float(Belt.Int.toFloat(i)))(h.duration)),
    ])
  }

  let scene = (s: Types.scene) => {
    Encode.object([
      ("id", Encode.string(s.id)),
      ("name", Encode.string(s.name)),
      ("file", file(s.file)),
      ("tinyFile", Encode.option(file)(s.tinyFile)),
      ("originalFile", Encode.option(file)(s.originalFile)),
      ("hotspots", Encode.array(hotspot)(s.hotspots)),
      ("category", Encode.string(s.category)),
      ("floor", Encode.string(s.floor)),
      ("label", Encode.string(s.label)),
      ("quality", Encode.option(value)(s.quality)),
      ("colorGroup", Encode.option(Encode.string)(s.colorGroup)),
      ("_metadataSource", Encode.string(s._metadataSource)),
      ("categorySet", Encode.bool(s.categorySet)),
      ("labelSet", Encode.bool(s.labelSet)),
      ("isAutoForward", Encode.bool(s.isAutoForward)),
    ])
  }

  let timelineItem = (t: Types.timelineItem) => {
    Encode.object([
      ("id", Encode.string(t.id)),
      ("linkId", Encode.string(t.linkId)),
      ("sceneId", Encode.string(t.sceneId)),
      ("targetScene", Encode.string(t.targetScene)),
      ("transition", Encode.string(t.transition)),
      ("duration", Encode.float(Belt.Int.toFloat(t.duration))),
    ])
  }

  let project = (p: Types.project) => {
    Encode.object([
      ("tourName", Encode.string(p.tourName)),
      ("scenes", Encode.array(scene)(p.scenes)),
      ("lastUsedCategory", Encode.string(p.lastUsedCategory)),
      ("exifReport", Encode.option(value)(p.exifReport)),
      ("sessionId", Encode.option(Encode.string)(p.sessionId)),
      ("deletedSceneIds", Encode.array(Encode.string)(p.deletedSceneIds)),
      ("timeline", Encode.array(timelineItem)(p.timeline)),
    ])
  }

  let pathRequest = (req: Types.pathRequest) => {
    Encode.object([
      ("type", Encode.string(req.type_)),
      ("scenes", Encode.array(scene)(req.scenes)),
      ("skipAutoForward", Encode.bool(req.skipAutoForward)),
      ("timeline", Encode.option(Encode.array(timelineItem))(req.timeline)),
    ])
  }

  let gpsData = (g: SharedTypes.gpsData) => {
    Encode.object([("lat", Encode.float(g.lat)), ("lon", Encode.float(g.lon))])
  }

  let exifMetadata = (m: SharedTypes.exifMetadata) => {
    Encode.object([
      ("date", nullable(Encode.string, m.dateTime)),
      ("gps", nullable(gpsData, m.gps)),
      ("cameraModel", nullable(Encode.string, m.make)),
      ("lensModel", nullable(Encode.string, m.model)),
      ("focalLength", nullable(Encode.float, m.focalLength)),
      ("fNumber", nullable(Encode.float, m.aperture)),
      ("iso", nullable(Encode.int, m.iso)),
      ("width", Encode.int(m.width)),
      ("height", Encode.int(m.height)),
    ])
  }

  let similarityPair = (p: SharedTypes.similarityPair) => {
    Encode.object([
      ("idA", Encode.string(p.idA)),
      ("idB", Encode.string(p.idB)),
      ("histogramA", value(p.histogramA)),
      ("histogramB", value(p.histogramB)),
    ])
  }
}
