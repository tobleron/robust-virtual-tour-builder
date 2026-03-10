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

let emptyPano: gPanoMetadata = {
  usePanoramaViewer: false,
  projectionType: "",
  poseHeadingDegrees: 0.0,
  posePitchDegrees: 0.0,
  poseRollDegrees: 0.0,
  croppedAreaImageWidthPixels: 0,
  croppedAreaImageHeightPixels: 0,
  fullPanoWidthPixels: 0,
  fullPanoHeightPixels: 0,
  croppedAreaLeftPixels: 0,
  croppedAreaTopPixels: 0,
  initialViewHeadingDegrees: 0,
}

/* extractExifTags - Extracts full technical metadata and GPS using ExifReader */
let extractExifTags = async (file: Types.file): result<(exifMetadata, gPanoMetadata), string> => {
  try {
    let _tags = await ExifParserSupport.loadTags(
      ~loadFile=f => ExifReader.load(f),
      ~loadBlob=b => ExifReader.load(b),
      file,
    )

    let _ = _tags // Keep for getValue scope
    let keys = Dict.toArray(_tags)->Belt.Array.map(((k, _)) => k)
    let lookupDescription = key => Dict.get(_tags, key)->Option.map(t => String.make(t.description))

    let getValue = key => {
      ExifParserSupport.getValue(~keys, ~lookupDescription, key)
    }

    let getFloat = key => ExifParserSupport.getFloat(~getValue, key)

    let getInt = key => ExifParserSupport.getInt(~getValue, key)

    // GPano Extraction
    let pano: gPanoMetadata = ExifParserSupport.buildPano(~getValue, ~getFloat, ~getInt)

    let parseGpsCoordinate = (valKey, refKey, xmpKey) => {
      ExifParserSupport.parseGpsCoordinate(~getValue, valKey, refKey, xmpKey)
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

    let exif: exifMetadata = ExifParserSupport.buildExif(~getValue, ~getFloat, ~getInt, ~gps)

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

let exifFromWorkerDimensions = (width: int, height: int): (exifMetadata, gPanoMetadata) => {
  let exif: exifMetadata = {
    make: Nullable.null,
    model: Nullable.null,
    dateTime: Nullable.null,
    gps: Nullable.null,
    width,
    height,
    focalLength: Nullable.null,
    aperture: Nullable.null,
    iso: Nullable.null,
  }
  (exif, emptyPano)
}

/* Prefer backend parsing for heavy flows to keep main thread responsive. */
let extractExifTagsPreferred = async (file: Types.file): result<
  (exifMetadata, gPanoMetadata),
  string,
> => {
  switch file {
  | File(f) =>
    switch await extractExifData(f) {
    | Ok(metadata) => Ok((metadata.exif, emptyPano))
    | Error(_) => await extractExifTags(file)
    }
  | Blob(b) =>
    let workerFile = BrowserBindings.File.newFile(
      [b],
      "blob-image",
      {"type": BrowserBindings.Blob.type_(b)},
    )
    switch await WorkerPool.extractExifWithWorker(workerFile) {
    | Some((width, height)) => Ok(exifFromWorkerDimensions(width, height))
    | None => await extractExifTags(file)
    }
  | Url(url) =>
    try {
      let res = await Fetch.fetchSimple(url)
      let blob = await Fetch.blob(res)
      let workerFile = BrowserBindings.File.newFile(
        [blob],
        "url-image",
        {"type": BrowserBindings.Blob.type_(blob)},
      )
      switch await WorkerPool.extractExifWithWorker(workerFile) {
      | Some((width, height)) => Ok(exifFromWorkerDimensions(width, height))
      | None => await extractExifTags(file)
      }
    } catch {
    | _ => await extractExifTags(file)
    }
  }
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
