// @efficiency: infra-adapter
import { vi } from 'vitest';

let currentMockViewer = null;
globalThis.setMockViewer = (v) => { currentMockViewer = v; };

vi.mock('../../src/core/ViewerState.bs.js', async (importOriginal) => {
  const actual = await importOriginal();
  return {
    ...actual,
    getActiveViewer: () => currentMockViewer || actual.getActiveViewer(),
    // Keep other helpers as they are unless explicitly mocked
    getInactiveViewer: actual.getInactiveViewer,
    getActiveContainerId: actual.getActiveContainerId,
    resetState: actual.resetState,
  };
});