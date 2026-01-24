import { vi } from 'vitest';

vi.mock('../../src/utils/Resizer.bs.js', () => ({
  checkBackendHealth: () => Promise.resolve(true),
  getChecksum: () => Promise.resolve('mock_id'),
  processAndAnalyzeImage: (f) => Promise.resolve({
    TAG: 'Ok',
    _0: {
      preview: f,
      tiny: [f],
      quality: { score: 9.0, stats: { avgLuminance: 128 }, isBlurry: false },
      metadata: { width: 100, height: 100 }
    }
  })
}));

vi.mock('../../src/api/BackendApi.bs.js', () => ({
  batchCalculateSimilarity: () => Promise.resolve({ TAG: 'Ok', _0: [] })
}));
