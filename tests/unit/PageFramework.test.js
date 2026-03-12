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
      sessionId: 'session-4',
      tourName: 'Tour',
      logo: '/api/project/session-4/file/logo_upload',
      scenes: [{ id: 'scene-1' }],
    });
    expect(projectData.sessionId).toBeUndefined();
    expect(projectData.logo).toBe('logo_upload');
  });

  test('normalizes scene and inventory file references to the current session asset URLs', () => {
    const projectData = {
      tourName: 'Tour',
      inventory: [
        {
          entry: {
            scene: {
              id: 'scene-a',
              file: 'assets/images/2k/001_Zoom_Out_View.webp',
              originalFile: '/api/project/old-session/file/001_Zoom_Out_View.jpg?cache=1',
              tinyFile: 'tiny/001_Zoom_Out_View.webp',
            },
          },
        },
      ],
      scenes: [
        {
          id: 'scene-a',
          file: 'images/001_Zoom_Out_View.webp',
          originalFile: 'https://cdn.example.com/001_Zoom_Out_View.jpg',
          tinyFile: 'tiny/001_Zoom_Out_View.webp',
        },
      ],
    };

    const normalized = normalizeProjectDataForBuilder('session-5', projectData);

    expect(normalized.inventory[0].entry.scene).toEqual({
      id: 'scene-a',
      file: '/api/project/session-5/file/001_Zoom_Out_View.webp',
      originalFile: '/api/project/session-5/file/001_Zoom_Out_View.jpg',
      tinyFile: '/api/project/session-5/file/001_Zoom_Out_View.webp',
    });
    expect(normalized.scenes[0]).toEqual({
      id: 'scene-a',
      file: '/api/project/session-5/file/001_Zoom_Out_View.webp',
      originalFile: 'https://cdn.example.com/001_Zoom_Out_View.jpg',
      tinyFile: '/api/project/session-5/file/001_Zoom_Out_View.webp',
    });

    expect(projectData.inventory[0].entry.scene.file).toBe('assets/images/2k/001_Zoom_Out_View.webp');
    expect(projectData.scenes[0].file).toBe('images/001_Zoom_Out_View.webp');
  });
});
