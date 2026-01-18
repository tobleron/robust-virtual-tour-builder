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
let extractExifTags = async (file): result<(exifMetadata, gPanoMetadata), string> => {
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

    Ok((exif, pano))
  } catch {
  | exn => {
      let (msg, _stack) = Logger.getErrorDetails(exn)
      Error(msg)
    }
  }
}

/* parseFile - Combined extraction */
let parseFile = async file => {
  let result = await extractExifTags(file)
  switch result {
  | Ok((_exif, pano)) => Ok(pano)
  | Error(msg) => Error(msg)
  }
}

/* extractExifData - Calls the Rust Backend */
let extractExifData = (file: File.t): Promise.t<BackendApi.apiResult<metadataResponse>> => {
  let formData = FormData.newFormData()
  FormData.append(formData, "file", file)

  RequestQueue.schedule(() => {
    Fetch.fetch(
      `${backendUrl}/api/media/extract-metadata`,
      Fetch.requestInit(~method="POST", ~body=formData, ()),
    )
    ->Promise.then(BackendApi.handleResponse)
    ->Promise.then(result => {
      switch result {
      | Ok(res) => Fetch.json(res)->Promise.then(json => Promise.resolve(Ok(Obj.magic(json))))
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
  })
}

/* analyzeImageQuality wrapper */
let analyzeImageQuality = (file: File.t): Promise.t<BackendApi.apiResult<qualityAnalysis>> => {
  extractExifData(file)
  ->Promise.then(result => {
    switch result {
    | Ok(data) => Promise.resolve(Ok(data.quality))
    | Error(msg) => Promise.resolve(Error(msg))
    }
  })
  ->Promise.catch(err => {
    let (msg, _stack) = Logger.getErrorDetails(err)
    Logger.error(
      ~module_="ExifParser",
      ~message="QUALITY_ANALYSIS_FAILED",
      ~data=Logger.castToJson({"error": msg}),
      (),
    )
    Promise.resolve(Error("Analysis failed: " ++ msg))
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
