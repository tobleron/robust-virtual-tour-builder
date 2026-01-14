/* src/systems/ExifParser.res */

// GPano XMP Tags
type gPano = {
  mutable usePanoramaViewer: bool,
  mutable projectionType: string,
  mutable poseHeadingDegrees: float,
  mutable posePitchDegrees: float,
  mutable poseRollDegrees: float,
  mutable croppedAreaImageWidthPixels: int,
  mutable croppedAreaImageHeightPixels: int,
  mutable fullPanoWidthPixels: int,
  mutable fullPanoHeightPixels: int,
  mutable croppedAreaLeftPixels: int,
  mutable croppedAreaTopPixels: int,
  mutable initialViewHeadingDegrees: int,
}

/* Bindings for ExifReader */
module ExifReader = {
  type t
  @module("exifreader") external load: 'a => promise<t> = "load"
}

/* Constants */
let backendUrl = Constants.backendUrl

/* Bindings for Fetch */
@val external fetch: (string, 'a) => promise<JSON.t> = "fetch"

/* extractExifTags - IMPLEMENTED per task requirement using ExifReader */
let extractExifTags = async file => {
  try {
    let _tags = await ExifReader.load(file)

    let getValue = _key => {
      let tag = %raw(`_tags[_key]`)
      switch Nullable.toOption(tag) {
      | Some(t) =>
        let desc = (Obj.magic(t): {..})["description"]
        switch Nullable.toOption(desc) {
        | Some(d) => d
        | None => ""
        }
      | None => ""
      }
    }

    let getFloat = key => {
      let v = getValue(key)
      switch Belt.Float.fromString(v) {
      | Some(f) => f
      | None => 0.0
      }
    }

    let getInt = key => {
      let v = getValue(key)
      let cleaned = Js.String.replaceByRe(/[^0-9-]/g, "", v)
      switch Belt.Int.fromString(cleaned) {
      | Some(i) => i
      | None => 0
      }
    }

    // GPano Extraction
    let usePano = getValue("UsePanoramaViewer") == "True"

    let pano: gPano = {
      usePanoramaViewer: usePano,
      projectionType: getValue("ProjectionType"),
      poseHeadingDegrees: getFloat("PoseHeadingDegrees"),
      posePitchDegrees: getFloat("PosePitchDegrees"),
      poseRollDegrees: getFloat("PoseRollDegrees"),
      croppedAreaImageWidthPixels: getInt("CroppedAreaImageWidthPixels"),
      croppedAreaImageHeightPixels: getInt("CroppedAreaImageHeightPixels"),
      fullPanoWidthPixels: getInt("FullPanoWidthPixels"),
      fullPanoHeightPixels: getInt("FullPanoHeightPixels"),
      croppedAreaLeftPixels: getInt("CroppedAreaLeftPixels"),
      croppedAreaTopPixels: getInt("CroppedAreaTopPixels"),
      initialViewHeadingDegrees: getInt("InitialViewHeadingDegrees"),
    }

    Some(pano)
  } catch {
  | _ => None
  }
}

/* parseFile - Combined extraction */
let parseFile = async file => {
  let gpano = await extractExifTags(file)
  gpano
}

/* extractExifData - Calls the Rust Backend */
let extractExifData = _file => {
  let formData = %raw(`new FormData()`)
  let _ = %raw(`formData.append("file", _file)`)

  fetch(
    `${backendUrl}/extract-metadata`,
    {
      "method": "POST",
      "body": formData,
    },
  )->Promise.then(res => {
    let response = (Obj.magic(res): {..})
    if !response["ok"] {
      JsError.throwWithMessage("Backend Metadata Extraction Failed")
    } else {
      response["json"]()
    }
  })
}

/* analyzeImageQuality wrapper */
let analyzeImageQuality = file => {
  extractExifData(file)->Promise.then(data => {
    let d = (Obj.magic(data): {..})
    switch Nullable.toOption(d["error"]) {
    | Some(err) =>
      Promise.resolve(Obj.magic({"score": 7.5, "issues": 0, "analysis": null, "error": err}))
    | None => Promise.resolve(d["quality"])
    }
  })
}

/* calculateSimilarity - Wrapper for ImageAnalysis */
let calculateSimilarity = (resultA, resultB) => {
  ImageAnalysis.calculateSimilarity(Obj.magic(resultA), Obj.magic(resultB))
}

/* getCameraSignature - Utility function */
let getCameraSignature = (exif: JSON.t) => {
  let e = (Obj.magic(exif): {..})
  let make = switch Nullable.toOption(e["make"]) {
  | Some(m) => m
  | None => "Unknown"
  }
  let model = switch Nullable.toOption(e["model"]) {
  | Some(m) => m
  | None => "Unknown"
  }
  let width = switch Nullable.toOption(e["width"]) {
  | Some(w) => String.make(w)
  | None => "Unknown"
  }
  let height = switch Nullable.toOption(e["height"]) {
  | Some(h) => String.make(h)
  | None => "Unknown"
  }

  make ++ " " ++ model ++ " @ " ++ width ++ "x" ++ height
}

/* calculateAverageLocation - Wrapper for GeoUtils */
let calculateAverageLocation = (gpsPoints, ~maxDistanceKm=0.5, ()) => {
  GeoUtils.calculateAverageLocation(gpsPoints, maxDistanceKm)
}

/* reverseGeocode - NOW PROXIED THROUGH BACKEND */
let reverseGeocode = (lat, lon) => {
  BackendApi.reverseGeocode(lat, lon)
}
