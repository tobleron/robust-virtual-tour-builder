open Vitest
open Api
open ReBindings

describe("MediaApi", () => {
  beforeEach(() => {
    let _ = %raw(`
      globalThis.fetch = (url, init) => {
        if (url.includes('/api/media/extract-metadata')) {
           return Promise.resolve({
             ok: true,
             status: 200,
             json: () => Promise.resolve({
               exif: {
                 width: 100, height: 100
                 // gps and other optional fields omitted
               },
               quality: {
                 score: 0.9, isBlurry: false, isDim: false, isSeverelyDark: false,
                 stats: { avgLuminance: 128, sharpnessVariance: 10, blackClipping: 0, whiteClipping: 0 },
                 // analysis omitted
                 histogram: [], colorHist: {r:[], g:[], b:[]},
                 isSoft: false, isSeverelyBright: false, hasBlackClipping: false, hasWhiteClipping: false,
                 issues: 0, warnings: 0
               },
               isOptimized: false,
               checksum: "abc"
               // suggestedName omitted
             })
           });
        }
        return Promise.resolve({ ok: false, status: 404 });
      }
    `)
  })

  testAsync("extractMetadata: should return metadata", async t => {
    let mockFile: File.t = Obj.magic({"name": "test.jpg"})
    let result = await MediaApi.extractMetadata(mockFile)

    switch result {
    | Ok(res) => t->expect(res.checksum)->Expect.toBe("abc")
    | Error(msg) => failwith(msg)
    }
  })
})
