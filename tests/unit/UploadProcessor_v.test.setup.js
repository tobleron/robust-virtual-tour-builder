import { vi } from 'vitest';

// We removed the global mocks for Resizer and BackendApi because they 
// were breaking the unit tests for those specific modules.
// Tests that need these should mock them locally or use fetch mocking.

vi.mock('../../src/utils/VersionData.bs.js', () => ({
  version: '4.8.0',
  buildNumber: 147,
  buildInfo: 'Stable Release',
}));
