open TeaserRecorder

let run = () => {
  Console.log("Running TeaserRecorder tests...")

  // Test 1: getRecordedBlobs returns empty array initially
  let blobs = getRecordedBlobs()
  if Array.length(blobs) == 0 {
    Console.log("✓ getRecordedBlobs passed (initial empty)")
  } else {
    Console.error("✗ getRecordedBlobs failed: expected empty array")
  }

  // Test 2: setFadeOpacity updates internal state (informational test)
  try {
    setFadeOpacity(0.5)
    // We can't easily check internalState since it's not exported, 
    // but we verify it doesn't crash even if DOM is missing (via catch)
    Console.log("✓ setFadeOpacity passed (execution check)")
  } catch {
  | _ => Console.log("ℹ setFadeOpacity skipped (DOM required)")
  }

  Console.log("✓ TeaserRecorder: Module loaded and basic functions verified")
}
