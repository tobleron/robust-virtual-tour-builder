/* tests/unit/GeoUtils_v.test.res */
open Vitest
open GeoUtils

describe("GeoUtils - Distance and Clustering Math", () => {
  test("haversineDistance calculates approximate distance between London and Paris", t => {
    // London: 51.5074, -0.1278
    // Paris: 48.8566, 2.3522
    // Expected: ~344km
    let d = haversineDistance(51.5074, -0.1278, 48.8566, 2.3522)
    t->expect(d)->Expect.Float.toBeGreaterThan(340.0)
    t->expect(d)->Expect.Float.toBeLessThan(350.0)
  })

  test("haversineDistance returns 0 for the same point", t => {
    let d = haversineDistance(51.5, -0.1, 51.5, -0.1)
    t->expect(d)->Expect.toEqual(0.0)
  })

  test("calculateAverageLocation identifies outliers and recalibrates centroid", t => {
    let points = [
      {lat: 51.5, lon: -0.1},
      {lat: 51.51, lon: -0.11},
      {lat: 51.49, lon: -0.09},
      {lat: 48.85, lon: 2.35}, // Outlier: Paris! (~344km away from London)
    ]

    // maxDistanceKm = 200.0
    let result = calculateAverageLocation(points, 200.0)

    switch result {
    | Some(res) => {
        t->expect(res.validCount)->Expect.toBe(3)
        t->expect(Belt.Array.length(res.outliers))->Expect.toBe(1)

        let firstOutlier = Belt.Array.getExn(res.outliers, 0)
        t->expect(firstOutlier.index)->Expect.toBe(3)
        t->expect(firstOutlier.point.lat)->Expect.toBe(48.85)

        // Centroid should be average of the 3 London points
        let expectedLat = (51.5 +. 51.51 +. 51.49) /. 3.0
        let expectedLon = (-0.1 +. -0.11 +. -0.09) /. 3.0

        t->expect(res.centroid.lat)->Expect.Float.toBeCloseTo(expectedLat, 5)
        t->expect(res.centroid.lon)->Expect.Float.toBeCloseTo(expectedLon, 5)
      }
    | None => t->expect(true)->Expect.toBe(false) // Should not happen
    }
  })

  test("calculateAverageLocation returns None for empty array", t => {
    let result = calculateAverageLocation([], 50.0)
    t->expect(result)->Expect.toBeNone
  })
})
