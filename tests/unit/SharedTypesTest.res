open SharedTypes

let run = () => {
  Console.log("Running SharedTypes tests...")

  // Test 1: gPanoMetadata structure
  let mockPano: gPanoMetadata = {
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
  assert(mockPano.usePanoramaViewer == true)
  Console.log("✓ gPanoMetadata structure verified")

  // Test 2: JSON Parsing verification for MetadataResponse (checking @as mappings)
  let jsonStr = `{
    "exif": {
      "make": "Insta360",
      "model": "X3",
      "dateTime": "2026:01:14 12:00:00",
      "gps": {"lat": 25.1, "lon": 55.2},
      "width": 5760,
      "height": 2880,
      "focalLength": 1.5,
      "aperture": 2.0,
      "iso": 100
    },
    "quality": {
      "score": 9.5,
      "histogram": [1, 2, 3],
      "colorHist": {"r": [10], "g": [20], "b": [30]},
      "stats": {
        "avgLuminance": 128,
        "blackClipping": 0.0,
        "whiteClipping": 0.0,
        "sharpnessVariance": 1000
      },
      "isBlurry": false,
      "isSoft": false,
      "isSeverelyDark": false,
      "isSeverelyBright": false,
      "isDim": false,
      "hasBlackClipping": false,
      "hasWhiteClipping": false,
      "issues": 0,
      "warnings": 0,
      "analysis": "Excellent"
    },
    "isOptimized": true,
    "checksum": "abc_123",
    "suggestedName": "living_room"
  }`

  let parsed: metadataResponse = Obj.magic(JSON.parseOrThrow(jsonStr))
  
  assert(parsed.exif.make == Nullable.make("Insta360"))
  assert(parsed.exif.dateTime == Nullable.make("2026:01:14 12:00:00"))
  assert(parsed.quality.colorHist.r == [10])
  assert(parsed.quality.stats.avgLuminance == 128)
  assert(parsed.isOptimized == true)
  assert(parsed.suggestedName == Nullable.make("living_room"))
  
  Console.log("✓ metadataResponse JSON mapping verified (@as checks)")

  // Test 3: ValidationReport mapping
  let reportJson = `{
    "brokenLinksRemoved": 5,
    "orphanedScenes": ["scene1"],
    "unusedFiles": [],
    "warnings": ["warn"],
    "errors": []
  }`
  let report: validationReport = Obj.magic(JSON.parseOrThrow(reportJson))
  assert(report.brokenLinksRemoved == 5)
  assert(Array.length(report.orphanedScenes) == 1)
  
  Console.log("✓ validationReport JSON mapping verified")
}