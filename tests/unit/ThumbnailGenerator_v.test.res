// @efficiency: infra-adapter
/* tests/unit/ThumbnailGenerator_v.test.res */
open Vitest
open ReBindings

// Mock Canvas and document
%%raw(`
  class MockCanvas {
    constructor() { this.width = 0; this.height = 0; }
    getContext() {
      return {
        drawImage: vi.fn(),
        getImageData: (x, y, w, h) => ({
          data: new Uint8ClampedArray(w * h * 4)
        }),
        createImageData: (w, h) => ({
          data: new Uint8ClampedArray(w * h * 4)
        }),
        putImageData: vi.fn(),
        imageSmoothingQuality: 'high'
      };
    }
    toBlob(cb, type, quality) {
      cb({ size: 1024, type: type });
    }
  }

  globalThis.document = {
    createElement: (tag) => {
      if (tag === 'canvas') return new MockCanvas();
      return {};
    }
  };
`)

describe("ThumbnailGenerator", () => {
  testAsync("generateRectilinearThumbnail creates a blob", async t => {
    let mockImg: Dom.element = %raw(`{
      width: 4096,
      height: 2048,
      naturalWidth: 4096,
      naturalHeight: 2048
    }`)

    let blob = await ThumbnailGenerator.generateRectilinearThumbnail(mockImg, 200, 100)

    t->expect(Blob.size(blob))->Expect.toBe(1024.0)
    t->expect(Blob.type_(blob))->Expect.toBe("image/webp")
  })
})
