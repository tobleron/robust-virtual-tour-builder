/* src/systems/ExifReportGenerator.res */

open ReBindings

type sceneDataItem = {
  original: File.t,
  metadata: option<JSON.t>,
  quality: option<JSON.t>,
}

type exifResult = {
  filename: string,
  exif: JSON.t,
  quality: JSON.t,
}

type reportResult = {
  report: string,
  suggestedName: string,
}

let max_int = (a, b) =>
  if a > b {
    a
  } else {
    b
  }

/**
 * Generate a smart project identification name
 * Format: Word1_Word2_Word3_DDMMYYHH_SSSSS
 */
let generateProjectName = (address: option<string>, dateTime: option<string>): string => {
  // 1. Extract first 3 words from address
  let locationPart = switch address {
  | Some(addr) => {
      let words =
        Js.String.splitByRe(/[\\s,]+/, addr)
        ->Belt.Array.keepMap(x => x)
        ->Belt.Array.keep(w => String.length(w) > 0)

      let selectedWords =
        Belt.Array.slice(words, ~offset=0, ~len=3)
        ->Belt.Array.map(w => {
          // Remove non-alphanumeric
          let clean = Js.String.replaceByRe(/[^a-zA-Z0-9]/g, "", w)
          if String.length(clean) == 0 {
            ""
          } else {
            let first = String.charAt(clean, 0)->String.toUpperCase
            let rest = String.slice(clean, ~start=1, ~end=String.length(clean))->String.toLowerCase
            first ++ rest
          }
        })
        ->Belt.Array.keep(w => String.length(w) > 0)

      if Array.length(selectedWords) > 0 {
        Js.Array.joinWith("_", selectedWords)
      } else {
        "Unknown_Location"
      }
    }
  | None => "Unknown_Location"
  }

  // 2. Generate compact timestamp DDMMYY_HHMM
  let timestampPart = switch dateTime {
  | Some(dt) => {
      let regex = /(\\d{4}):(\\d{2}):(\\d{2})\\s+(\\d{2}):(\\d{2})/
      switch RegExp.exec(regex, dt) {
      | Some(result) => {
          let captures = RegExp.Result.matches(result)
          let get = i => {
            switch Belt.Array.get(captures, i) {
            | Some(n) => n->Belt.Option.getWithDefault("")
            | None => ""
            }
          }
          if Array.length(captures) >= 6 {
            let year = get(1)
            let month = get(2)
            let day = get(3)
            let hour = get(4)
            let minute = get(5)
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
      // Fallback to current time
      let now = Date.make()
      let day = String.padStart(Belt.Int.toString(Date.getDate(now)), 2, "0")
      let month = String.padStart(Belt.Int.toString(Date.getMonth(now) + 1), 2, "0")
      let year = String.slice(Belt.Int.toString(Date.getFullYear(now)), ~start=2, ~end=4)
      let hour = String.padStart(Belt.Int.toString(Date.getHours(now)), 2, "0")
      let minute = String.padStart(Belt.Int.toString(Date.getMinutes(now)), 2, "0")
      `${day}${month}${year}_${hour}${minute}`
    }
  }

  `${locationPart}_${timestamp}`
}

/**
 * Generate EXIF metadata report from uploaded files
 */
let generateExifReport = async (sceneDataList: array<sceneDataItem>): Promise.t<reportResult> => {
  let lines = []
  let resolvedAddress = ref(None)
  let captureDateTime = ref(None)

  // Header
  let _ = Js.Array.push(
    "╔══════════════════════════════════════════════════════════════════════════════╗",
    lines,
  )
  let _ = Js.Array.push(
    "║                          EXIF METADATA ANALYSIS REPORT                       ║",
    lines,
  )
  let _ = Js.Array.push(
    "╠══════════════════════════════════════════════════════════════════════════════╣",
    lines,
  )

  let now = Date.make()
  let dateStr = Date.toLocaleString(now)
  let padded = String.padEnd(dateStr, 63, " ")
  let _ = Js.Array.push(`║  Generated: ${padded}║`, lines)

  let count = Belt.Int.toString(Array.length(sceneDataList))
  let countPadded = String.padEnd(count, 52, " ")
  let _ = Js.Array.push(`║  Total Files Analyzed: ${countPadded}║`, lines)
  let _ = Js.Array.push(
    "╚══════════════════════════════════════════════════════════════════════════════╝",
    lines,
  )
  let _ = Js.Array.push("", lines)

  // Extract EXIF from all files
  let exifResults = []
  let gpsPoints: array<GeoUtils.point> = []
  let gpsFilenames: array<string> = []

  let processItems = async () => {
    for i in 0 to Array.length(sceneDataList) - 1 {
      let item = Belt.Array.getExn(sceneDataList, i)
      let file = item.original

      // Use pre-existing metadata if available
      let exif = switch item.metadata {
      | Some(m) => Promise.resolve(m)
      | None => ExifParser.extractExifData(file)
      }

      let exifData = await exif

      let quality = switch item.quality {
      | Some(q) => Promise.resolve(q)
      | None => {
          let metaObj = (Obj.magic(exifData): {..})
          switch Nullable.toOption(metaObj["quality"]) {
          | Some(q) => Promise.resolve(q)
          | None => ExifParser.analyzeImageQuality(file)
          }
        }
      }

      let qualityData = await quality

      let result: exifResult = {
        filename: File.name(file),
        exif: exifData,
        quality: qualityData,
      }

      let _ = Js.Array.push(result, exifResults)

      // Check for GPS data
      let exifObj = (Obj.magic(exifData): {..})
      switch Nullable.toOption(exifObj["gps"]) {
      | Some(gps) => {
          let gpsObj = (Obj.magic(gps): {..})
          let lat: float = gpsObj["lat"]
          let lon: float = gpsObj["lon"]
          let gpsPoint: GeoUtils.point = {lat, lon}
          let _ = Js.Array.push(gpsPoint, gpsPoints)
          let _ = Js.Array.push(File.name(file), gpsFilenames)
        }
      | None => ()
      }

      // Capture first valid dateTime
      if captureDateTime.contents == None {
        switch Nullable.toOption(exifObj["dateTime"]) {
        | Some(dt) => captureDateTime := Some(dt)
        | None => ()
        }
      }
    }
  }

  await processItems()

  // ─────────────────────────────────────────────────────────────────
  // SECTION 1: LOCATION ANALYSIS
  // ─────────────────────────────────────────────────────────────────
  let _ = Js.Array.push(
    "┌──────────────────────────────────────────────────────────────────────────────┐",
    lines,
  )
  let _ = Js.Array.push(
    "│  📍 LOCATION ANALYSIS                                                        │",
    lines,
  )
  let _ = Js.Array.push(
    "└──────────────────────────────────────────────────────────────────────────────┘",
    lines,
  )
  let _ = Js.Array.push("", lines)

  if Array.length(gpsPoints) == 0 {
    let _ = Js.Array.push("  ⚠️  No GPS data found in any uploaded images.", lines)
    let _ = Js.Array.push(
      "      Images may have been taken with location services disabled,",
      lines,
    )
    let _ = Js.Array.push("      or GPS metadata was stripped during processing.", lines)
    let _ = Js.Array.push("", lines)
  } else {
    let locationAnalysis = ExifParser.calculateAverageLocation(gpsPoints, ~maxDistanceKm=0.5, ())

    let gpsCount = Belt.Int.toString(Array.length(gpsPoints))
    let totalCount = Belt.Int.toString(Array.length(sceneDataList))
    let _ = Js.Array.push(`  GPS Data Found: ${gpsCount} of ${totalCount} images`, lines)
    let _ = Js.Array.push("", lines)

    // Check for outliers
    let analysisObj = (Obj.magic(locationAnalysis): {..})
    let outliers = switch Nullable.toOption(analysisObj["outliers"]) {
    | Some(o) => Obj.magic(o)
    | None => []
    }

    if Array.length(outliers) > 0 {
      let _ = Js.Array.push(
        "  ⚠️  OUTLIERS DETECTED (excluded from average calculation):",
        lines,
      )
      Belt.Array.forEach(outliers, outlier => {
        let o = (Obj.magic(outlier): {..})
        let index: int = o["index"]
        let distance: float = o["distance"]
        let filename = Belt.Array.get(gpsFilenames, index)->Belt.Option.getWithDefault("Unknown")
        let distanceM = Belt.Int.toString(Float.toInt(distance *. 1000.0))
        let _ = Js.Array.push(`      • ${filename} - ${distanceM}m from cluster center`, lines)
      })
      let _ = Js.Array.push("", lines)
    }

    // Centroid
    switch Nullable.toOption(analysisObj["centroid"]) {
    | Some(c) => {
        let centroid = (Obj.magic(c): {..})
        let lat: float = centroid["lat"]
        let lon: float = centroid["lon"]

        let _ = Js.Array.push(`  📍 Estimated Property Location:`, lines)
        let _ = Js.Array.push(`     Latitude:  ${Float.toFixed(lat, ~digits=6)}`, lines)
        let _ = Js.Array.push(`     Longitude: ${Float.toFixed(lon, ~digits=6)}`, lines)
        let _ = Js.Array.push(
          `     Google Maps: https://maps.google.com/?q=${Float.toString(lat)},${Float.toString(
              lon,
            )}`,
          lines,
        )
        let _ = Js.Array.push("", lines)

        // Reverse geocode
        let _ = Js.Array.push("  🔍 Address Lookup:", lines)
        let address = await ExifParser.reverseGeocode(lat, lon)

        if String.startsWith(address, "[") {
          let _ = Js.Array.push(`     ${address}`, lines)
          let _ = Js.Array.push(
            "     (This does not affect your virtual tour - geocoding is informational only)",
            lines,
          )
        } else {
          let _ = Js.Array.push(`     ${address}`, lines)
          resolvedAddress := Some(address)
        }
        let _ = Js.Array.push("", lines)
      }
    | None => ()
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // SECTION 2: CAMERA/DEVICE GROUPING
  // ─────────────────────────────────────────────────────────────────
  let _ = Js.Array.push(
    "┌──────────────────────────────────────────────────────────────────────────────┐",
    lines,
  )
  let _ = Js.Array.push(
    "│  📷 CAMERA & DEVICE ANALYSIS                                                 │",
    lines,
  )
  let _ = Js.Array.push(
    "└──────────────────────────────────────────────────────────────────────────────┘",
    lines,
  )
  let _ = Js.Array.push("", lines)

  // Group by camera signature
  let groups = Dict.make()
  Belt.Array.forEach(exifResults, r => {
    let sig = ExifParser.getCameraSignature(r.exif)
    switch Dict.get(groups, sig) {
    | Some(group) => {
        let g = (Obj.magic(group): {..})
        let files: array<string> = g["files"]
        let _ = Js.Array.push(r.filename, files)
      }
    | None => {
        let group = {
          "exif": r.exif,
          "files": [r.filename],
        }
        Dict.set(groups, sig, group)
      }
    }
  })

  Belt.Array.forEach(Dict.toArray(groups), ((signature, data)) => {
    let d = (Obj.magic(data): {..})
    let files: array<string> = d["files"]
    let exif = (Obj.magic(d["exif"]): {..})

    let dashCount = max_int(0, 60 - String.length(signature))
    let dashes = String.repeat("─", dashCount)
    let _ = Js.Array.push(`  ┌─ ${signature} ─${dashes}`, lines)
    let _ = Js.Array.push(`  │  Images: ${Belt.Int.toString(Array.length(files))}`, lines)

    switch Nullable.toOption(exif["focalLength"]) {
    | Some(fl) => {
        let focal: float = fl
        let _ = Js.Array.push(`  │  Focal Length: ${Float.toFixed(focal, ~digits=1)}mm`, lines)
      }
    | None => ()
    }

    switch Nullable.toOption(exif["aperture"]) {
    | Some(ap) => {
        let aperture: float = ap
        let _ = Js.Array.push(`  │  Aperture: f/${Float.toFixed(aperture, ~digits=1)}`, lines)
      }
    | None => ()
    }

    switch Nullable.toOption(exif["iso"]) {
    | Some(i) => {
        let iso: int = i
        let _ = Js.Array.push(`  │  ISO: ${Belt.Int.toString(iso)}`, lines)
      }
    | None => ()
    }

    switch Nullable.toOption(exif["dateTime"]) {
    | Some(dt) => {
        let _ = Js.Array.push(`  │  Capture Period: ${dt}`, lines)
      }
    | None => ()
    }

    let _ = Js.Array.push(`  │`, lines)
    let _ = Js.Array.push(`  │  Files:`, lines)
    Belt.Array.forEach(files, f => {
      let _ = Js.Array.push(`  │    • ${f}`, lines)
    })
    let _ = Js.Array.push(`  └${String.repeat("─", 76)}`, lines)
    let _ = Js.Array.push("", lines)
  })

  // ─────────────────────────────────────────────────────────────────
  // SECTION 3: DETAILED FILE LIST
  // ─────────────────────────────────────────────────────────────────
  let _ = Js.Array.push(
    "┌──────────────────────────────────────────────────────────────────────────────┐",
    lines,
  )
  let _ = Js.Array.push(
    "│  📋 INDIVIDUAL FILE METADATA                                                 │",
    lines,
  )
  let _ = Js.Array.push(
    "└──────────────────────────────────────────────────────────────────────────────┘",
    lines,
  )
  let _ = Js.Array.push("", lines)

  Belt.Array.forEach(exifResults, r => {
    let exifObj = (Obj.magic(r.exif): {..})
    let qualityObj = (Obj.magic(r.quality): {..})

    let hasGPS = switch Nullable.toOption(exifObj["gps"]) {
    | Some(_) => "✓ GPS"
    | None => "✗ No GPS"
    }

    let hasCamera = {
      let make = switch Nullable.toOption(exifObj["make"]) {
      | Some(m) => m
      | None => ""
      }
      let model = switch Nullable.toOption(exifObj["model"]) {
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

    let qScore = switch Nullable.toOption(qualityObj["score"]) {
    | Some(s) => {
        let score: float = s
        `| Quality: ${Float.toFixed(score, ~digits=1)}/10`
      }
    | None => ""
    }

    let _ = Js.Array.push(`  ${r.filename}`, lines)
    let _ = Js.Array.push(`    └─ ${hasCamera} | ${hasGPS} ${qScore}`, lines)

    switch Nullable.toOption(qualityObj["analysis"]) {
    | Some(analysis) => {
        let _ = Js.Array.push(`       Note: ${analysis}`, lines)
      }
    | None => ()
    }
  })

  let _ = Js.Array.push("", lines)
  let _ = Js.Array.push(String.repeat("═", 80), lines)
  let _ = Js.Array.push("END OF REPORT", lines)
  let _ = Js.Array.push(String.repeat("═", 80), lines)

  // Generate suggested project name
  let suggestedName = generateProjectName(resolvedAddress.contents, captureDateTime.contents)

  Promise.resolve({
    report: Js.Array.joinWith("\n", lines),
    suggestedName,
  })
}

/**
 * Save the EXIF report to the logs folder (browser download)
 */
let downloadExifReport = (content: string): string => {
  let timestamp =
    Date.toISOString(Date.make())
    ->String.replaceRegExp(/[:.]/g, "-")
    ->String.slice(~start=0, ~end=19)

  let filename = `EXIF_METADATA_${timestamp}.txt`

  let blob = Blob.newBlob([content], {"type": "text/plain;charset=utf-8"})
  let url = URL.createObjectURL(blob)

  let a = Dom.createElement("a")
  let _ = (Obj.magic(a): {..})["href"] = url
  let _ = (Obj.magic(a): {..})["download"] = filename
  Dom.appendChild(Dom.documentBody, a)
  let _ = (Obj.magic(a): {..})["click"]()
  Dom.documentBody
  ->Obj.magic
  ->Dict.get("removeChild")
  ->Belt.Option.forEach(fn => {
    let _ = (Obj.magic(fn): Dom.element => unit)(a)
  })

  let _ = Window.setTimeout(() => URL.revokeObjectURL(url), 10000)

  filename
}
