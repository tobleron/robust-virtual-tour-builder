// @efficiency: infra-adapter
open Vitest
open Resizer
open ReBindings
open SharedTypes

/* Mocks */
%%raw(`
  vi.mock('../../src/utils/ThumbnailGenerator.bs.js', () => ({
    generateRectilinearThumbnail: vi.fn(() => Promise.resolve(new Blob(["mock-thumbnail"], {type: "image/webp"})))
  }));
`)

describe("ResizerLogic", () => {
  beforeEach(() => {
    let _ = %raw(`(function(){
      globalThis.JSZip = {
        loadAsync: vi.fn(),
        file: vi.fn(),
        async: vi.fn()
      };
      
      const originalCreateElement = document.createElement;
      document.createElement = function(tagName) {
        const el = originalCreateElement.call(document, tagName);
        if (tagName.toLowerCase() === 'img') {
          const originalSetAttribute = el.setAttribute;
          el.setAttribute = function(name, value) {
            originalSetAttribute.call(this, name, value);
            if (name === 'src') {
              setTimeout(() => {
                const event = new Event('load');
                this.dispatchEvent(event);
              }, 0);
            }
          };
        }
        return el;
      };
    })()`)
  })

  describe("createResultFiles: Renaming Logic", () => {
    let mockBlob = %raw(`new Blob(["content"], {type: "image/webp"})`)

    let makeMetadata = suggestedName => {
      let json = switch suggestedName {
      | Some(n) => `{"suggestedName": "${n}", "exif": {}, "quality": {}, "checksum": "123"}`
      | None => `{"suggestedName": null, "exif": {}, "quality": {}, "checksum": "123"}`
      }
      json
    }

    testAsync(
      "Uses suggested name if provided",
      async t => {
        let meta = makeMetadata(Some("MyPhoto"))
        let result = await ResizerLogic.createResultFiles(
          Ok((mockBlob, meta, None)),
          "Original.jpg",
        )

        switch result {
        | Ok(res) => t->expect(res.preview->File.name)->Expect.toBe("MyPhoto.webp")
        | Error(e) => t->expect(e)->Expect.toBe("Should satisfy")
        }
      },
    )

    testAsync(
      "Uses PureShot format if detected (IMG_YYYYMMDD_HHMMSS_XX_SSS)",
      async t => {
        let meta = makeMetadata(None)
        // IMG_20230101_123456_00_789.jpg -> IMG_3456_789
        // HHMMSS = 123456. slice(2,6) -> 3456. SSS = 789.
        let original = "IMG_20230101_123456_00_789.jpg"
        let result = await ResizerLogic.createResultFiles(Ok((mockBlob, meta, None)), original)

        switch result {
        | Ok(res) => t->expect(res.preview->File.name)->Expect.toBe("IMG_3456_789.webp")
        | Error(e) => t->expect(e)->Expect.toBe("Should satisfy")
        }
      },
    )

    testAsync(
      "Uses Legacy format if detected (_HHMMSS_XX_SSS)",
      async t => {
        let meta = makeMetadata(None)
        // Pano_123456_00_789.jpg -> 123456_789
        let original = "Pano_123456_00_789.jpg"
        let result = await ResizerLogic.createResultFiles(Ok((mockBlob, meta, None)), original)

        switch result {
        | Ok(res) => t->expect(res.preview->File.name)->Expect.toBe("123456_789.webp")
        | Error(e) => t->expect(e)->Expect.toBe("Should satisfy")
        }
      },
    )

    testAsync(
      "Falls back to original base name if no format matches",
      async t => {
        let meta = makeMetadata(None)
        let original = "My_Vacation_Photo.jpg"
        let result = await ResizerLogic.createResultFiles(Ok((mockBlob, meta, None)), original)

        switch result {
        | Ok(res) => t->expect(res.preview->File.name)->Expect.toBe("My_Vacation_Photo.webp")
        | Error(e) => t->expect(e)->Expect.toBe("Should satisfy")
        }
      },
    )

    testAsync(
      "Handles tiny file if present",
      async t => {
        let meta = makeMetadata(Some("Photo"))
        let tinyBlob = %raw(`new Blob(["tiny"], {type: "image/webp"})`)
        let result = await ResizerLogic.createResultFiles(
          Ok((mockBlob, meta, Some(tinyBlob))),
          "Original.jpg",
        )

        switch result {
        | Ok(res) => {
            t->expect(res.tiny->Belt.Option.isSome)->Expect.toBe(true)
            let tiny = res.tiny->Belt.Option.getExn
            t->expect(tiny->File.name)->Expect.toBe("Photo_tiny.webp")
          }
        | Error(e) => t->expect(e)->Expect.toBe("Should satisfy")
        }
      },
    )
  })

  describe("processZipResponse", () => {
    testAsync(
      "Extracts preview, metadata, and tiny from zip",
      async t => {
        // Mock JSZip behavior
        let _ = %raw(`(function(){
        globalThis.JSZip.file = vi.fn((zip, name) => {
          if (name === "preview.webp" || name === "metadata.json" || name === "tiny.webp") {
             // Return object with async method that delegates to globalThis.JSZip.async
             return { async: globalThis.JSZip.async };
          }
          return null;
        });
        globalThis.JSZip.async = vi.fn((type) => {
          if (type === "blob") return Promise.resolve(new Blob(["blob"], {type: "image/webp"}));
          if (type === "text") return Promise.resolve("{}");
          return Promise.resolve(null);
        });
      })()`)

        // Mock zip object with file method
        let mockZip = %raw(`{
         file: function(name) { return globalThis.JSZip.file(this, name) }
      }`)
        let result = await ResizerLogic.processZipResponse(Ok(mockZip))

        switch result {
        | Ok((_preview, meta, tinyOpt)) => {
            t->expect(meta)->Expect.toBe("{}")
            t->expect(tinyOpt->Belt.Option.isSome)->Expect.toBe(true)
          }
        | Error(e) => t->expect(e)->Expect.toBe("Should have succeeded")
        }
      },
    )

    testAsync(
      "Fails if essential files missing",
      async t => {
        // Mock JSZip behavior: missing metadata
        let _ = %raw(`(function(){
        globalThis.JSZip.file = vi.fn((zip, name) => {
          if (name === "preview.webp") return { async: globalThis.JSZip.async };
          return null;
        });
      })()`)

        let mockZip = %raw(`{
         file: function(name) { return globalThis.JSZip.file(this, name) }
      }`)
        let result = await ResizerLogic.processZipResponse(Ok(mockZip))

        switch result {
        | Error(e) => t->expect(e)->Expect.String.toContain("Missing preview.webp or metadata.json")
        | Ok(_) => t->expect(false)->Expect.toBe(true)
        }
      },
    )
  })

  describe("GPS metadata merge helpers", () => {
    let makeExif = (~gps: option<gpsData>=None, ~width: int=0, ~height: int=0, ()) => {
      make: Nullable.null,
      model: Nullable.null,
      dateTime: Nullable.null,
      gps: Nullable.fromOption(gps),
      width,
      height,
      focalLength: Nullable.null,
      aperture: Nullable.null,
      iso: Nullable.null,
    }

    test(
      "hasGps detects GPS presence",
      t => {
        let withGps = makeExif(~gps=Some({lat: 25.2, lon: 55.3}), ())
        let withoutGps = makeExif()

        t->expect(ResizerLogic.hasGps(withGps))->Expect.toBe(true)
        t->expect(ResizerLogic.hasGps(withoutGps))->Expect.toBe(false)
      },
    )

    test(
      "mergeExifPreferBase keeps base data and fills missing fields from fallback",
      t => {
        let base = makeExif(~width=4096, ())
        let fallback = makeExif(~gps=Some({lat: 1.1, lon: 2.2}), ~width=100, ~height=200, ())

        let merged = ResizerLogic.mergeExifPreferBase(~base, ~fallback)
        t->expect(merged.width)->Expect.toBe(4096)
        t->expect(merged.height)->Expect.toBe(200)
        t->expect(merged.gps->Nullable.toOption->Option.isSome)->Expect.toBe(true)
      },
    )
  })
})
