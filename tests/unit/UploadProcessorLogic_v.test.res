open Vitest
open ReBindings
open UploadTypes

%%raw(`
  vi.mock('../../src/systems/Resizer.bs.js', () => ({
    processAndAnalyzeImage: (f) => Promise.resolve({
      TAG: 'Ok',
      _0: {
        preview: f,
        tiny: f,
        qualityData: { score: 0.9, stats: { avgLuminance: 128, sharpnessVariance: 10, blackClipping: 0, whiteClipping: 0 }, isBlurry: false, issues: 0, warnings: 0, analysis: null, histogram: [], colorHist: {r:[], g:[], b:[]}, isSoft: false, isSeverelyBright: false, isDim: false, isSeverelyDark: false, hasBlackClipping: false, hasWhiteClipping: false },
        metadata: { width: 100, height: 100 }
      }
    })
  }));

  vi.mock('../../src/utils/OperationJournal.bs.js', () => ({
    updateContext: () => Promise.resolve(),
    load: () => Promise.resolve([]),
    getInterrupted: () => []
  }));

  vi.mock('../../src/utils/PersistenceLayer.bs.js', () => ({
    performSave: () => Promise.resolve()
  }));

  vi.mock('../../src/systems/PanoramaClusterer.bs.js', () => ({
    clusterScenes: (items) => Promise.resolve(items)
  }));
`)

describe("UploadProcessorLogic", () => {
  beforeEach(() => {
    AppStateBridge.updateState(State.initialState)
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

    let startTime = Date.now()
    let results = await UploadProcessorLogic.executeProcessingChain(
      [item1, item2],
      2,
      startTime,
      onProgress,
      0, // skippedCount
      "test_journal_id",
      ~getState=AppStateBridge.getState,
      ~dispatch=AppStateBridge.dispatch,
    )

    t->expect(Array.length(results.report.success))->Expect.toBe(2)
    t->expect(Array.length(progressLog) > 0)->Expect.toBe(true)

    // Old assertions on array items access removed as executeProcessingChain returns summary result.
    // To test individual items we would need to inspect side effects or mock finalizeUploads.
    // For now we check success count which verifies flow.
  })

  testAsync(
    "finalizeUploads: dispatches SetPreloadingScene(0) if state was empty and new scenes added",
    async t => {
      let dispatchedActions = []

      // We need to override the dispatch in AppStateBridge
      AppStateBridge.registerDispatch(
        action => {
          let _ = Array.push(dispatchedActions, action)
        },
      )

      let f1 = mockFile("test.jpg")
      let scene: Types.scene = {
        id: "s1",
        name: "test.jpg",
        file: Types.File(f1),
        tinyFile: Some(Types.File(f1)),
        originalFile: Some(Types.File(f1)),
        hotspots: [],
        category: "0",
        floor: "1",
      label: "",
      quality: None,
      colorGroup: Some("0"),
      _metadataSource: "",
      categorySet: false,
      labelSet: false,
      isAutoForward: false,
      sequenceId: 0,
    }

      // Set state with activeIndex = -1 and one scene (simulating added scene)
      let stateWithScenes = TestUtils.createMockState(~scenes=[scene], ~activeIndex=-1, ())
      AppStateBridge.updateState(stateWithScenes)

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

      let _ = await UploadProcessorLogic.finalizeUploads(
        [item1],
        Date.now(),
        (_, _, _, _) => (),
        0,
        ~getState=AppStateBridge.getState,
        ~dispatch=AppStateBridge.dispatch,
      )

      let found = Belt.Array.getBy(
        dispatchedActions,
        a =>
          switch a {
          | Actions.SetPreloadingScene(idx) if idx == 0 => true
          | _ => false
          },
      )

      t->expect(found->Option.isSome)->Expect.toBe(true)
    },
  )
})
