open Vitest
open ExifReportGeneratorLogicGroups
open ExifReportGeneratorTypes
open SharedTypes

/* Mocks */
type mockFn
@send external mockReturnValue: (mockFn, 'a) => unit = "mockReturnValue"
@send external mockImplementation: (mockFn, 'a) => unit = "mockImplementation"

/* Mock ExifParser */
%%raw(`
  import { vi } from 'vitest';

  vi.mock('../../src/systems/ExifParser.bs.js', () => {
    return {
      getCameraSignature: vi.fn(exif => "MockSignature")
    };
  });
`)

@module("../../src/systems/ExifParser.bs.js")
external mockGetCameraSignature: mockFn = "getCameraSignature"

/* Helper to create mock result */
let createMockResult = (~name, ~make=?, ~model=?, ~gps=?, ~score=10.0, ()) => {
  let exif: exifMetadata = {
    ...SharedTypes.defaultExif,
    make: Nullable.fromOption(make),
    model: Nullable.fromOption(model),
    gps: Nullable.fromOption(gps),
  }

  let quality: qualityAnalysis = {
    ...SharedTypes.defaultQuality(""),
    score: score
  }

  {
    filename: name,
    exifData: exif,
    qualityData: quality
  }
}

describe("ExifReportGeneratorLogicGroups", () => {
  beforeEach(() => {
    %raw(`vi.clearAllMocks()`)
  })

  describe("analyzeGroups", () => {
    test("groups files by signature", t => {
      mockGetCameraSignature->mockReturnValue("Cam A")

      let r1 = createMockResult(~name="1.jpg", ())
      let r2 = createMockResult(~name="2.jpg", ())

      let lines = []
      analyzeGroups([r1, r2], lines)

      let content = Js.Array.joinWith("\n", lines)
      t->expect(content)->Expect.String.toContain("Cam A")
      t->expect(content)->Expect.String.toContain("Images: 2")
      t->expect(content)->Expect.String.toContain("1.jpg")
      t->expect(content)->Expect.String.toContain("2.jpg")
    })

    test("handles multiple groups", t => {
      let _ = %raw(`
        mockGetCameraSignature.mockImplementation((exif) => {
          if (exif.make === "Cam1") return "Signature1";
          return "Signature2";
        })
      `)

      let r1 = createMockResult(~name="1.jpg", ~make="Cam1", ())
      let r2 = createMockResult(~name="2.jpg", ~make="Cam2", ())

      let lines = []
      analyzeGroups([r1, r2], lines)

      let content = Js.Array.joinWith("\n", lines)
      t->expect(content)->Expect.String.toContain("Signature1")
      t->expect(content)->Expect.String.toContain("Signature2")
    })
  })

  describe("listIndividualFiles", () => {
    test("lists files with details", t => {
       let r = createMockResult(
         ~name="file.jpg",
         ~make="Sony",
         ~model="A7",
         ~gps={lat: 0.0, lon: 0.0},
         ()
       )

       let lines = []
       listIndividualFiles([r], lines)

       let content = Js.Array.joinWith("\n", lines)
       t->expect(content)->Expect.String.toContain("file.jpg")
       t->expect(content)->Expect.String.toContain("Sony A7")
       t->expect(content)->Expect.String.toContain("✓ GPS")
    })
  })
})
