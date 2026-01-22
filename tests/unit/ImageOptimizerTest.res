/* tests/unit/ImageOptimizerTest.res */
open ReBindings

let run = async () => {
  Console.log("Running ImageOptimizer tests...")

  // Mock a File object
  let mockFile = Obj.magic({
    "name": "test-pano.jpg",
    "size": 5000000,
    "type": "image/jpeg",
  })

  // Test 1: compressToWebP Successful Path
  let result1 = await ImageOptimizer.compressToWebP(mockFile, 0.92)
  switch result1 {
  | Ok(blob) => {
      let size = Blob.size(blob)
      if size != 1024.0 {
        JsError.throwWithMessage(
          "ImageOptimizerTest Failed: Expected mocked blob size 1024, got " ++ Float.toString(size),
        )
      }
      if Blob.type_(blob) != "image/webp" {
        JsError.throwWithMessage(
          "ImageOptimizerTest Failed: Expected type image/webp, got " ++ Blob.type_(blob),
        )
      }
      Console.log("✓ compressToWebP success path passed")
    }
  | Error(msg) =>
    JsError.throwWithMessage(
      "ImageOptimizerTest Failed: Compression should have succeeded but failed with: " ++ msg,
    )
  }

  // Test 2: safeCreateObjectURL failure path (internal to compressToWebP)
  // We can force this by mocking URL.createObjectURL to return ""
  ignore(
    %raw(`(function() {
    globalThis._savedCreateObjectURL = globalThis.URL.createObjectURL;
    globalThis.URL.createObjectURL = () => '';
  })()`),
  )

  let result2 = await ImageOptimizer.compressToWebP(mockFile, 0.92)

  // Restore original mock
  ignore(
    %raw(`(function() {
    globalThis.URL.createObjectURL = globalThis._savedCreateObjectURL;
    delete globalThis._savedCreateObjectURL;
  })()`),
  )

  switch result2 {
  | Ok(_) =>
    JsError.throwWithMessage("ImageOptimizerTest Failed: Should have failed on empty object URL")
  | Error(msg) => {
      if msg != "Failed to create object URL" {
        JsError.throwWithMessage("ImageOptimizerTest Failed: Unexpected error message: " ++ msg)
      }
      Console.log("✓ compressToWebP failure path (empty URL) passed")
    }
  }

  Console.log("ImageOptimizer tests completed.")
}
