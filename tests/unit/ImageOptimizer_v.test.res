// @efficiency: infra-adapter
/* tests/unit/ImageOptimizer_v.test.res */
open Vitest
open ImageOptimizer
open ReBindings

// Global mocks for DOM and Canvas
%%raw(`
  globalThis.createImageBitmap = vi.fn().mockResolvedValue({
    width: 1000,
    height: 500,
    close: () => {}
  });

  vi.mock('../../src/utils/WorkerPool.bs.js', () => ({
    processFullWithWorker: vi.fn((blob, options) => {
      // Mocked virtual processing
      const width = options.width || 4096;
      const targetW = Math.min(width, 1000);
      const targetH = Math.min(width, 1000) / 2;
      return Promise.resolve({
        TAG: 'Ok',
        _0: [{ size: 1024, type: 'image/webp' }, targetW, targetH]
      });
    })
  }));
  globalThis.OffscreenCanvas = class {
    constructor(width, height) {
      this.width = width;
      this.height = height;
    }
    getContext() {
      return {
        drawImage: () => {},
        canvas: this
      };
    }
    convertToBlob() {
      return Promise.resolve(new Blob(['mock-webp'], { type: 'image/webp' }));
    }
  };
`)

describe("ImageOptimizer - Browser-side Compression", () => {
  beforeEach(() => {
    let _ = %raw(`vi.clearAllMocks()`)
  })

  testAsync("compressToWebP successfully resizes and compresses image", async t => {
    let mockFile: File.t = Obj.magic({"size": 5000, "name": "test.jpg"})
    let result = await compressToWebP(mockFile, 0.8)

    switch result {
    | Ok(blob) => {
        t->expect(Blob.size(blob))->Expect.toBe(1024.0)
        t->expect(Blob.type_(blob))->Expect.toBe("image/webp")
      }
    | Error(msg) => t->expect(msg)->Expect.toBe("Success")
    }
  })

  testAsync("compressToWebPConstrained respects custom bounds", async t => {
    let mockFile: File.t = Obj.magic({"size": 1000000})
    let result = await compressToWebPConstrained(
      mockFile,
      ~quality=0.8,
      ~maxWidth=500.0,
      ~maxHeight=250.0,
    )

    switch result {
    | Ok(blob) => t->expect(Blob.size(blob))->Expect.toBe(1024.0)
    | Error(msg) => t->expect(msg)->Expect.toBe("Success")
    }
  })
})
