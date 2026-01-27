/* src/systems/ExifReportGeneratorLogic.res */

open ReBindings
open SharedTypes
open ExifReportGeneratorTypes
open ExifReportGeneratorUtils

/**
 * Generate EXIF metadata report from uploaded files
 */
let generateExifReport = async (sceneDataList: array<sceneDataItem>) => {
  Logger.initialized(~module_="ExifReportGeneratorLogic")
  let lines = []
  let resolvedAddress = ref(None)
  let captureDateTime = ref(None)

  // Header
  let _ = Array.push(
    lines,
    "╔══════════════════════════════════════════════════════════════════════════════╗",
  )
  let _ = Array.push(
    lines,
    "║                          EXIF METADATA ANALYSIS REPORT                       ║",
  )
  let _ = Array.push(
    lines,
    "╠══════════════════════════════════════════════════════════════════════════════╣",
  )

  let now = Date.make()
  let dateStr = Date.toLocaleString(now)
  let padded = String.padEnd(dateStr, 63, " ")
  let _ = Array.push(lines, `║  Generated: ${padded}║`)

  let count = Belt.Int.toString(Array.length(sceneDataList))
  let countPadded = String.padEnd(count, 52, " ")
  let _ = Array.push(lines, `║  Total Files Analyzed: ${countPadded}║`)
  let _ = Array.push(
    lines,
    "╚══════════════════════════════════════════════════════════════════════════════╝",
  )
  let _ = Array.push(lines, "")

  // Extract EXIF from all files
  let exifResults = []
  let gpsPoints: array<GeoUtils.point> = []
  let gpsFilenames: array<string> = []

  let processItems = async () => {
    for i in 0 to Array.length(sceneDataList) - 1 {
      switch Belt.Array.get(sceneDataList, i) {
      | Some(item) =>
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
                isOptimized: false,
                checksum: "",
                suggestedName: Nullable.null,
              }
            } else {
              // Metadata present but NO GPS - try local extraction to see if we can find it
              let localRes = await ExifParser.extractExifTags(File(file))
              switch localRes {
              | Ok((exif, _pano)) => {
                  exif, // This might have the GPS we missed
                  quality: defaultQuality("GPS recovered locally"),
                  isOptimized: false,
                  checksum: "",
                  suggestedName: Nullable.null,
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
                    isOptimized: false,
                    checksum: "",
                    suggestedName: Nullable.null,
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
              exif,
              quality: defaultQuality("Extracted locally"),
              isOptimized: false,
              checksum: "",
              suggestedName: Nullable.null,
            }
          | Error(msg) => {
              exif: defaultExif,
              quality: defaultQuality("Local extraction failed: " ++ msg),
              isOptimized: false,
              checksum: "error",
              suggestedName: Nullable.null,
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
      | None => ()
      }
    }
  }

  await processItems()

  // ─────────────────────────────────────────────────────────────────
  // SECTION 1: LOCATION ANALYSIS
  // ─────────────────────────────────────────────────────────────────
  let _ = Array.push(
    lines,
    "┌──────────────────────────────────────────────────────────────────────────────┐",
  )
  let _ = Array.push(
    lines,
    "│  📍 LOCATION ANALYSIS                                                        │",
  )
  let _ = Array.push(
    lines,
    "└──────────────────────────────────────────────────────────────────────────────┘",
  )
  let _ = Array.push(lines, "")

  if Array.length(gpsPoints) == 0 {
    Logger.warn(
      ~module_="ExifReport",
      ~message="NO_GPS_DATA_FOUND",
      ~data=Some({
        "totalImages": Array.length(sceneDataList),
        "reason": "No GPS coordinates in EXIF metadata",
      }),
      (),
    )
    let _ = Array.push(lines, "  ⚠️  No GPS data found in any uploaded images.")
    let _ = Array.push(lines, "      Images may have been taken with location services disabled,")
    let _ = Array.push(lines, "      or GPS metadata was stripped during processing.")
    let _ = Array.push(lines, "")
  } else {
    let locationAnalysis = ExifParser.calculateAverageLocation(gpsPoints, ~maxDistanceKm=0.5, ())

    let gpsCount = Belt.Int.toString(Array.length(gpsPoints))
    let totalCount = Belt.Int.toString(Array.length(sceneDataList))

    Logger.info(
      ~module_="ExifReport",
      ~message="GPS_POINTS_COLLECTED",
      ~data=Some({
        "gpsCount": gpsCount,
        "totalCount": totalCount,
        "gpsPoints": gpsPoints->Belt.Array.map(p =>
          {
            "lat": p.lat,
            "lon": p.lon,
          }
        ),
      }),
      (),
    )

    let _ = Array.push(lines, `  GPS Data Found: ${gpsCount} of ${totalCount} images`)
    let _ = Array.push(lines, "")

    // Check for outliers
    let outliers = switch locationAnalysis {
    | Some(analysis) => analysis.outliers
    | None => []
    }

    if Array.length(outliers) > 0 {
      let _ = Array.push(lines, "  ⚠️  OUTLIERS DETECTED (excluded from average calculation):")
      Belt.Array.forEach(outliers, outlier => {
        let index = outlier.index
        let distance = outlier.distance
        let filename = Belt.Array.get(gpsFilenames, index)->Belt.Option.getWithDefault("Unknown")
        let distanceM = Belt.Int.toString(Float.toInt(distance *. 1000.0))
        let _ = Array.push(lines, `      • ${filename} - ${distanceM}m from cluster center`)
      })
      let _ = Array.push(lines, "")
    }

    // Centroid
    switch locationAnalysis {
    | Some(analysis) => {
        let centroid = analysis.centroid
        let lat = centroid.lat
        let lon = centroid.lon

        let _ = Array.push(lines, `  📍 Estimated Property Location:`)
        let _ = Array.push(lines, `     Latitude:  ${Float.toFixed(lat, ~digits=6)}`)
        let _ = Array.push(lines, `     Longitude: ${Float.toFixed(lon, ~digits=6)}`)
        let _ = Array.push(
          lines,
          `     Google Maps: https://maps.google.com/?q=${Float.toString(lat)},${Float.toString(
              lon,
            )}`,
        )
        let _ = Array.push(lines, "")

        // Reverse geocode
        let _ = Array.push(lines, "  🔍 Address Lookup:")

        Logger.info(
          ~module_="ExifReport",
          ~message="GEOCODING_REQUEST_SENT",
          ~data=Some({"lat": lat, "lon": lon}),
          (),
        )

        let geocodeResult = await ExifParser.reverseGeocode(lat, lon)

        switch geocodeResult {
        | Ok(address) => {
            Logger.info(
              ~module_="ExifReport",
              ~message="GEOCODING_SUCCESS",
              ~data=Some({
                "lat": lat,
                "lon": lon,
                "address": address,
              }),
              (),
            )
            let _ = Array.push(lines, `     ${address}`)
            resolvedAddress := Some(address)
          }
        | Error(msg) => {
            Logger.error(
              ~module_="ExifReport",
              ~message="GEOCODING_FAILED",
              ~data=Some({
                "lat": lat,
                "lon": lon,
                "error": msg,
              }),
              (),
            )
            let _ = Array.push(lines, `     [Geocoding failed: ${msg}]`)
            let _ = Array.push(
              lines,
              "     (This does not affect your virtual tour - geocoding is informational only)",
            )
          }
        }
        let _ = Array.push(lines, "")
      }
    | None => ()
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // SECTION 2: CAMERA/DEVICE GROUPING
  // ─────────────────────────────────────────────────────────────────
  let _ = Array.push(
    lines,
    "┌──────────────────────────────────────────────────────────────────────────────┐",
  )
  let _ = Array.push(
    lines,
    "│  📷 CAMERA & DEVICE ANALYSIS                                                 │",
  )
  let _ = Array.push(
    lines,
    "└──────────────────────────────────────────────────────────────────────────────┘",
  )
  let _ = Array.push(lines, "")

  // Group by camera signature
  let groups = Dict.make()
  Belt.Array.forEach(exifResults, r => {
    let sig = ExifParser.getCameraSignature(r.exifData)
    switch Dict.get(groups, sig) {
    | Some(files) => {
        let _ = Array.push(files, r)
      }
    | None => Dict.set(groups, sig, [r])
    }
  })

  Belt.Array.forEach(Dict.toArray(groups), ((signature, files)) => {
    let firstExif = switch Belt.Array.get(files, 0) {
    | Some(r) => r.exifData
    | None => defaultExif // Should not happen
    }

    let dashCount = maxInt(0, 60 - String.length(signature))
    let dashes = String.repeat("─", dashCount)
    let _ = Array.push(lines, `  ┌─ ${signature} ─${dashes}`)
    let _ = Array.push(lines, `  │  Images: ${Belt.Int.toString(Array.length(files))}`)

    switch firstExif.focalLength->Nullable.toOption {
    | Some(fl) => {
        let _ = Array.push(lines, `  │  Focal Length: ${Float.toFixed(fl, ~digits=1)}mm`)
      }
    | None => ()
    }

    switch firstExif.aperture->Nullable.toOption {
    | Some(ap) => {
        let _ = Array.push(lines, `  │  Aperture: f/${Float.toFixed(ap, ~digits=1)}`)
      }
    | None => ()
    }

    switch firstExif.iso->Nullable.toOption {
    | Some(iso) => {
        let _ = Array.push(lines, `  │  ISO: ${Belt.Int.toString(iso)}`)
      }
    | None => ()
    }

    switch firstExif.dateTime->Nullable.toOption {
    | Some(dt) => {
        let _ = Array.push(lines, `  │  Capture Period: ${dt}`)
      }
    | None => ()
    }

    let _ = Array.push(lines, `  │`)
    let _ = Array.push(lines, `  │  Files:`)
    Belt.Array.forEach(files, r => {
      let _ = Array.push(lines, `  │    • ${r.filename}`)
    })
    let _ = Array.push(lines, `  └${String.repeat("─", 76)}`)
    let _ = Array.push(lines, "")
  })

  // ─────────────────────────────────────────────────────────────────
  // SECTION 3: DETAILED FILE LIST
  // ─────────────────────────────────────────────────────────────────
  let _ = Array.push(
    lines,
    "┌──────────────────────────────────────────────────────────────────────────────┐",
  )
  let _ = Array.push(
    lines,
    "│  📋 INDIVIDUAL FILE METADATA                                                 │",
  )
  let _ = Array.push(
    lines,
    "└──────────────────────────────────────────────────────────────────────────────┘",
  )
  let _ = Array.push(lines, "")

  Belt.Array.forEach(exifResults, r => {
    let hasGPS = switch r.exifData.gps->Nullable.toOption {
    | Some(_) => "✓ GPS"
    | None => "✗ No GPS"
    }

    let hasCamera = {
      let make = switch r.exifData.make->Nullable.toOption {
      | Some(m) => m
      | None => ""
      }
      let model = switch r.exifData.model->Nullable.toOption {
      | Some(m) => m
      | None => ""
      }
      let combined = String.trim(make ++ " " ++ model)
      if combined == "" {
        "Unknown Device"
      } else {
        combined
      }
    }

    let qScore = `| Quality: ${Float.toFixed(r.qualityData.score, ~digits=1)}/10`

    let _ = Array.push(lines, `  ${r.filename}`)
    let _ = Array.push(lines, `    └─ ${hasCamera} | ${hasGPS} ${qScore}`)

    switch r.qualityData.analysis->Nullable.toOption {
    | Some(analysis) => {
        let _ = Array.push(lines, `       Note: ${analysis}`)
      }
    | None => ()
    }
  })

  let _ = Array.push(lines, "")
  let _ = Array.push(lines, String.repeat("═", 80))
  let _ = Array.push(lines, "END OF REPORT")
  let _ = Array.push(lines, String.repeat("═", 80))

  // Generate suggested project name
  let suggestedName = generateProjectName(resolvedAddress.contents, captureDateTime.contents)

  Logger.info(
    ~module_="ExifReport",
    ~message="PROJECT_NAME_GENERATED_FROM_EXIF",
    ~data=Some({
      "suggestedName": suggestedName->Option.getOr("None"),
      "hasAddress": resolvedAddress.contents != None,
      "hasDateTime": captureDateTime.contents != None,
      "address": resolvedAddress.contents->Option.getOr("None"),
      "dateTime": captureDateTime.contents->Option.getOr("None"),
    }),
    (),
  )

  {
    report: Array.join(lines, "\n"),
    suggestedProjectName: suggestedName,
  }
}
