/* src/core/JsonParsers.res */

open JsonCombinators.Json

// Utility alias for the extracted shared parsers
module Shared = JsonParsersShared

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

  // Helper for cleaner optional fields
  let opt = (field: Decode.fieldDecoders, key, decoder, default) => {
    field.optional(key, option(decoder))->Option.flatMap(x => x)->Option.getOr(default)
  }

  let file = string->map(s => Types.Url(s))

  let viewFrame = object(field => {
    {
      Types.yaw: field->opt("yaw", float, 0.0),
      pitch: field->opt("pitch", float, 0.0),
      hfov: field->opt("hfov", float, 0.0),
    }
  })

  let hotspot = object(field => {
    {
      Types.linkId: field->opt("linkId", string, ""),
      yaw: field->opt("yaw", float, 0.0),
      pitch: field->opt("pitch", float, 0.0),
      target: field->opt("target", string, ""),
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
      Types.id: field->opt("id", string, ""),
      name: field->opt("name", string, "unknown"),
      file: field.optional("file", option(file))
      ->Option.flatMap(x => x)
      ->Option.getOr(Types.Url("")),
      tinyFile: field.optional("tinyFile", option(file))->Option.flatMap(x => x),
      originalFile: field.optional("originalFile", option(file))->Option.flatMap(x => x),
      hotspots: field->opt("hotspots", array(hotspot), []),
      category: field->opt("category", string, "outdoor"),
      floor: field->opt("floor", string, "ground"),
      label: field->opt("label", string, ""),
      quality: field.optional("quality", id),
      colorGroup: field.optional("colorGroup", option(string))->Option.flatMap(x => x),
      _metadataSource: field->opt("_metadataSource", string, "user"),
      categorySet: field->opt("categorySet", bool, false),
      labelSet: field->opt("labelSet", bool, false),
      isAutoForward: field->opt("isAutoForward", bool, false),
    }
  })

  let timelineItem = object(field => {
    {
      Types.id: field->opt("id", string, ""),
      linkId: field->opt("linkId", string, ""),
      sceneId: field->opt("sceneId", string, ""),
      targetScene: field->opt("targetScene", string, ""),
      transition: field->opt("transition", string, ""),
      duration: field.optional("duration", option(float))
      ->Option.flatMap(x => x)
      ->Option.map(Belt.Float.toInt)
      ->Option.getOr(0),
    }
  })

  let project = object(field => {
    {
      Types.tourName: field->opt("tourName", string, "Tour Name"),
      scenes: field->opt("scenes", array(scene), []),
      lastUsedCategory: field->opt("lastUsedCategory", string, "outdoor"),
      exifReport: field.optional("exifReport", id),
      sessionId: field.optional("sessionId", option(string))->Option.flatMap(x => x),
      deletedSceneIds: field->opt("deletedSceneIds", array(string), []),
      timeline: field->opt("timeline", array(timelineItem), []),
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
      Types.id: field->opt("id", string, ""),
      name: field->opt("name", string, "unknown"),
      file: field.optional("file", option(file))
      ->Option.flatMap(x => x)
      ->Option.getOr(Types.Url("")),
      tinyFile: field.optional("tinyFile", option(file))->Option.flatMap(x => x),
      originalFile: field.optional("originalFile", option(file))->Option.flatMap(x => x),
      hotspots: field->opt("hotspots", array(hotspot), []),
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
