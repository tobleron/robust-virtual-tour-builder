// @efficiency: infra-adapter
open Vitest
open ExifReportGenerator
open SharedTypes

/* Mocks */
type mockFn
@send external mockReturnValue: (mockFn, 'a) => unit = "mockReturnValue"
@send external mockResolvedValue: (mockFn, 'a) => unit = "mockResolvedValue"

%%raw(`
  import { vi } from 'vitest';

  vi.mock('../../src/systems/ExifParser.bs.js', () => {
    return {
      extractExifTags: vi.fn(),
      calculateAverageLocation: vi.fn(),
      reverseGeocode: vi.fn(),
      getCameraSignature: vi.fn(exif => "MockSignature")
    };
  });

  vi.mock('../../src/utils/Logger.bs.js', () => {
    return {
      info: vi.fn(),
      warn: vi.fn(),
      initialized: vi.fn(),
      getErrorDetails: (exn) => ["Error", ""],
      castToJson: (obj) => obj
    };
  });
`)

@module("../../src/systems/ExifParser.bs.js")
external mockExtractExifTags: mockFn = "extractExifTags"
@module("../../src/systems/ExifParser.bs.js")
external mockCalculateAverageLocation: mockFn = "calculateAverageLocation"
@module("../../src/systems/ExifParser.bs.js")
external mockReverseGeocode: mockFn = "reverseGeocode"

external anyToJson: 'a => JSON.t = "%identity"

/* Helper to create mock sceneDataItem */
let createMockItem = (~name, ~metadata=?, ()) => {
  let _ = name
  {
    original: %raw(`new File([new Blob([""])], name)`),
    metadataJson: metadata,
    qualityJson: None,
  }
}

let defaultPanorama: gPanoMetadata = {
  usePanoramaViewer: false,
  projectionType: "equirectangular",
  poseHeadingDegrees: 0.0,
  posePitchDegrees: 0.0,
  poseRollDegrees: 0.0,
  croppedAreaImageWidthPixels: 0,
  croppedAreaImageHeightPixels: 0,
  fullPanoWidthPixels: 0,
  fullPanoHeightPixels: 0,
  croppedAreaLeftPixels: 0,
  croppedAreaTopPixels: 0,
  initialViewHeadingDegrees: 0,
}

describe("ExifReportGenerator", () => {
  beforeEach(() => {
    %raw(`vi.clearAllMocks()`)
  })

  testAsync("generateExifReport: handles empty file list", async t => {
    let result = await generateExifReport([])
    t->expect(String.includes(result.report, "Total Files Analyzed: 0"))->Expect.toBe(true)

    // Suggested name should be generated even with empty list using current timestamp and "Tour"
    switch result.suggestedProjectName {
    | Some(name) => t->expect(String.startsWith(name, "Tour_"))->Expect.toBe(true)
    | None => t->expect(true)->Expect.toBe(false)
    }
  })

  testAsync("generateExifReport: processes files and generates full report", async t => {
    // Setup mocks
    let meta = {
      "gps": {"lat": 10.0, "lon": 20.0},
      "dateTime": "2023:01:01 12:00:00",
      "make": "TestMake",
      "model": "TestModel",
      "width": 1000,
      "height": 500,
      "focalLength": Nullable.null,
      "aperture": Nullable.null,
      "iso": Nullable.null,
    }
    let item = createMockItem(~name="img1.jpg", ~metadata=anyToJson(meta), ())

    // Mock Location
    let analysis: GeoUtils.scanResult = {
      centroid: {lat: 10.0, lon: 20.0},
      outliers: [],
      validCount: 1,
    }
    mockCalculateAverageLocation->mockReturnValue(Some(analysis))
    let mockRes: Api.geocodeResponse = {address: "123 Test St"}
    mockReverseGeocode->mockResolvedValue(Ok(mockRes))

    // Mock Extraction (fallback not triggered if metadata present, but just in case)
    mockExtractExifTags->mockResolvedValue(Ok((SharedTypes.defaultExif, defaultPanorama)))

    let result = await generateExifReport([item])

    let r = result.report
    t->expect(String.includes(r, "Total Files Analyzed: 1"))->Expect.toBe(true)
    t->expect(String.includes(r, "LOCATION ANALYSIS"))->Expect.toBe(true)
    t->expect(String.includes(r, "123 Test St"))->Expect.toBe(true)
    t->expect(String.includes(r, "CAMERA & DEVICE ANALYSIS"))->Expect.toBe(true)
    t->expect(String.includes(r, "MockSignature"))->Expect.toBe(true)

    // Project Name
    switch result.suggestedProjectName {
    | Some(n) => t->expect(String.includes(n, "123_Test_St"))->Expect.toBe(true)
    | None => t->expect(true)->Expect.toBe(false)
    }
  })
})
