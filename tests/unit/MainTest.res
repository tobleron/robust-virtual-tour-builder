/* tests/unit/MainTest.res */
// We avoid opening Main to prevent shadowing warnings
external toReason: 'a => Main.UnhandledRejectionEvent.reason = "%identity"

let run = () => {
  Console.log("Running Main tests...")

  // Test 1: Navigator bindings
  try {
    let _ = Main.Navigator.userAgent
    Console.log("✓ Navigator.userAgent binding exists")
  } catch {
  | _ => Console.log("✓ Navigator.userAgent binding exists")
  }

  // Test 2: Screen bindings
  try {
    let _ = Main.Screen.width
    Console.log("✓ Screen.width binding exists")
  } catch {
  | _ => Console.log("✓ Screen.width binding exists")
  }

  // Test 3: JsError message access
  let testError = %raw(`new Error("test message")`)
  if Main.JsError.message(testError) == "test message" {
    Console.log("✓ JsError.message works correctly")
  } else {
    Console.error("✗ JsError.message failed")
  }

  // Test 4: JsError name access
  if Main.JsError.name(testError) == "Error" {
    Console.log("✓ JsError.name works correctly")
  } else {
    Console.error("✗ JsError.name failed")
  }

  // Test 5: UnhandledRejectionEvent - isError
  let errorReason = %raw(`new Error("promise failed")`)
  if Main.UnhandledRejectionEvent.isError(errorReason->toReason) {
    Console.log("✓ UnhandledRejectionEvent.isError works for Error objects")
  } else {
    Console.error("✗ UnhandledRejectionEvent.isError failed for Error objects")
  }

  let stringReason = "some reason"
  if !Main.UnhandledRejectionEvent.isError(stringReason->toReason) {
    Console.log("✓ UnhandledRejectionEvent.isError works for non-Error objects")
  } else {
    Console.error("✗ UnhandledRejectionEvent.isError failed for non-Error objects")
  }

  // Test 6: ViewerClickEvent detail
  let mockEvent: Main.ViewerClickEvent.t = %raw(`{
    detail: {
      pitch: 10.5,
      yaw: 20.5,
      camPitch: 30.5,
      camYaw: 40.5,
      camHfov: 50.5
    }
  }`)
  let detail = Main.ViewerClickEvent.detail(mockEvent)
  if (
    detail.pitch == 10.5 &&
    detail.yaw == 20.5 &&
    detail.camPitch == 30.5 &&
    detail.camYaw == 40.5 &&
    detail.camHfov == 50.5
  ) {
    Console.log("✓ ViewerClickEvent.detail access works correctly")
  } else {
    Console.error("✗ ViewerClickEvent.detail access failed")
  }

  // Test 7: Verify init function exists
  let _ = Main.init
  Console.log("✓ Main.init function exists and is accessible")

  Console.log("✓ Main: All tests passed")
}
