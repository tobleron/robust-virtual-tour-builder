// @vitest-environment jsdom
import { beforeEach, describe, expect, test, vi } from 'vitest';

vi.mock('../../src/systems/Exporter.bs.js', () => ({
  exportTour: vi.fn().mockResolvedValue({ TAG: 0, _0: undefined }),
}));

vi.mock('../../src/systems/Teaser.bs.js', () => ({
  startHeadlessTeaserWithStyle: vi.fn().mockResolvedValue(undefined),
}));

vi.mock('../../src/systems/ExifReportGenerator.bs.js', () => ({
  generateExifReport: vi.fn().mockResolvedValue({ report: 'mock-report', suggestedProjectName: undefined }),
  downloadExifReport: vi.fn().mockResolvedValue(undefined),
}));

vi.mock('../../src/systems/ExifParserFacade.bs.js', () => ({
  extractExifFromFile: vi.fn().mockResolvedValue({ TAG: 0, _0: { make: 'TestCam' } }),
}));

import * as Exporter from '../../src/systems/Exporter.bs.js';
import * as Teaser from '../../src/systems/Teaser.bs.js';
import * as ExifReportGenerator from '../../src/systems/ExifReportGenerator.bs.js';
import * as ExifParserFacade from '../../src/systems/ExifParserFacade.bs.js';
import {
  downloadExifReportLazy,
  exportTourLazy,
  extractExifFromFileLazy,
  generateExifReportLazy,
  startTeaserLazy,
} from '../../src/systems/FeatureLoaders.js';

describe('FeatureLoaders', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  test('startTeaserLazy preserves style and pan-speed argument ordering', async () => {
    const getState = vi.fn();
    const dispatch = vi.fn();
    const signal = { aborted: false };
    const onCancel = vi.fn();

    await startTeaserLazy('webm', 'cinematic', 'fast', getState, dispatch, signal, onCancel);

    expect(Teaser.startHeadlessTeaserWithStyle).toHaveBeenCalledWith(
      'webm',
      'cinematic',
      'fast',
      getState,
      dispatch,
      signal,
      onCancel
    );
  });

  test('exportTourLazy forwards publish profiles and operation id unchanged', async () => {
    const scenes = [{ id: 'scene-1' }];
    const signal = { aborted: false };
    const onProgress = vi.fn();

    await exportTourLazy(
      scenes,
      'Tour Name',
      null,
      true,
      { version: 1 },
      signal,
      onProgress,
      'op-123',
      ['hd', '2k']
    );

    expect(Exporter.exportTour).toHaveBeenCalledWith(
      scenes,
      'Tour Name',
      null,
      true,
      { version: 1 },
      signal,
      onProgress,
      'op-123',
      ['hd', '2k']
    );
  });

  test('EXIF lazy helpers delegate to the expected modules', async () => {
    const fakeFile = { name: 'scene.webp' };

    await generateExifReportLazy([{ original: fakeFile, metadataJson: undefined, qualityJson: undefined }]);
    await downloadExifReportLazy('csv-content');
    await extractExifFromFileLazy(fakeFile);

    expect(ExifReportGenerator.generateExifReport).toHaveBeenCalledTimes(1);
    expect(ExifReportGenerator.downloadExifReport).toHaveBeenCalledWith('csv-content');
    expect(ExifParserFacade.extractExifFromFile).toHaveBeenCalledWith(fakeFile);
  });
});
