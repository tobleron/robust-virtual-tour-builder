open Vitest
open ExifReportGeneratorLogicLocation

/* Mocks */
type mockFn
@send external mockResolvedValue: (mockFn, 'a) => unit = "mockResolvedValue"
@send external mockReturnValue: (mockFn, 'a) => unit = "mockReturnValue"

/* Mock ExifParser */
%%raw(`
  import { vi } from 'vitest';

  vi.mock('../../src/systems/ExifParser.bs.js', () => {
    return {
      calculateAverageLocation: vi.fn(),
      reverseGeocode: vi.fn()
    };
  });

  vi.mock('../../src/utils/Logger.bs.js', () => {
    return {
      info: vi.fn(),
      warn: vi.fn(),
      error: vi.fn(),
      castToJson: (obj) => obj
    };
  });
`)

@module("../../src/systems/ExifParser.bs.js")
external mockCalculateAverageLocation: mockFn = "calculateAverageLocation"

@module("../../src/systems/ExifParser.bs.js")
external mockReverseGeocode: mockFn = "reverseGeocode"

@module("../../src/utils/Logger.bs.js")
external mockInfo: mockFn = "info"

@module("../../src/utils/Logger.bs.js")
external mockWarn: mockFn = "warn"

describe("ExifReportGeneratorLogicLocation", () => {
  beforeEach(() => {
    %raw(`vi.clearAllMocks()`)
  })

  describe("analyzeLocation", () => {
    testAsync(
      "warns when no GPS points found",
      async t => {
        let lines = []
        let result = await analyzeLocation([], [], 10, lines)

        t->expect(result)->Expect.toBe(None)
        let _ = %raw(`expect(mockWarn).toHaveBeenCalledWith("ExifReport", "NO_GPS_DATA_FOUND", expect.anything(), undefined)`)
        t->expect(Array.length(lines) > 0)->Expect.toBe(true)
        let line0 = lines->Belt.Array.get(0)->Belt.Option.getWithDefault("")
        t->expect(line0)->Expect.String.toContain("No GPS data found")
      },
    )

    testAsync(
      "analyzes location when GPS points exist",
      async t => {
        let lines = []
        let gpsPoints: array<GeoUtils.point> = [{lat: 10.0, lon: 20.0}]
        let gpsFilenames = ["test.jpg"]

        // Mock centroid analysis
        let analysis: GeoUtils.scanResult = {
          centroid: {lat: 10.0, lon: 20.0},
          outliers: [],
          validCount: 1,
        }
        mockCalculateAverageLocation->mockReturnValue(Some(analysis))

        // Mock geocoding
        let mockRes: Api.geocodeResponse = {address: "123 Test St"}
        mockReverseGeocode->mockResolvedValue(Ok(mockRes))

        let result = await analyzeLocation(gpsPoints, gpsFilenames, 1, lines)

        t->expect(result)->Expect.toBe(Some("123 Test St"))

        // Check lines
        let content = Js.Array.joinWith("\n", lines)
        t->expect(content)->Expect.String.toContain("GPS Data Found: 1")
        t->expect(content)->Expect.String.toContain("123 Test St")
      },
    )

    testAsync(
      "handles geocoding failure",
      async t => {
        let lines = []
        let gpsPoints: array<GeoUtils.point> = [{lat: 10.0, lon: 20.0}]
        let gpsFilenames = ["test.jpg"]

        let analysis: GeoUtils.scanResult = {
          centroid: {lat: 10.0, lon: 20.0},
          outliers: [],
          validCount: 1,
        }
        mockCalculateAverageLocation->mockReturnValue(Some(analysis))
        mockReverseGeocode->mockResolvedValue(Error("API Error"))

        let result = await analyzeLocation(gpsPoints, gpsFilenames, 1, lines)

        t->expect(result)->Expect.toBe(None)

        let content = Js.Array.joinWith("\n", lines)
        t->expect(content)->Expect.String.toContain("Geocoding failed: API Error")
      },
    )

    testAsync(
      "reports outliers",
      async t => {
        let lines = []
        let gpsPoints: array<GeoUtils.point> = [{lat: 10.0, lon: 20.0}, {lat: 90.0, lon: 90.0}]
        let gpsFilenames = ["valid.jpg", "outlier.jpg"]

        let analysis: GeoUtils.scanResult = {
          centroid: {lat: 10.0, lon: 20.0},
          outliers: [{index: 1, distance: 5000.0, point: {lat: 90.0, lon: 90.0}}],
          validCount: 1,
        }
        mockCalculateAverageLocation->mockReturnValue(Some(analysis))
        let mockRes: Api.geocodeResponse = {address: "Address"}
        mockReverseGeocode->mockResolvedValue(Ok(mockRes))

        let _ = await analyzeLocation(gpsPoints, gpsFilenames, 2, lines)

        let content = Js.Array.joinWith("\n", lines)
        t->expect(content)->Expect.String.toContain("OUTLIERS DETECTED")
        t->expect(content)->Expect.String.toContain("outlier.jpg")
      },
    )
  })
})
