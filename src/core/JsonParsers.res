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
      SharedTypes.lat: field.required("lat", float),
      lon: field.required("lon", float),
    }
  })

  let exifMetadata = object(field => {
    {
      SharedTypes.dateTime: field.optional("date", string)->Nullable.fromOption,
      gps: field.optional("gps", gpsData)->Nullable.fromOption,
      make: field.optional("cameraModel", string)->Nullable.fromOption,
      model: field.optional("lensModel", string)->Nullable.fromOption,
      width: 0,
      height: 0,
      focalLength: field.optional("focalLength", float)->Nullable.fromOption,
      aperture: field.optional("fNumber", float)->Nullable.fromOption,
      iso: field.optional("iso", int)->Nullable.fromOption,
    }
  })

  let colorHist = object(field => {
    let res: SharedTypes.colorHist = {
      r: field.required("r", array(int)),
      g: field.required("g", array(int)),
      b: field.required("b", array(int)),
    }
    res
  })

  let qualityStats = object(field => {
    {
      SharedTypes.avgLuminance: field.required("avgLuminance", int),
      blackClipping: field.required("blackClipping", float),
      whiteClipping: field.required("whiteClipping", float),
      sharpnessVariance: field.required("sharpnessVariance", int),
    }
  })

  let qualityAnalysis = object(field => {
    {
      SharedTypes.score: field.required("score", float),
      histogram: field.required("histogram", array(int)),
      colorHist: field.required("colorHist", colorHist),
      stats: field.required("stats", qualityStats),
      isBlurry: field.required("isBlurry", bool),
      isSoft: field.required("isSoft", bool),
      isSeverelyDark: field.required("isSeverelyDark", bool),
      isSeverelyBright: field.required("isSeverelyBright", bool),
      isDim: field.required("isDim", bool),
      hasBlackClipping: field.required("hasBlackClipping", bool),
      hasWhiteClipping: field.required("hasWhiteClipping", bool),
      issues: field.required("issues", int),
      warnings: field.required("warnings", int),
      analysis: field.optional("analysis", string)->Nullable.fromOption,
    }
  })

  let metadataResponse = object(field => {
    {
      SharedTypes.exif: field.required("exif", exifMetadata),
      quality: field.required("quality", qualityAnalysis),
      isOptimized: field.required("isOptimized", bool),
      checksum: field.required("checksum", string),
      suggestedName: field.optional("suggestedName", string)->Nullable.fromOption,
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
      Types.yaw: field.optional("yaw", float)->Option.getOr(0.0),
      pitch: field.optional("pitch", float)->Option.getOr(0.0),
      hfov: field.optional("hfov", float)->Option.getOr(0.0),
    }
  })

  let hotspot = object(field => {
    {
      Types.linkId: field.optional("linkId", string)->Option.getOr(""),
      yaw: field.optional("yaw", float)->Option.getOr(0.0),
      pitch: field.optional("pitch", float)->Option.getOr(0.0),
      target: field.optional("target", string)->Option.getOr(""),
      targetYaw: field.optional("targetYaw", float),
      targetPitch: field.optional("targetPitch", float),
      targetHfov: field.optional("targetHfov", float),
      startYaw: field.optional("startYaw", float),
      startPitch: field.optional("startPitch", float),
      startHfov: field.optional("startHfov", float),
      isReturnLink: field.optional("isReturnLink", bool),
      viewFrame: field.optional("viewFrame", viewFrame),
      returnViewFrame: field.optional("returnViewFrame", viewFrame),
      waypoints: field.optional("waypoints", array(viewFrame)),
      displayPitch: field.optional("displayPitch", float),
      transition: field.optional("transition", string),
      duration: field.optional("duration", float)->Option.map(Belt.Float.toInt),
    }
  })

  let scene = object(field => {
    {
      Types.id: field.optional("id", string)->Option.getOr(""),
      name: field.optional("name", string)->Option.getOr("unknown"),
      file: field.optional("file", file)->Option.getOr(Types.Url("")),
      tinyFile: field.optional("tinyFile", option(file))->Option.flatMap(x => x),
      originalFile: field.optional("originalFile", option(file))->Option.flatMap(x => x),
      hotspots: field.optional("hotspots", array(hotspot))->Option.getOr([]),
      category: field.optional("category", string)->Option.getOr("outdoor"),
      floor: field.optional("floor", string)->Option.getOr("ground"),
      label: field.optional("label", string)->Option.getOr(""),
      quality: field.optional("quality", id),
      colorGroup: field.optional("colorGroup", string),
      _metadataSource: field.optional("_metadataSource", string)->Option.getOr("user"),
      categorySet: field.optional("categorySet", bool)->Option.getOr(false),
      labelSet: field.optional("labelSet", bool)->Option.getOr(false),
      isAutoForward: field.optional("isAutoForward", bool)->Option.getOr(false),
    }
  })

  let timelineItem = object(field => {
    {
      Types.id: field.optional("id", string)->Option.getOr(""),
      linkId: field.optional("linkId", string)->Option.getOr(""),
      sceneId: field.optional("sceneId", string)->Option.getOr(""),
      targetScene: field.optional("targetScene", string)->Option.getOr(""),
      transition: field.optional("transition", string)->Option.getOr(""),
      duration: field.optional("duration", float)->Option.map(Belt.Float.toInt)->Option.getOr(0),
    }
  })

  let project = object(field => {
    {
      Types.tourName: field.optional("tourName", string)->Option.getOr("Tour Name"),
      scenes: field.optional("scenes", array(scene))->Option.getOr([]),
      lastUsedCategory: field.optional("lastUsedCategory", string)->Option.getOr("outdoor"),
      exifReport: field.optional("exifReport", id),
      sessionId: field.optional("sessionId", string),
      deletedSceneIds: field.optional("deletedSceneIds", array(string))->Option.getOr([]),
      timeline: field.optional("timeline", array(timelineItem))->Option.getOr([]),
    }
  })

  let transitionTarget = object(field => {
    {
      Types.yaw: field.required("yaw", float),
      pitch: field.required("pitch", float),
      targetName: field.required("targetName", string),
      timelineItemId: field.optional("timelineItemId", string),
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
      transitionTarget: field.optional("transitionTarget", transitionTarget),
      arrivalView: field.required("arrivalView", arrivalView),
    }
  })

  let steps = array(step)

  let importScene = object(field => {
    {
      Types.id: field.optional("id", string)->Option.getOr(""),
      name: field.optional("name", string)->Option.getOr("unknown"),
      file: field.optional("file", file)->Option.getOr(Types.Url("")),
      tinyFile: field.optional("tinyFile", option(file))->Option.flatMap(x => x),
      originalFile: field.optional("originalFile", option(file))->Option.flatMap(x => x),
      hotspots: field.optional("hotspots", array(hotspot))->Option.getOr([]),
      category: "outdoor",
      floor: "ground",
      label: "",
      quality: field.optional("quality", id),
      colorGroup: field.optional("colorGroup", string),
      _metadataSource: "default",
      categorySet: false,
      labelSet: false,
      isAutoForward: false,
    }
  })

  let updateMetadata = object(field => {
    {
      Types.category: field.optional("category", string),
      floor: field.optional("floor", string),
      label: field.optional("label", string),
      isAutoForward: field.optional("isAutoForward", bool),
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
