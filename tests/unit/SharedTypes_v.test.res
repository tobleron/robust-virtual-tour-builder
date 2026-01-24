open Vitest
open SharedTypes

describe("SharedTypes", _ => {
  test("gPanoMetadata structure verified", t => {
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
    t->expect(mockPano.usePanoramaViewer)->Expect.toBe(true)
  })

  test("metadataResponse JSON mapping verified", t => {
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

    t->expect(parsed.exif.make->Nullable.toOption)->Expect.toBe(Some("Insta360"))
    t->expect(parsed.exif.dateTime->Nullable.toOption)->Expect.toBe(Some("2026:01:14 12:00:00"))
    t->expect(parsed.quality.colorHist.r)->Expect.toEqual([10])
    t->expect(parsed.quality.stats.avgLuminance)->Expect.toBe(128)
    t->expect(parsed.isOptimized)->Expect.toBe(true)
    t->expect(parsed.suggestedName->Nullable.toOption)->Expect.toBe(Some("living_room"))
  })

  test("validationReport JSON mapping verified", t => {
    let reportJson = `{
      "brokenLinksRemoved": 5,
      "orphanedScenes": ["scene1"],
      "unusedFiles": [],
      "warnings": ["warn"],
      "errors": []
    }`
    let report: validationReport = Obj.magic(JSON.parseOrThrow(reportJson))

    t->expect(report.brokenLinksRemoved)->Expect.toBe(5)
    t->expect(Belt.Array.length(report.orphanedScenes))->Expect.toBe(1)
  })
})
