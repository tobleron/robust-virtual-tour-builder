/* src/systems/ExifReport/ExifReportGeneratorLogicExtraction.res */

open ReBindings
open SharedTypes
@@warning("-45")
open ExifReportGeneratorLogicTypes

let resolveExifData = async (item: sceneDataItem) => {
  let _file = item.original
  switch item.metadataJson {
  | Some(m) => {
      // Heuristic: If it's a ReScript record, it won't have the internal JSON structure expected by decoder
      // Actually, since we know it's coming from our own ResizerLogic, it's already an exifMetadata record.
      let meta: SharedTypes.exifMetadata = Obj.magic(m)

      let q: SharedTypes.qualityAnalysis = switch item.qualityJson {
      | Some(qJson) => Obj.magic(qJson)
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
