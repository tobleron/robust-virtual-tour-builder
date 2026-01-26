open Vitest
open ReBindings
open UploadProcessorTypes

%%raw(`
  vi.mock('../../src/systems/Resizer.bs.js', () => ({
    processAndAnalyzeImage: (f) => Promise.resolve({
      TAG: 'Ok',
      _0: {
        preview: f,
        tiny: f,
        quality: { score: 0.9, stats: { avgLuminance: 128, sharpnessVariance: 10, blackClipping: 0, whiteClipping: 0 }, isBlurry: false, issues: 0, warnings: 0, analysis: null, histogram: [], colorHist: {r:[], g:[], b:[]}, isSoft: false, isSeverelyBright: false, isDim: false, isSeverelyDark: false, hasBlackClipping: false, hasWhiteClipping: false },
        metadata: { width: 100, height: 100 }
      }
    })
  }));
`)

describe("UploadProcessorLogic", () => {
  beforeEach(() => {
    GlobalStateBridge.setState(State.initialState)
  })

  let mockFile = (name): File.t => {
    Obj.magic({
      "name": name,
      "size": 1024.0,
      "type": "image/jpeg",
    })
  }

  testAsync("processWithQueue: should process multiple items concurrently", async t => {
    let f1 = mockFile("f1.jpg")
    let f2 = mockFile("f2.jpg")
    let item1 = {
      id: Nullable.null,
      original: f1,
      error: None,
      preview: None,
      tiny: None,
      quality: None,
      metadata: None,
      colorGroup: None,
    }
    let item2 = {
      id: Nullable.null,
      original: f2,
      error: None,
      preview: None,
      tiny: None,
      quality: None,
      metadata: None,
      colorGroup: None,
    }

    let progressLog = []
    let onProgress = (pct, msg, isProc, phase) => {
      let _ = Array.push(progressLog, (pct, msg, isProc, phase))
    }

    let results = await UploadProcessorLogic.processWithQueue([item1, item2], 2, onProgress)

    t->expect(Array.length(results))->Expect.toBe(2)
    t->expect(Array.length(progressLog) > 0)->Expect.toBe(true)

    let res1 = Belt.Array.getExn(results, 0)
    t->expect(res1.preview)->Expect.not->Expect.toEqual(None)
    t->expect(res1.quality)->Expect.not->Expect.toEqual(None)
  })
})
