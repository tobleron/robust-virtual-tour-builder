open Vitest
open ExifReportGeneratorLogicExtraction
open ExifReportGeneratorTypes
open SharedTypes

/* Mocks */
type mockFn
@send external mockResolvedValue: (mockFn, 'a) => unit = "mockResolvedValue"
@send external mockReturnValue: (mockFn, 'a) => unit = "mockReturnValue"

/* Mock ExifParser */
%%raw(`
  import { vi } from 'vitest';

  vi.mock('../../src/systems/ExifParser.bs.js', () => {
    return {
      extractExifTags: vi.fn(),
      // Mock other functions if imported by the module, though LogicExtraction mainly uses extractExifTags
    };
  });
`)

@module("../../src/systems/ExifParser.bs.js")
external mockExtractExifTags: mockFn = "extractExifTags"

external anyToJson: 'a => JSON.t = "%identity"

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

/* Helper to create mock sceneDataItem */
let createMockItem = (~name, ~metadata=?, ~quality=?, ~fileObj=?, ()) => {
  let file = switch fileObj {
  | Some(f) => f
  | None => {
      let _ = name
      %raw(`(function(name) {
        var b = new Blob([""], {type: "image/jpeg"});
        return new File([b], name, {type: "image/jpeg"});
      })(name)`)
    }
  }

  {
    original: file,
    metadataJson: metadata,
    qualityJson: quality,
  }
}

describe("ExifReportGeneratorLogicExtraction", () => {
  beforeEach(() => {
    %raw(`vi.clearAllMocks()`)
  })

  describe("extractAllExif", () => {
    testAsync(
      "handles empty list",
      async t => {
        let (results, gps, filenames, date) = await extractAllExif([])

        t->expect(Array.length(results))->Expect.toBe(0)
        t->expect(Array.length(gps))->Expect.toBe(0)
        t->expect(Array.length(filenames))->Expect.toBe(0)
        t->expect(date)->Expect.toBe(None)
      },
    )

    testAsync(
      "uses cached metadata when available and GPS is present",
      async t => {
        let meta = {
          "gps": {"lat": 10.0, "lon": 20.0},
          "date": "2023:01:01 12:00:00",
          "cameraModel": "TestMake",
          "lensModel": "TestModel",
          "width": 1000,
          "height": 500,
          "focalLength": Nullable.null,
          "aperture": Nullable.null,
          "iso": Nullable.null,
        }
        let item = createMockItem(~name="test1.jpg", ~metadata=anyToJson(meta), ())

        let (results, gps, _filenames, date) = await extractAllExif([item])

        t->expect(Array.length(results))->Expect.toBe(1)
        t->expect(Array.length(gps))->Expect.toBe(1)
        let p = gps->Belt.Array.get(0)->Belt.Option.getExn
        t->expect(p.lat)->Expect.toBe(10.0)
        t->expect(p.lon)->Expect.toBe(20.0)
        t->expect(date)->Expect.toBe(Some("2023:01:01 12:00:00"))

        // Should NOT call local extraction
        let _ = %raw(`expect(mockExtractExifTags).not.toHaveBeenCalled()`)
      },
    )

    testAsync(
      "falls back to local extraction when metadata has no GPS",
      async t => {
        let meta = {
          "gps": Nullable.null, // No GPS in cached metadata
          "date": "2023:01:01 12:00:00",
          "width": 1000,
          "height": 500,
          "cameraModel": Nullable.null,
          "lensModel": Nullable.null,
          "focalLength": Nullable.null,
          "aperture": Nullable.null,
          "iso": Nullable.null,
        }
        let item = createMockItem(~name="test2.jpg", ~metadata=anyToJson(meta), ())

        // Mock local extraction success with GPS
        let localExif: exifMetadata = {
          ...defaultExif,
          gps: Nullable.make({lat: 30.0, lon: 40.0}),
          dateTime: Nullable.make("2023:02:02 12:00:00"),
        }
        let localPano = defaultPanorama

        mockExtractExifTags->mockResolvedValue(Ok((localExif, localPano)))

        let (results, gps, _, _) = await extractAllExif([item])

        t->expect(Array.length(results))->Expect.toBe(1)
        t->expect(Array.length(gps))->Expect.toBe(1)
        let p = gps->Belt.Array.get(0)->Belt.Option.getExn
        t->expect(p.lat)->Expect.toBe(30.0)

        // Should HAVE called local extraction
        let _ = %raw(`expect(mockExtractExifTags).toHaveBeenCalledTimes(1)`)
      },
    )

    testAsync(
      "performs local extraction when no metadata provided",
      async t => {
        let item = createMockItem(~name="test3.jpg", ())

        let localExif: exifMetadata = {
          ...defaultExif,
          make: Nullable.make("LocalMake"),
        }
        mockExtractExifTags->mockResolvedValue(Ok((localExif, defaultPanorama)))

        let (results, _, _, _) = await extractAllExif([item])

        t->expect(Array.length(results))->Expect.toBe(1)
        let r = results->Belt.Array.get(0)->Belt.Option.getExn
        t->expect(r.exifData.make->Nullable.toOption)->Expect.toBe(Some("LocalMake"))
      },
    )

    testAsync(
      "handles local extraction failure gracefully",
      async t => {
        let item = createMockItem(~name="test4.jpg", ())

        mockExtractExifTags->mockResolvedValue(Error("Corrupt file"))

        let (results, gps, _, _) = await extractAllExif([item])

        t->expect(Array.length(results))->Expect.toBe(1)
        let r = results->Belt.Array.get(0)->Belt.Option.getExn
        t
        ->expect(r.qualityData.analysis->Nullable.toOption)
        ->Expect.toBe(Some("Local extraction failed: Corrupt file"))
        t->expect(Array.length(gps))->Expect.toBe(0)
      },
    )
  })
})
