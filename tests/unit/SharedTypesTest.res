open ReBindings
open SharedTypes

let run = () => {
  Console.log("Running SharedTypes tests...")

  // Smoke test for type stability
  let mock: gPanoMetadata = {
    usePanoramaViewer: true,
    projectionType: "equirectangular",
    poseHeadingDegrees: 0.0,
    posePitchDegrees: 0.0,
    poseRollDegrees: 0.0,
    croppedAreaImageWidthPixels: 1000,
    croppedAreaImageHeightPixels: 500,
    fullPanoWidthPixels: 1000,
    fullPanoHeightPixels: 500,
    croppedAreaLeftPixels: 0,
    croppedAreaTopPixels: 0,
    initialViewHeadingDegrees: 0,
  }
  
  assert(mock.usePanoramaViewer == true)
  Console.log("✓ SharedTypes: gPanoMetadata structure verified")
}
