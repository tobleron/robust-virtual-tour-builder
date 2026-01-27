/* src/systems/ExifReportGeneratorLogicLocation.res */

open ReBindings
open SharedTypes
open ExifReportGeneratorTypes

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
        "gpsPoints": gpsPoints->Belt.Array.map(p =>
          {
            "lat": p.lat,
            "lon": p.lon,
          }
        ),
      }),
      (),
    )

    let _ = Array.push(lines, `  GPS Data Found: ${gpsCount} of ${totalCountStr} images`)
    let _ = Array.push(lines, "")

    // Outliers
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

  resolvedAddress.contents
}
