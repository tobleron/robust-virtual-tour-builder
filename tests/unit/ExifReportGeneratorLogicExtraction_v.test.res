open Vitest
open ExifReportGenerator.Extraction
open SharedTypes

/* Mocks */
type mockFn
@send external mockResolvedValue: (mockFn, 'a) => unit = "mockResolvedValue"
@send external mockReturnValue: (mockFn, 'a) => unit = "mockReturnValue"

/* Mock ExifParser */
%%raw(`
  import { vi } from 'vitest';

  vi.mock('../../src/systems/ExifParser.bs.js', () => {
    const extractExifTags = vi.fn();
    return {
      extractExifTags,
      extractExifTagsPreferred: extractExifTags,
      // Mock other functions if imported by the module, though LogicExtraction mainly uses extractExifTags
    };
  });
`)

@module("../../src/systems/ExifParser.bs.js")
external mockExtractExifTags: mockFn = "extractExifTags"

external anyToJson: 'a => JSON.t = "%identity"

/* Helper to remove undefined fields from object */
let sanitizeObject: 'a => 'a = %raw(`
  function(obj) {
    return JSON.parse(JSON.stringify(obj));
  }
`)

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
let createMockItem = (
  ~name,
  ~metadata=?,
  ~quality=?,
  ~fileObj=?,
  (),
): ExifReportGenerator.sceneDataItem => {
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
    let _ = %raw(`vi.clearAllMocks()`)
    // Ensure mock returns something safe by default to avoid crash if logic fallbacks
    mockExtractExifTags->mockResolvedValue(Error("Default Mock Error"))
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
      "uses cached metadata record when available",
      async t => {
        let meta: exifMetadata = {
          ...defaultExif,
          gps: Nullable.make({lat: 10.0, lon: 20.0}),
          dateTime: Nullable.make("2023:01:01 12:00:00"),
          width: 1000,
          height: 500,
        }
        let item = createMockItem(~name="test1.jpg", ~metadata=Obj.magic(meta), ())

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
