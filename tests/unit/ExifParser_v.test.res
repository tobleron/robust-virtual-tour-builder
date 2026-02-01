// @efficiency: infra-adapter
open Vitest
open ExifParser
open SharedTypes
open Types

type mockFn
@send external mockResolvedValue: (mockFn, 'a) => unit = "mockResolvedValue"
@send external mockRejectedValue: (mockFn, 'e) => unit = "mockRejectedValue"
@module("exifreader") external mockLoad: mockFn = "load"

let makeError: string => 'e = %raw(`function(msg) { return new Error(msg); }`)

/* Mocks */

/* Mock ExifReader */
%%raw(`
  import { vi } from 'vitest';

  vi.mock('exifreader', () => {
    return {
      load: vi.fn()
    };
  });
`)

/* Mock Logger to prevent console noise and verify calls */
%%raw(`
  vi.mock('../../src/utils/Logger.bs.js', () => {
    return {
      info: vi.fn(),
      warn: vi.fn(),
      error: vi.fn(),
      getErrorDetails: (exn) => {
        // console.log("Mock Logger received exn:", exn)
        let inner = exn && exn._1 ? exn._1 : exn;
        let msg = inner && inner.message ? inner.message : "Mock Error";
        return [msg, ""];
      },
      castToJson: (obj) => obj
    };
  });
`)

/* Mock BackendApi */
%%raw(`
  vi.mock('../../src/api/BackendApi.bs.js', () => {
    return {
      handleResponse: (res) => Promise.resolve(globalThis.Result.Ok(res)),
      reverseGeocode: vi.fn()
    };
  });
`)

/* Mock Fetch */
%%raw(`
  global.fetch = vi.fn();
  global.FormData = class FormData {
    constructor() { this.data = {}; }
    append(key, value) { this.data[key] = value; }
  };
`)

describe("ExifParser", () => {
  let _mockFetch: mockFn = %raw(`global.fetch`)

  beforeEach(() => {
    %raw(`vi.clearAllMocks()`)
  })

  describe("getCameraSignature", () => {
    test(
      "returns formatted string with valid data",
      t => {
        let mockExif: SharedTypes.exifMetadata = {
          make: Nullable.make("Insta360"),
          model: Nullable.make("X3"),
          dateTime: Nullable.null,
          gps: Nullable.null,
          width: 5760,
          height: 2880,
          focalLength: Nullable.null,
          aperture: Nullable.null,
          iso: Nullable.null,
        }

        let signature = getCameraSignature(mockExif)
        t->expect(signature)->Expect.toBe("Insta360 X3 @ 5760x2880")
      },
    )

    test(
      "handles missing data gracefully",
      t => {
        let mockExif: SharedTypes.exifMetadata = {
          make: Nullable.null,
          model: Nullable.null,
          dateTime: Nullable.null,
          gps: Nullable.null,
          width: 0,
          height: 0,
          focalLength: Nullable.null,
          aperture: Nullable.null,
          iso: Nullable.null,
        }

        let signature = getCameraSignature(mockExif)
        t->expect(signature)->Expect.toBe("Unknown Unknown @ 0x0")
      },
    )
  })

  describe("extractExifTags", () => {
    // Helper to create mock tags
    let createMockTags = dict => {
      let tags = Dict.make()
      let entries = Dict.toArray(dict)
      entries->Belt.Array.forEach(
        ((k, v)) => {
          tags->Dict.set(k, {ExifReader.description: v})
        },
      )
      tags
    }

    testAsync(
      "extracts basic metadata correctly",
      async t => {
        let _tags = createMockTags(
          Dict.fromArray([
            ("Make", "Canon"),
            ("Model", "EOS R5"),
            ("DateTime", "2023:01:01 12:00:00"),
            ("ImageWidth", "8192"),
            ("ImageHeight", "5464"),
            ("ProjectionType", "equirectangular"),
            ("UsePanoramaViewer", "True"),
          ]),
        )

        mockLoad->mockResolvedValue(_tags)

        // Mock a file object (blob)
        let blob = %raw(`new Blob([""], {type: "image/jpeg"})`)
        let file = Blob(blob)

        let result = await extractExifTags(file)

        switch result {
        | Ok((exif, pano)) => {
            t->expect(Nullable.toOption(exif.make))->Expect.toBe(Some("Canon"))
            t->expect(Nullable.toOption(exif.model))->Expect.toBe(Some("EOS R5"))
            t->expect(exif.width)->Expect.toBe(8192)
            t->expect(pano.usePanoramaViewer)->Expect.toBe(true)
            t->expect(pano.projectionType)->Expect.toBe("equirectangular")
          }
        | Error(msg) => t->expect(msg)->Expect.toBe("Should not error")
        }
      },
    )

    testAsync(
      "parses robust float and int values",
      async t => {
        let _tags = createMockTags(
          Dict.fromArray([
            ("PoseHeadingDegrees", "180.5"),
            ("CroppedAreaImageWidthPixels", "4000"),
            ("FullPanoWidthPixels", "8000"),
          ]),
        )
        mockLoad->mockResolvedValue(_tags)
        let blob = %raw(`new Blob([""], {type: "image/jpeg"})`)
        let file = Blob(blob)

        let result = await extractExifTags(file)

        switch result {
        | Ok((_, pano)) => {
            t->expect(pano.poseHeadingDegrees)->Expect.toBe(180.5)
            t->expect(pano.croppedAreaImageWidthPixels)->Expect.toBe(4000)
            t->expect(pano.fullPanoWidthPixels)->Expect.toBe(8000)
          }
        | Error(_) => t->expect(true)->Expect.toBe(false)
        }
      },
    )

    testAsync(
      "parses GPS coordinates successfully",
      async t => {
        let _tags = createMockTags(
          Dict.fromArray([
            ("GPSLatitude", "34.05"),
            ("GPSLatitudeRef", "N"),
            ("GPSLongitude", "118.25"),
            ("GPSLongitudeRef", "W"),
          ]),
        )
        mockLoad->mockResolvedValue(_tags)
        let blob = %raw(`new Blob([""], {type: "image/jpeg"})`)
        let file = Blob(blob)

        let result = await extractExifTags(file)

        switch result {
        | Ok((exif, _)) => {
            let gps = Nullable.toOption(exif.gps)
            t->expect(Belt.Option.isSome(gps))->Expect.toBe(true)
            let coords = Belt.Option.getExn(gps)
            t->expect(coords.lat)->Expect.toBe(34.05)
            // Longitude should be negative because of Ref="W"
            t->expect(coords.lon)->Expect.toBe(-118.25)
          }
        | Error(_) => t->expect(true)->Expect.toBe(false)
        }
      },
    )

    testAsync(
      "handles DMS GPS format",
      async t => {
        let _tags = createMockTags(
          Dict.fromArray([
            ("GPSLatitude", "34 deg 30' 0.0\""),
            ("GPSLatitudeRef", "N"),
            ("GPSLongitude", "118 deg 15' 0.0\""),
            ("GPSLongitudeRef", "W"),
          ]),
        )
        mockLoad->mockResolvedValue(_tags)
        let blob = %raw(`new Blob([""], {type: "image/jpeg"})`)
        let file = Blob(blob)

        let result = await extractExifTags(file)

        switch result {
        | Ok((exif, _)) => {
            let gps = Nullable.toOption(exif.gps)
            let coords = Belt.Option.getExn(gps)
            // 34 + 30/60 = 34.5
            t->expect(coords.lat)->Expect.toBe(34.5)
            // 118 + 15/60 = 118.25 -> -118.25 (West)
            t->expect(coords.lon)->Expect.toBe(-118.25)
          }
        | Error(_) => t->expect(true)->Expect.toBe(false)
        }
      },
    )

    testAsync(
      "gracefully handles missing GPS",
      async t => {
        let _tags = createMockTags(Dict.fromArray([("Make", "Test")]))
        mockLoad->mockResolvedValue(_tags)
        let blob = %raw(`new Blob([""], {type: "image/jpeg"})`)
        let file = Blob(blob)

        let result = await extractExifTags(file)

        switch result {
        | Ok((exif, _)) => t->expect(Nullable.toOption(exif.gps))->Expect.toBe(None)
        | Error(_) => t->expect(true)->Expect.toBe(false)
        }
      },
    )

    testAsync(
      "handles Url file type by fetching blob first",
      async t => {
        let _tags = createMockTags(Dict.fromArray([("Make", "WebImage")]))
        mockLoad->mockResolvedValue(_tags)

        // Mock fetch to return a blob
        _mockFetch->mockResolvedValue({
          "blob": () => Promise.resolve(%raw(`new Blob([""], {type: "image/jpeg"})`)),
        })

        let file = Url("https://example.com/image.jpg")
        let result = await extractExifTags(file)

        switch result {
        | Ok((exif, _)) => {
            t->expect(Nullable.toOption(exif.make))->Expect.toBe(Some("WebImage"))
            let _ = %raw(`expect(_mockFetch).toHaveBeenCalledWith("https://example.com/image.jpg")`)
          }
        | Error(_) => t->expect(true)->Expect.toBe(false)
        }
      },
    )

    testAsync(
      "returns error on ExifReader exception",
      async t => {
        mockLoad->mockRejectedValue(makeError("Corrupt file"))
        let blob = %raw(`new Blob([""], {type: "image/jpeg"})`)
        let file = Blob(blob)

        let result = await extractExifTags(file)

        switch result {
        | Ok(_) => t->expect(true)->Expect.toBe(false)
        | Error(_) => t->expect(true)->Expect.toBe(true)
        }
      },
    )
  })

  describe("analyzeImageQuality", () => {
    testAsync(
      "calls backend and handles success",
      async t => {
        let fileType = %raw(`new File([new Blob([""], {type: "image/jpeg"})], "test.jpg")`)

        let mockResponse = {
          "exif": {
            "make": "Canon",
            "model": "EOS R5",
            "date": "2023:01:01",
            "cameraModel": "Canon EOS R5",
            "lensModel": "RF 15-35mm",
            "width": 8192,
            "height": 5464,
            "focalLength": 15.0,
            "fNumber": 2.8,
            "iso": 100,
            // gps omitted (undefined) instead of null
          },
          "quality": {
            "score": 0.9,
            "histogram": [1, 2, 3],
            "colorHist": {"r": [], "g": [], "b": []},
            "stats": {
              "avgLuminance": 128,
              "blackClipping": 0.0,
              "whiteClipping": 0.0,
              "sharpnessVariance": 10,
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
            // analysis omitted
          },
          "isOptimized": false,
          "checksum": "abc12345",
        }

        _mockFetch->mockResolvedValue({
          "ok": true,
          "json": () => Promise.resolve(mockResponse),
        })

        let result = await analyzeImageQuality(fileType)

        switch result {
        | Ok(_quality) => t->expect(true)->Expect.toBe(true)
        | Error(msg) => {
            Console.log2("Analyze Failure:", msg)
            t->expect(msg)->Expect.toBe("Should be Ok")
          }
        }
      },
    )

    testAsync(
      "handles backend failure",
      async t => {
        let fileType = %raw(`new File([new Blob([""], {type: "image/jpeg"})], "test.jpg")`)

        _mockFetch->mockRejectedValue(makeError("Network Error"))

        let result = await analyzeImageQuality(fileType)

        switch result {
        | Error(msg) => t->expect(msg)->Expect.String.toContain("Network Error")
        | Ok(_) => t->expect(true)->Expect.toBe(false)
        }
      },
    )
  })

  describe("calculateAverageLocation", () => {
    test(
      "calculates average correctly",
      t => {
        let p1: GeoUtils.point = {lat: 10.0, lon: 10.0}
        let p2: GeoUtils.point = {lat: 20.0, lon: 20.0}

        let avg = switch calculateAverageLocation([p1, p2], ()) {
        | Some({centroid}) => centroid
        | None => {lat: 0.0, lon: 0.0} // shouldn't happen
        }

        // Simple midpoint for small distances on flat plane approximation (
        // GeoUtils might do spherical, but this is fine for test
        // Wait, GeoUtils IS a dependency. If it's pure ReScript/logic
        // , it runs.

        t->expect(avg.lat > 14.0 && avg.lat < 16.0)->Expect.toBe(true)
      },
    )
  })
})
