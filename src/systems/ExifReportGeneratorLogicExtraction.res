/* src/systems/ExifReportGeneratorLogicExtraction.res */

open ReBindings
open SharedTypes
open ExifReportGeneratorTypes

let extractAllExif = async (sceneDataList: array<sceneDataItem>) => {
  let exifResults = []
  let gpsPoints: array<GeoUtils.point> = []
  let gpsFilenames: array<string> = []
  let captureDateTime = ref(None)

  for i in 0 to Array.length(sceneDataList) - 1 {
    switch Belt.Array.get(sceneDataList, i) {
    | Some(item) => {
        let file = item.original

        // Use pre-existing metadata if available, but FALLBACK to local extraction if GPS is missing
        let exifData = switch item.metadataJson {
        | Some(m) => {
            let meta = JsonTypes.castToExifMetadata(m)
            let hasGps = switch meta.gps->Nullable.toOption {
            | Some(_) => true
            | None => false
            }

            if hasGps {
              let q =
                item.qualityJson
                ->Option.map(JsonTypes.castToQualityAnalysis)
                ->Option.getOr(defaultQuality("Cached metadata loaded"))
              {
                exif: meta,
                quality: q,
              }
            } else {
              // Metadata present but NO GPS - try local extraction to see if we can find it
              let localRes = await ExifParser.extractExifTags(File(file))
              switch localRes {
              | Ok((exif, _pano)) => {
                  exif: exif, // This might have the GPS we missed
                  quality: defaultQuality("GPS recovered locally"),
                }
              | Error(_) => {
                  // Local failed too, use what we have
                  let q =
                    item.qualityJson
                    ->Option.map(JsonTypes.castToQualityAnalysis)
                    ->Option.getOr(defaultQuality("Cached metadata (no GPS)"))
                  {
                    exif: meta,
                    quality: q,
                  }
                }
              }
            }
          }
        | None =>
          // Extract locally - non-blocking for network
          let localRes = await ExifParser.extractExifTags(File(file))
          switch localRes {
          | Ok((exif, _pano)) => {
              exif: exif,
              quality: defaultQuality("Extracted locally"),
            }
          | Error(msg) => {
              exif: defaultExif,
              quality: defaultQuality("Local extraction failed: " ++ msg),
            }
          }
        }

        let result: exifResult = {
          filename: File.name(file),
          exifData: exifData.exif,
          qualityData: exifData.quality,
        }

        let _ = Array.push(exifResults, result)

        // Check for GPS data
        let gpsOpt = exifData.exif.gps

        switch gpsOpt->Nullable.toOption {
        | Some(gpsDict) => {
            let gpsPoint: GeoUtils.point = {lat: gpsDict.lat, lon: gpsDict.lon}
            let _ = Array.push(gpsPoints, gpsPoint)
            let _ = Array.push(gpsFilenames, File.name(file))
          }
        | None => ()
        }

        // Capture first valid dateTime
        if captureDateTime.contents == None {
          let dateOpt = exifData.exif.dateTime
          switch dateOpt->Nullable.toOption {
          | Some(dt) =>
            if dt != "" {
              captureDateTime := Some(dt)
            }
          | None => ()
          }
        }
      }
    | None => ()
    }
  }

  (exifResults, gpsPoints, gpsFilenames, captureDateTime.contents)
}
