/* src/utils/GeoUtils.res */

/* Math bindings */
let pi = Math.Constants.pi
let atan2 = Math.atan2
let sqrt = Math.sqrt
let sin = Math.sin
let cos = Math.cos

type point = {
  lat: float,
  lon: float,
}

type outlier = {
  index: int,
  distance: float,
  point: point,
}

type scanResult = {
  centroid: point,
  outliers: array<outlier>,
  validCount: int,
}

let toRad = deg => deg *. pi /. 180.0

let haversineDistance = (lat1, lon1, lat2, lon2) => {
  let r = 6371.0 // Earth's radius in km
  let dLat = toRad(lat2 -. lat1)
  let dLon = toRad(lon2 -. lon1)

  let lat1Rad = toRad(lat1)
  let lat2Rad = toRad(lat2)

  let a = sin(dLat /. 2.0) ** 2.0 +. cos(lat1Rad) *. cos(lat2Rad) *. sin(dLon /. 2.0) ** 2.0

  let c = 2.0 *. atan2(~y=sqrt(a), ~x=sqrt(1.0 -. a))
  r *. c
}

let calculateAverageLocation = (gpsPoints: array<point>, maxDistanceKm: float) => {
  if Array.length(gpsPoints) == 0 {
    None
  } else {
    let len = Int.toFloat(Array.length(gpsPoints))

    // First pass: simple average
    let (sumLat, sumLon) = Array.reduce(gpsPoints, (0.0, 0.0), ((accLat, accLon), p) => {
      (accLat +. p.lat, accLon +. p.lon)
    })

    let roughCentroid = {
      lat: sumLat /. len,
      lon: sumLon /. len,
    }

    // Identify outliers
    let validPoints = []
    let outliers = []

    for i in 0 to Array.length(gpsPoints) - 1 {
      switch Belt.Array.get(gpsPoints, i) {
      | Some(p) =>
        let dist = haversineDistance(roughCentroid.lat, roughCentroid.lon, p.lat, p.lon)
        if dist > maxDistanceKm {
          let _ = Array.push(outliers, {index: i, distance: dist, point: p})
        } else {
          let _ = Array.push(validPoints, p)
        }
      | None => ()
      }
    }

    // Recalculate centroid without outliers
    if Array.length(validPoints) == 0 {
      Some({
        centroid: roughCentroid,
        outliers,
        validCount: 0,
      })
    } else {
      let validLen = Int.toFloat(Array.length(validPoints))
      let (finalSumLat, finalSumLon) = Array.reduce(validPoints, (0.0, 0.0), (
        (accLat, accLon),
        p,
      ) => {
        (accLat +. p.lat, accLon +. p.lon)
      })

      Some({
        centroid: {
          lat: finalSumLat /. validLen,
          lon: finalSumLon /. validLen,
        },
        outliers,
        validCount: Array.length(validPoints),
      })
    }
  }
}
