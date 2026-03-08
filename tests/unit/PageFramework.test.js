import { describe, expect, test } from 'vitest';

import {
  buildProjectAssetUrl,
  normalizeLogoForBuilder,
  normalizeProjectDataForBuilder,
} from '../../src/site/PageFramework.js';

describe('PageFramework builder restore normalization', () => {
  test('builds same-origin asset URLs for a project session', () => {
    expect(buildProjectAssetUrl('session 1', 'Brand Logo.png')).toBe(
      '/api/project/session%201/file/Brand%20Logo.png'
    );
  });

  test('normalizes logo sentinel and legacy backend logo URLs', () => {
    expect(normalizeLogoForBuilder('next-session', 'logo_upload')).toBe(
      '/api/project/next-session/file/logo_upload'
    );
    expect(
      normalizeLogoForBuilder(
        'next-session',
        '/api/project/old-session/file/logo_upload?cache=1#fragment'
      )
    ).toBe('/api/project/next-session/file/logo_upload');
  });

  test('normalizes relative logo filenames and preserves non-string values', () => {
    expect(normalizeLogoForBuilder('session-3', 'logos/company mark.svg')).toBe(
      '/api/project/session-3/file/company%20mark.svg'
    );
    expect(normalizeLogoForBuilder('session-3', null)).toBeNull();
    expect(normalizeLogoForBuilder('session-3', { url: 'logo_upload' })).toEqual({ url: 'logo_upload' });
  });

  test('normalizes builder project payloads without mutating unrelated fields', () => {
    const projectData = { tourName: 'Tour', logo: 'logo_upload', scenes: [{ id: 'scene-1' }] };
    const normalized = normalizeProjectDataForBuilder('session-4', projectData);

    expect(normalized).toEqual({
      tourName: 'Tour',
      logo: '/api/project/session-4/file/logo_upload',
      scenes: [{ id: 'scene-1' }],
    });
    expect(projectData.logo).toBe('logo_upload');
  });
});
