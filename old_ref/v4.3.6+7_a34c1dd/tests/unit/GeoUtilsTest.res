/* tests/unit/GeoUtilsTest.res */
open GeoUtils

let run = () => {
  Console.log("Running GeoUtils tests...")

  // Test haversineDistance
  // Distance between London (51.5074, -0.1278) and Paris (48.8566, 2.3522) is ~344km
  let d1 = haversineDistance(51.5074, -0.1278, 48.8566, 2.3522)
  assert(d1 > 340.0 && d1 < 350.0)
  Console.log("✓ haversineDistance (London to Paris)")

  // Same point should be 0 distance
  let d2 = haversineDistance(51.5, -0.1, 51.5, -0.1)
  assert(d2 == 0.0)
  Console.log("✓ haversineDistance (Same point)")

  // Test calculateAverageLocation
  let points = [
    {lat: 51.5, lon: -0.1},
    {lat: 51.51, lon: -0.11},
    {lat: 51.49, lon: -0.09},
    {lat: 48.85, lon: 2.35}, // Outlier: Paris!
  ]

  let result = calculateAverageLocation(points, 200.0)
  switch result {
  | Some(res) => {
      assert(res.validCount == 3)
      assert(Array.length(res.outliers) == 1)
      let firstOutlier = Array.getUnsafe(res.outliers, 0)
      assert(firstOutlier.index == 3)
      Console.log("✓ calculateAverageLocation with outliers")
    }
  | None => assert(false)
  }

  // Test empty points
  let emptyResult = calculateAverageLocation([], 50.0)
  assert(emptyResult == None)
  Console.log("✓ calculateAverageLocation empty array")

  Console.log("GeoUtils tests passed!")
}
