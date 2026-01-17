/* src/systems/ExifParser.res */

open ReBindings
open SharedTypes

// GPano XMP Tags
// type gPano = SharedTypes.gPanoMetadata

/* Bindings for ExifReader */
module ExifReader = {
  type tag = {description: string}
  type tags = Dict.t<tag>
  @module("exifreader") external load: 'a => promise<tags> = "load"
}

/* Constants */
let backendUrl = Constants.backendUrl

/* extractExifTags - Extracts full technical metadata and GPS using ExifReader */
let extractExifTags = async file => {
  try {
    let _tags = await ExifReader.load(file)

    let getValue = key => {
      switch Dict.get(_tags, key) {
      | Some(t) => t.description
      | None => ""
      }
    }

    let getFloat = key => {
      let v = getValue(key)
      switch Belt.Float.fromString(v) {
      | Some(f) => Some(f)
      | None => None
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
    let pano: gPanoMetadata = {
      usePanoramaViewer: usePano,
      projectionType: getValue("ProjectionType"),
      poseHeadingDegrees: getFloat("PoseHeadingDegrees")->Option.getOr(0.0),
      posePitchDegrees: getFloat("PosePitchDegrees")->Option.getOr(0.0),
      poseRollDegrees: getFloat("PoseRollDegrees")->Option.getOr(0.0),
      croppedAreaImageWidthPixels: getInt("CroppedAreaImageWidthPixels"),
      croppedAreaImageHeightPixels: getInt("CroppedAreaImageHeightPixels"),
      fullPanoWidthPixels: getInt("FullPanoWidthPixels"),
      fullPanoHeightPixels: getInt("FullPanoHeightPixels"),
      croppedAreaLeftPixels: getInt("CroppedAreaLeftPixels"),
      croppedAreaTopPixels: getInt("CroppedAreaTopPixels"),
      initialViewHeadingDegrees: getInt("InitialViewHeadingDegrees"),
    }

    // GPS Extraction
    let lat = getFloat("GPSLatitude")
    let lon = getFloat("GPSLongitude")
    let gps = switch (lat, lon) {
    | (Some(la), Some(lo)) => Nullable.make({lat: la, lon: lo})
    | _ => Nullable.null
    }

    let exif: exifMetadata = {
      make: Nullable.fromOption(Some(getValue("Make"))),
      model: Nullable.fromOption(Some(getValue("Model"))),
      dateTime: Nullable.fromOption(Some(getValue("DateTime"))),
      gps,
      width: getInt("ImageWidth"),
      height: getInt("ImageHeight"),
      focalLength: Nullable.fromOption(getFloat("FocalLength")),
      aperture: Nullable.fromOption(getFloat("FNumber")),
      iso: Nullable.fromOption(Some(getInt("ISOSpeedRatings"))),
    }

    Some((exif, pano))
  } catch {
  | _ => None
  }
}

/* parseFile - Combined extraction */
let parseFile = async file => {
  let result = await extractExifTags(file)
  switch result {
  | Some((_exif, pano)) => Some(pano)
  | None => None
  }
}

/* extractExifData - Calls the Rust Backend */
let extractExifData = (file: File.t): Promise.t<metadataResponse> => {
  let formData = FormData.newFormData()
  FormData.append(formData, "file", file)

  Fetch.fetch(
    `${backendUrl}/api/media/extract-metadata`,
    Fetch.requestInit(~method="POST", ~body=formData, ()),
  )
  ->Promise.then(res => {
    if !Fetch.ok(res) {
      JsError.throwWithMessage("Backend Metadata Extraction Failed")
    } else {
      Fetch.json(res)
    }
  })
  ->Promise.then(json => Promise.resolve(Obj.magic(json)))
}

/* analyzeImageQuality wrapper */
let analyzeImageQuality = (file: File.t): Promise.t<qualityAnalysis> => {
  extractExifData(file)
  ->Promise.then(data => Promise.resolve(data.quality))
  ->Promise.catch(err => {
    Logger.error(
      ~module_="ExifParser",
      ~message="QUALITY_ANALYSIS_FAILED",
      ~data=Logger.castToJson({"error": err}),
      (),
    )
    Promise.resolve(
      Obj.magic({"score": 7.5, "issues": 0, "analysis": Nullable.null, "error": "Analysis failed"}),
    )
  })
}

/* getCameraSignature - Utility function */
let getCameraSignature = (exif: exifMetadata) => {
  let make = switch Nullable.toOption(exif.make) {
  | Some(m) => m
  | None => "Unknown"
  }
  let model = switch Nullable.toOption(exif.model) {
  | Some(m) => m
  | None => "Unknown"
  }
  let width = String.make(exif.width)
  let height = String.make(exif.height)

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
