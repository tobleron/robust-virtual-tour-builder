/* src/systems/ExifReportGeneratorLogic.res */

open ReBindings
open SharedTypes

// --- TYPES ---

type sceneDataItem = {
  original: File.t,
  metadataJson: option<JSON.t>,
  qualityJson: option<JSON.t>,
}

type exifResult = {
  filename: string,
  exifData: exifMetadata,
  qualityData: qualityAnalysis,
}

type reportResult = {
  report: string,
  suggestedProjectName: option<string>,
}

type localExifResult = {
  exif: exifMetadata,
  quality: qualityAnalysis,
  isOptimized: bool,
  checksum: string,
  suggestedName: Nullable.t<string>,
}

type locationAnalysis = {
  centroid: GeoUtils.point,
  outliers: array<GeoUtils.outlier>,
}

// --- UTILS ---

module Utils = {
  let maxInt = (a, b) =>
    if a > b {
      a
    } else {
      b
    }

  external castToDict: JSON.t => dict<JSON.t> = "%identity"
  external castToJson: 'a => JSON.t = "%identity"

  let extractLocationName = (addr: string): option<string> => {
    let words =
      String.split(addr, " ")
      ->Belt.Array.flatMap(w => String.split(w, ","))
      ->Belt.Array.keep(w => String.length(String.trim(w)) > 0)

    let selectedWords =
      Belt.Array.slice(words, ~offset=0, ~len=3)
      ->Belt.Array.map(w => {
        let clean = String.replaceRegExp(w, /[^\p{L}\p{N}]/gu, "")
        if String.length(clean) == 0 {
          ""
        } else {
          let first = String.charAt(clean, 0)->String.toUpperCase
          let rest =
            String.slice(clean, ~start=1, ~end=String.length(clean))->String.toLowerCase
          first ++ rest
        }
      })
      ->Belt.Array.keep(w => String.length(w) > 0)

    if Array.length(selectedWords) > 0 {
      Some(Array.join(selectedWords, "_"))
    } else {
      None
    }
  }

  let generateProjectName = (address: option<string>, dateTime: option<string>): option<string> => {
    let locationPart = switch address {
    | Some(addr) => extractLocationName(addr)
    | None => None
    }

    let timestampPart = switch dateTime {
    | Some(dt) => {
        let regex = RegExp.fromString("(\\d{4}):(\\d{2}):(\\d{2})\\s+(\\d{2}):(\\d{2})")
        switch RegExp.exec(regex, dt) {
        | Some(result) => {
            let captures = RegExp.Result.matches(result)
            let get = i => {
              switch Belt.Array.get(captures, i) {
              | Some(n) => n->Belt.Option.getWithDefault("")
              | None => ""
              }
            }
            if Array.length(captures) >= 5 {
              let year = get(0)
              let month = get(1)
              let day = get(2)
              let hour = get(3)
              let minute = get(4)
              let shortYear = String.slice(year, ~start=2, ~end=4)
              Some(`${day}${month}${shortYear}_${hour}${minute}`)
            } else {
              None
            }
          }
        | None => None
        }
      }
    | None => None
    }

    let timestamp = switch timestampPart {
    | Some(ts) => ts
    | None => {
        let now = Date.make()
        let day = String.padStart(Belt.Int.toString(Date.getDate(now)), 2, "0")
        let month = String.padStart(Belt.Int.toString(Date.getMonth(now) + 1), 2, "0")
        let year = String.slice(Belt.Int.toString(Date.getFullYear(now)), ~start=2, ~end=4)
        let hour = String.padStart(Belt.Int.toString(Date.getHours(now)), 2, "0")
        let minute = String.padStart(Belt.Int.toString(Date.getMinutes(now)), 2, "0")
        `${day}${month}${year}_${hour}${minute}`
      }
    }

    let loc = switch locationPart {
    | Some(l) => l
    | None => "Tour"
    }

    Some(`${loc}_${timestamp}`)
  }

  let downloadExifReport = (content: string): string => {
    let timestamp =
      Date.toISOString(Date.make())
      ->String.replaceRegExp(/[:.]/g, "-")
      ->String.slice(~start=0, ~end=19)

    let filename = `EXIF_METADATA_${timestamp}.txt`
    let blob = Blob.newBlob([content], {"type": "text/plain;charset=utf-8"})
    let url = UrlUtils.safeCreateObjectURL(blob)

    let a = Dom.createElement("a")
    Dom.setAttribute(a, "href", url)
    Dom.setAttribute(a, "download", filename)
    Dom.appendChild(Dom.documentBody, a)
    Dom.click(a)
    Dom.removeElement(a)

    let _ = Window.setTimeout(() => URL.revokeObjectURL(url), 10000)
    filename
  }
}

// --- LOGIC: EXTRACTION ---

