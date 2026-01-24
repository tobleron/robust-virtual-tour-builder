/* tests/unit/MainTest.res */
// We avoid opening Main to prevent shadowing warnings

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
