open Vitest

%%raw(`
  vi.mock('../../src/systems/Upload/UploadItemProcessor.bs.js', () => ({
    processItem: (i, item, _onStatus) => Promise.resolve({
      ...item,
      preview: Some(item.original),
      metadata: Some({}),
      quality: Some({ score: 0.9 })
    })
  }));

  vi.mock('../../src/systems/PanoramaClusterer.bs.js', () => ({
    clusterScenes: (items, _opts) => Promise.resolve(items)
  }));

  vi.mock('../../src/systems/Upload/UploadReporting.bs.js', () => ({
    handleExifReport: () => Promise.resolve({ success: [], skipped: [] }),
    createScenePayload: () => []
  }));

  vi.mock('../../src/api/BackendApi.bs.js', () => ({
    batchCalculateSimilarity: () => Promise.resolve({ TAG: 'Ok', _0: [] })
  }));

  vi.mock('../../src/systems/FeatureLoaders.bs.js', () => ({
    generateExifReportLazy: () => Promise.resolve({ report: "mock report", suggestedProjectName: None })
  }));

  vi.mock('../../src/utils/OperationJournal.bs.js', () => ({
    updateContext: () => Promise.resolve(),
    load: () => Promise.resolve([]),
    getInterrupted: () => []
  }));

  vi.mock('../../src/utils/PersistenceLayer.bs.js', () => ({
    performSave: () => Promise.resolve()
  }));

  vi.mock('../../src/systems/Upload/UploadFinalizer.bs.js', () => ({
    finalizeUploads: vi.fn(() => Promise.resolve({ qualityResults: [], duration: "0", report: { success: [], skipped: [] } })),
    executeProcessingChain: vi.fn(() => Promise.resolve({ qualityResults: [], duration: "0", report: { success: [], skipped: [] } }))
  }));

  vi.mock('../../src/systems/Upload/UploadReporting.bs.js', () => ({
    handleExifReport: vi.fn(() => Promise.resolve({ success: [], skipped: [] })),
    createScenePayload: vi.fn(() => [])
  }));

  vi.mock('../../src/systems/PanoramaClusterer.bs.js', () => ({
    clusterScenes: vi.fn((items, _opts) => Promise.resolve(items))
  }));

  vi.mock('../../src/api/BackendApi.bs.js', () => ({
    batchCalculateSimilarity: vi.fn(() => Promise.resolve({ TAG: 'Ok', _0: [] })),
    handleResponse: vi.fn((r) => Promise.resolve(r))
  }));
`)

describe("UploadProcessorLogic", () => {
  test("placeholder", t => {
    t->expect(true)->Expect.toBe(true)
  })
})
