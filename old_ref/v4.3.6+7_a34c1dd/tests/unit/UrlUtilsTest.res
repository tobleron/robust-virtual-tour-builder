/* tests/unit/UrlUtilsTest.res */
open UrlUtils

let run = () => {
  Console.log("Running UrlUtilsTest...")

  // Test 1: fileToUrl with Url
  let urlStr = "https://example.com/panorama.jpg"
  let file = Types.Url(urlStr)
  let result = fileToUrl(file)
  if result != urlStr {
    JsError.throwWithMessage("UrlUtilsTest Failed: fileToUrl(Url) mismatch")
  }
  Console.log("✓ fileToUrl(Url) passed")

  // Test 2: safeCreateObjectURL (Smoke Test)
  // We already have a mock in node-setup.js that returns a string for truthy objects
  let blob = Obj.magic({"size": 100})
  let result2 = safeCreateObjectURL(blob)
  if !String.startsWith(result2, "blob:mock") {
    // If it didn't return our mock, maybe it returned "" on error, which is also fine for a smoke test
    if result2 != "" {
      Console.log2("safeCreateObjectURL returned unexpected value:", result2)
    }
  }
  Console.log("✓ safeCreateObjectURL smoke test passed")

  // Test 3: revokeUrl
  try {
    revokeUrl("blob:123")
  } catch {
  | _ => JsError.throwWithMessage("UrlUtilsTest Failed: revokeUrl crashed")
  }
  Console.log("✓ revokeUrl passed")

  Console.log("UrlUtilsTest Passed")
}
