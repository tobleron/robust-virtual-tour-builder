/* src/systems/ExifParser.res */

open ReBindings
open SharedTypes
open Types

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
let extractExifTags = async (file: Types.file): result<(exifMetadata, gPanoMetadata), string> => {
  try {
    let _tags = switch file {
    | File(f) => await ExifReader.load(f)
    | Blob(b) => await ExifReader.load(b)
    | Url(url) =>
      // For URLs, we need to fetch the blob first
      let res = await Fetch.fetchSimple(url)
      let blob = await Fetch.blob(res)
      await ExifReader.load(blob)
    }

    let _ = _tags // Keep for getValue scope

    let getValue = key => {
      // 1. Try direct match
      switch Dict.get(_tags, key) {
      | Some(t) => String.make(t.description)
      | None => {
          // 2. Try case-insensitive and space-insensitive match
          let normalizedSearch = String.toLowerCase(String.replaceRegExp(key, /\s/g, ""))
          let keys = Dict.toArray(_tags)->Belt.Array.map(((k, _)) => k)
          let foundKey = keys->Belt.Array.getBy(k => {
            let normalizedK = String.toLowerCase(String.replaceRegExp(k, /\s/g, ""))
            normalizedK == normalizedSearch || String.includes(normalizedK, normalizedSearch)
          })

          switch foundKey {
          | Some(k) =>
            switch Dict.get(_tags, k) {
            | Some(t) => String.make(t.description)
            | None => ""
            }
          | None => ""
          }
        }
      }
    }

    let getFloat = key => {
      let v = getValue(key)
      // Robust float parsing: replace commas with dots, remove non-numeric chars (except . and -)
      let step1 = v->String.replaceRegExp(/,/g, ".")
      let cleaned = step1->String.replaceRegExp(/[^0-9.\-]/g, "")

      switch Belt.Float.fromString(cleaned) {
      | Some(f) => Some(f)
      | None => None
      }
    }

    let getInt = key => {
      let v = getValue(key)
      let cleaned = v->String.replaceRegExp(/[^0-9-]/g, "")
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

    let parseGpsCoordinate = (valKey, refKey, xmpKey) => {
      // Try both camelCase, spaced versions, and simple lowercase/short versions
      let rawValues = [
        getValue(valKey),
        getValue(valKey->String.replaceRegExp(/([a-z])([A-Z])/g, "$1 $2")),
        getValue(xmpKey),
        getValue(String.toLowerCase(valKey)),
        getValue(String.replaceRegExp(valKey, /GPS/, "")),
      ]
      let rawVal = rawValues->Belt.Array.getBy(v => v != "")->Option.getOr("")

      let refValues = [
        getValue(refKey),
        getValue(refKey->String.replaceRegExp(/([a-z])([A-Z])/g, "$1 $2")),
      ]
      let ref = refValues->Belt.Array.getBy(v => v != "")->Option.getOr("")->String.toUpperCase

      if rawVal == "" {
        None
      } else {
        // Handle DMS format: "34, 12, 45.6" or "34 deg 12' 45.6\""
        let parts =
          rawVal
          ->String.replaceRegExp(/[deg°'"\s]/g, " ")
          ->String.replaceRegExp(/,/g, " ")
          ->String.split(" ")
          ->Belt.Array.keep(s => String.length(String.trim(s)) > 0)

        let decimalDegrees = if Array.length(parts) >= 3 {
          let d = Belt.Float.fromString(parts[0]->Option.getOr("0"))->Option.getOr(0.0)
          let m = Belt.Float.fromString(parts[1]->Option.getOr("0"))->Option.getOr(0.0)
          let s = Belt.Float.fromString(parts[2]->Option.getOr("0"))->Option.getOr(0.0)
          Some(d +. m /. 60.0 +. s /. 3600.0)
        } else {
          // Fallback to simple float
          let cleaned = rawVal->String.replaceRegExp(/[^0-9.\-]/g, "")
          Belt.Float.fromString(cleaned)
        }

        switch decimalDegrees {
        | Some(deg) =>
          let factor = if (
            ref == "S" || ref == "W" || String.includes(rawVal, "S") || String.includes(rawVal, "W")
          ) {
            -1.0
          } else {
            1.0
          }
          let finalVal = deg *. factor

          // Sanity check: must be +/- 180 (actually +/- 90 for lat, but lon is 180)
          if finalVal >= -180.0 && finalVal <= 180.0 {
            Some(finalVal)
          } else {
            None
          }
        | None => None
        }
      }
    }

    // GPS Extraction with robust fallbacks
    let lat = parseGpsCoordinate("GPSLatitude", "GPSLatitudeRef", "XMP:GPSLatitude")
    let lon = parseGpsCoordinate("GPSLongitude", "GPSLongitudeRef", "XMP:GPSLongitude")

    // COMPREHENSIVE GPS DIAGNOSTIC
    Logger.info(
      ~module_="ExifParser",
      ~message="GPS_EXTRACTION_TRACE",
      ~data=Logger.castToJson({
        "latRaw": getValue("GPSLatitude"),
        "lonRaw": getValue("GPSLongitude"),
        "latRefRaw": getValue("GPSLatitudeRef"),
        "lonRefRaw": getValue("GPSLongitudeRef"),
        "latParsed": lat->Belt.Option.map(Belt.Float.toString)->Belt.Option.getWithDefault("NONE"),
        "lonParsed": lon->Belt.Option.map(Belt.Float.toString)->Belt.Option.getWithDefault("NONE"),
        "willCreateGPS": lat != None && lon != None,
      }),
      (),
    )

    // DIAGNOSTIC: Log keys if GPS is missing to identify camera-specific fields
    if lat == None && lon == None {
      Logger.info(
        ~module_="ExifParser",
        ~message="GPS_MISSING_DIAGNOSTIC",
        ~data=Logger.castToJson({
          "availableKeys": Dict.toArray(_tags)->Belt.Array.map(((k, _)) => k),
          "make": getValue("Make"),
          "model": getValue("Model"),
        }),
        (),
      )
    }

    let gps = switch (lat, lon) {
    | (Some(la), Some(lo)) => {
        Logger.info(
          ~module_="ExifParser",
          ~message="GPS_OBJECT_CREATED",
          ~data=Logger.castToJson({"lat": la, "lon": lo}),
          (),
        )
        Nullable.make(({lat: la, lon: lo}: gpsData))
      }
    | _ => {
        Logger.warn(
          ~module_="ExifParser",
          ~message="GPS_OBJECT_NULL",
          ~data=Logger.castToJson({"reason": "Missing lat or lon"}),
          (),
        )
        Nullable.null
      }
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
      | Ok(res) =>
        Fetch.json(res)->Promise.then(
          json => {
            switch JsonCombinators.Json.decode(json, JsonParsers.Shared.metadataResponse) {
            | Ok(data) => Promise.resolve(Ok(data))
            | Error(e) => Promise.resolve(Error("Metadata parse error: " ++ e))
            }
          },
        )
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

/* fetchFromOsm - Fallback when backend is unavailable */
let fetchFromOsm = async (lat, lon) => {
  let url = `https://nominatim.openstreetmap.org/reverse?format=json&lat=${Float.toString(
      lat,
    )}&lon=${Float.toString(lon)}`
  try {
    let res = await Fetch.fetchSimple(url)
    let json = await Fetch.json(res)
    // Safe decoder for OSM response
    let osmDecoder = JsonCombinators.Json.Decode.object(field => {
      field.required("display_name", JsonCombinators.Json.Decode.string)
    })
    switch JsonCombinators.Json.decode(json, osmDecoder) {
    | Ok(addr) => Ok({address: addr})
    | Error(_) => Error("OSM response missing display_name")
    }
  } catch {
  | exn =>
    let (msg, _) = Logger.getErrorDetails(exn)
    Error("OSM fetch failed: " ++ msg)
  }
}

/* reverseGeocode - PROXIED THROUGH BACKEND WITH CLIENT-SIDE FALLBACK */
let reverseGeocode = async (lat, lon) => {
  let backendResult = await BackendApi.reverseGeocode(lat, lon)
  switch backendResult {
  | Ok(res) => Ok(res)
  | Error(msg) => {
      Logger.warn(
        ~module_="ExifParser",
        ~message="BACKEND_GEOCODE_FAILED_FALLBACK_OSM",
        ~data=Logger.castToJson({"lat": lat, "lon": lon, "backendError": msg}),
        (),
      )
      await fetchFromOsm(lat, lon)
    }
  }
}
