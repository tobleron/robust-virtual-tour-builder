open ReBindings
open ExifParser

let run = () => {
  Console.log("Running ExifParser tests...")

  // Test 1: getCameraSignature returns formatted string
  try {
    let mockExif = Js.Json.parseExn(`{
      "make": "Insta360",
      "model": "X3",
      "width": 5760,
      "height": 2880
    }`)
    
    let sig_ = getCameraSignature(mockExif)
    assert(sig_ == "Insta360 X3 @ 5760x2880")
    Console.log("✓ getCameraSignature passed (formatted string)")
  } catch {
  | Js.Exn.Error(e) => Console.error("✗ getCameraSignature failed: " ++ Option.getOr(Js.Exn.message(e), "Unknown"))
  | _ => Console.error("✗ getCameraSignature failed with unknown error")
  }

  // Test 2: getCameraSignature handles missing data
  try {
    let mockExif = Js.Json.parseExn(`{}`)
    
    let sig_ = getCameraSignature(mockExif)
    assert(sig_ == "Unknown Unknown @ UnknownxUnknown")
    Console.log("✓ getCameraSignature passed (missing data)")
  } catch {
  | Js.Exn.Error(e) => Console.error("✗ getCameraSignature failed (missing data): " ++ Option.getOr(Js.Exn.message(e), "Unknown"))
  | _ => Console.error("✗ getCameraSignature failed (missing data) with unknown error")
  }

  Console.log("ExifParser tests completed.")
}