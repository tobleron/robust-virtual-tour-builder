/* src/systems/ExifReport/ExifReportGeneratorLogicExtraction.res */

open ReBindings
open SharedTypes
@@warning("-45")
open ExifReportGeneratorLogicTypes

external unsafeCastExif: JSON.t => exifMetadata = "%identity"
external unsafeCastQuality: JSON.t => qualityAnalysis = "%identity"

let isLikelyValidExif = (meta: exifMetadata): bool => {
  let gpsLooksValid = switch meta.gps->Nullable.toOption {
  | Some(gps) => Float.isFinite(gps.lat) && Float.isFinite(gps.lon)
  | None => true
  }
  meta.width >= 0 && meta.height >= 0 && gpsLooksValid
}

let isLikelyValidQuality = (q: qualityAnalysis): bool =>
  Float.isFinite(q.score) && q.issues >= 0 && q.warnings >= 0

let decodeExifMetadata = (json: JSON.t): exifMetadata =>
  switch JsonCombinators.Json.decode(json, JsonParsersShared.exifMetadata) {
  | Ok(meta) => meta
  | Error(e) =>
    switch JsonCombinators.Json.decode(json, JsonParsersShared.metadataResponse) {
    | Ok(metaResponse) => metaResponse.exif
    | Error(wrapperError) =>
      let casted = unsafeCastExif(json)
      if isLikelyValidExif(casted) {
        Logger.warn(
          ~module_="ExifExtraction",
          ~message="EXIF_METADATA_DECODE_FALLBACK_CAST",
          ~data={"error": e, "wrapperError": wrapperError},
          (),
        )
        casted
      } else {
        Logger.warn(
          ~module_="ExifExtraction",
          ~message="EXIF_METADATA_DECODE_FAILED",
          ~data={"error": e, "wrapperError": wrapperError},
          (),
        )
        SharedTypes.defaultExif
      }
    }
  }

let decodeQualityAnalysis = (json: JSON.t): qualityAnalysis =>
  switch JsonCombinators.Json.decode(json, JsonParsersShared.qualityAnalysis) {
  | Ok(q) => q
  | Error(e) =>
    switch JsonCombinators.Json.decode(json, JsonParsersShared.metadataResponse) {
    | Ok(metaResponse) => metaResponse.quality
    | Error(wrapperError) =>
      let casted = unsafeCastQuality(json)
      if isLikelyValidQuality(casted) {
        Logger.warn(
          ~module_="ExifExtraction",
          ~message="QUALITY_ANALYSIS_DECODE_FALLBACK_CAST",
          ~data={"error": e, "wrapperError": wrapperError},
          (),
        )
        casted
      } else {
        Logger.warn(
          ~module_="ExifExtraction",
          ~message="QUALITY_ANALYSIS_DECODE_FAILED",
          ~data={"error": e, "wrapperError": wrapperError},
          (),
        )
        SharedTypes.defaultQuality("Quality decode failed")
      }
    }
  }

let resolveExifData = async (item: sceneDataItem) => {
  let _file = item.original
  switch item.metadataJson {
  | Some(m) => {
      let meta = decodeExifMetadata(m)

      let q = switch item.qualityJson {
      | Some(qJson) => decodeQualityAnalysis(qJson)
      | None => SharedTypes.defaultQuality("Metadata loaded from internal state")
      }

      {
        exif: meta,
        quality: q,
        isOptimized: false,
        checksum: "",
        suggestedName: Nullable.null,
      }
    }
  | None => // STRICT MODE: Skip local extraction to prevent RAM spikes on large files.
    // If metadata wasn't provided by the backend, we simply return defaults.
    {
      exif: SharedTypes.defaultExif,
      quality: SharedTypes.defaultQuality("Metadata unavailable (Strict Mode)"),
      isOptimized: false,
      checksum: "",
      suggestedName: Nullable.null,
    }
  }
}

let processSceneDataItem = async (item: sceneDataItem) => {
  let file = item.original
  let exifData = await resolveExifData(item)

  let result: exifResult = {
    filename: File.name(file),
    exifData: exifData.exif,
    qualityData: exifData.quality,
  }

  let gpsPoint = switch exifData.exif.gps->Nullable.toOption {
  | Some(gpsDict) => Some({GeoUtils.lat: gpsDict.lat, lon: gpsDict.lon})
  | None => None
  }

  let dateTime = switch exifData.exif.dateTime->Nullable.toOption {
  | Some(dt) =>
    if dt != "" {
      Some(dt)
    } else {
      None
    }
  | None => None
  }

  (result, gpsPoint, File.name(file), dateTime)
}

let extractAllExif = async (sceneDataList: array<sceneDataItem>) => {
  let exifResults = []
  let gpsPoints: array<GeoUtils.point> = []
  let gpsFilenames: array<string> = []
  let captureDateTime = ref(None)

  for i in 0 to Array.length(sceneDataList) - 1 {
    switch Belt.Array.get(sceneDataList, i) {
    | Some(item) => {
        let (result, gpsOpt, filename, dtOpt) = await processSceneDataItem(item)
        let _ = Array.push(exifResults, result)

        switch gpsOpt {
        | Some(p) =>
          let _ = Array.push(gpsPoints, p)
          let _ = Array.push(gpsFilenames, filename)
        | None => ()
        }

        if captureDateTime.contents == None {
          captureDateTime := dtOpt
        }
      }
    | None => ()
    }
  }
  (exifResults, gpsPoints, gpsFilenames, captureDateTime.contents)
}
