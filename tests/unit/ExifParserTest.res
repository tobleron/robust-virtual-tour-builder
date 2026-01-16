open SharedTypes
open ExifParser

let run = () => {
  Console.log("Running ExifParser tests...")

  // Test 1: getCameraSignature returns formatted string
  try {
    let mockExif: SharedTypes.exifMetadata = {
      make: Nullable.make("Insta360"),
      model: Nullable.make("X3"),
      dateTime: Nullable.null,
      gps: Nullable.null,
      width: 5760,
      height: 2880,
      focalLength: Nullable.null,
      aperture: Nullable.null,
      iso: Nullable.null,
    }

    let sig_ = getCameraSignature(mockExif)
    assert(sig_ == "Insta360 X3 @ 5760x2880")
    Console.log("✓ getCameraSignature passed (formatted string)")
  } catch {
  | _ => Console.error("✖ getCameraSignature failed")
  }

  // Test 2: getCameraSignature handles missing data
  try {
    let mockExif: exifMetadata = {
      make: Nullable.null,
      model: Nullable.null,
      dateTime: Nullable.null,
      gps: Nullable.null,
      width: 0,
      height: 0,
      focalLength: Nullable.null,
      aperture: Nullable.null,
      iso: Nullable.null,
    }

    let sig_ = getCameraSignature(mockExif)
    assert(sig_ == "Unknown Unknown @ 0x0")
    Console.log("✓ getCameraSignature passed (missing data)")
  } catch {
  | JsExn(e) =>
    Console.error(
      "✗ getCameraSignature failed (missing data): " ++ Option.getOr(JsExn.message(e), "Unknown"),
    )
  | _ => Console.error("✗ getCameraSignature failed (missing data) with unknown error")
  }

  Console.log("ExifParser tests completed.")
}
