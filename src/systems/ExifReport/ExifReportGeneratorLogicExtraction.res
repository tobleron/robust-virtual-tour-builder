/* src/systems/ExifReport/ExifReportGeneratorLogicExtraction.res */

open ReBindings
open SharedTypes
@@warning("-45")
open ExifReportGeneratorLogicTypes

let resolveExifData = async (item: sceneDataItem) => {
  let file = item.original
  switch item.metadataJson {
  | Some(m) => {
      // Js.log("Metadata present")
      let meta = switch JsonCombinators.Json.decode(m, JsonParsers.Shared.exifMetadata) {
      | Ok(meta) => meta
      | Error(_) => // Js.log("Decode error: " ++ e)
        SharedTypes.defaultExif
      }

      let hasGps = switch meta.gps->Nullable.toOption {
      | Some(_) => true
      | None => false
      }

      if hasGps {
        let q =
          item.qualityJson
          ->Option.flatMap(q =>
            switch JsonCombinators.Json.decode(q, JsonParsers.Shared.qualityAnalysis) {
            | Ok(qa) => Some(qa)
            | Error(_) => None
            }
          )
          ->Option.getOr(SharedTypes.defaultQuality("Cached metadata loaded"))
        {
          exif: meta,
          quality: q,
          isOptimized: false,
          checksum: "",
          suggestedName: Nullable.null,
        }
      } else {
        // Js.log("No GPS, extracting locally")
        let localRes = await ExifParser.extractExifTagsPreferred(File(file))
        switch localRes {
        | Ok((exif, _pano)) => {
            exif,
            quality: SharedTypes.defaultQuality("GPS recovered locally"),
            isOptimized: false,
            checksum: "",
            suggestedName: Nullable.null,
          }
        | Error(_) => {
            // Js.log("Local extraction error")
            let q =
              item.qualityJson
              ->Option.flatMap(q =>
                switch JsonCombinators.Json.decode(q, JsonParsers.Shared.qualityAnalysis) {
                | Ok(qa) => Some(qa)
                | Error(_) => None
                }
              )
              ->Option.getOr(SharedTypes.defaultQuality("Cached metadata (no GPS)"))
            {
              exif: meta,
              quality: q,
              isOptimized: false,
              checksum: "",
              suggestedName: Nullable.null,
            }
          }
        }
      }
    }
  | None =>
    let localRes = await ExifParser.extractExifTagsPreferred(File(file))
    switch localRes {
    | Ok((exif, _pano)) => {
        exif,
        quality: SharedTypes.defaultQuality("Extracted locally"),
        isOptimized: false,
        checksum: "",
        suggestedName: Nullable.null,
      }
    | Error(msg) => {
        exif: SharedTypes.defaultExif,
        quality: SharedTypes.defaultQuality("Local extraction failed: " ++ msg),
        isOptimized: false,
        checksum: "error",
        suggestedName: Nullable.null,
      }
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
