// @efficiency: infra-adapter
open Vitest
open Resizer
open ReBindings

describe("ResizerLogic", () => {
  beforeEach(() => {
    let _ = %raw(`(function(){
      globalThis.JSZip = {
        loadAsync: vi.fn(),
        file: vi.fn(),
        async: vi.fn()
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
})