module Extraction = {
  let extractAllExif = async (sceneDataList: array<sceneDataItem>) => {
    let exifResults = []
    let gpsPoints: array<GeoUtils.point> = []
    let gpsFilenames: array<string> = []
    let captureDateTime = ref(None)

    for i in 0 to Array.length(sceneDataList) - 1 {
      switch Belt.Array.get(sceneDataList, i) {
      | Some(item) => {
          let file = item.original
          let exifData = switch item.metadataJson {
          | Some(m) => {
              let meta = Schemas.castToExifMetadata(m)
              let hasGps = switch meta.gps->Nullable.toOption {
              | Some(_) => true
              | None => false
              }

              if hasGps {
                let q =
                  item.qualityJson
                  ->Option.map(Schemas.castToQualityAnalysis)
                  ->Option.getOr(defaultQuality("Cached metadata loaded"))
                {
                  exif: meta,
                  quality: q,
                  isOptimized: false,
                  checksum: "",
                  suggestedName: Nullable.null,
                }
              } else {
                let localRes = await ExifParser.extractExifTags(File(file))
                switch localRes {
                | Ok((exif, _pano)) => {
                    exif,
                    quality: defaultQuality("GPS recovered locally"),
                    isOptimized: false,
                    checksum: "",
                    suggestedName: Nullable.null,
                  }
                | Error(_) => {
                    let q =
                      item.qualityJson
                      ->Option.map(Schemas.castToQualityAnalysis)
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

          let gpsOpt = exifData.exif.gps
          switch gpsOpt->Nullable.toOption {
          | Some(gpsDict) => {
              let gpsPoint: GeoUtils.point = {lat: gpsDict.lat, lon: gpsDict.lon}
              let _ = Array.push(gpsPoints, gpsPoint)
              let _ = Array.push(gpsFilenames, File.name(file))
            }
          | None => ()
          }

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
}

// --- LOGIC: LOCATION ---

module Location = {
  let analyzeLocation = async (gpsPoints, gpsFilenames, totalCount, lines) => {
    let resolvedAddress = ref(None)

    if Array.length(gpsPoints) == 0 {
      Logger.warn(
        ~module_="ExifReport",
        ~message="NO_GPS_DATA_FOUND",
        ~data=Some({
          "totalImages": totalCount,
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
      let totalCountStr = Belt.Int.toString(totalCount)

      Logger.info(
        ~module_="ExifReport",
        ~message="GPS_POINTS_COLLECTED",
        ~data=Some({
          "gpsCount": gpsCount,
          "totalCount": totalCountStr,
          "gpsPoints": gpsPoints->Belt.Array.map(p => {"lat": p.lat, "lon": p.lon}),
        }),
        (),
      )

      let _ = Array.push(lines, `  GPS Data Found: ${gpsCount} of ${totalCountStr} images`)
      let _ = Array.push(lines, "")

      let outliers = switch locationAnalysis {
      | Some(analysis) => analysis.outliers
      | None => []
      }

      if Array.length(outliers) > 0 {
        let _ = Array.push(
          lines,
          "  ⚠️  OUTLIERS DETECTED (excluded from average calculation):",
        )
        Belt.Array.forEach(outliers, outlier => {
          let index = outlier.index
          let distance = outlier.distance
          let filename = Belt.Array.get(gpsFilenames, index)->Belt.Option.getWithDefault("Unknown")
          let distanceM = Belt.Int.toString(Float.toInt(distance *. 1000.0))
          let _ = Array.push(lines, `      • ${filename} - ${distanceM}m from cluster center`)
        })
        let _ = Array.push(lines, "")
      }

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

          let _ = Array.push(lines, "  🔍 Address Lookup:")
          Logger.info(
            ~module_="ExifReport",
            ~message="GEOCODING_REQUEST_SENT",
            ~data=Some({"lat": lat, "lon": lon}),
            (),
          )

          let geocodeResult = await ExifParser.reverseGeocode(lat, lon)
          switch geocodeResult {
          | Ok(res) => {
              let address = res.address
              Logger.info(
                ~module_="ExifReport",
                ~message="GEOCODING_SUCCESS",
                ~data=Some({"lat": lat, "lon": lon, "address": address}),
                (),
              )
              let _ = Array.push(lines, `     ${address}`)
              resolvedAddress := Some(address)
            }
          | Error(msg) => {
              Logger.error(
                ~module_="ExifReport",
                ~message="GEOCODING_FAILED",
                ~data=Some({"lat": lat, "lon": lon, "error": msg}),
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
    resolvedAddress.contents
  }
}

// --- LOGIC: GROUPS ---

module Groups = {
  let analyzeGroups = (exifResults, lines) => {
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
      | None => defaultExif
      }

      let dashCount = Utils.maxInt(0, 60 - String.length(signature))
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
  }

  let listIndividualFiles = (exifResults, lines) => {
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
  }
}
