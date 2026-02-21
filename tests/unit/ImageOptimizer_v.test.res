// @efficiency: infra-adapter
/* tests/unit/ImageOptimizer_v.test.res */
open Vitest
open ImageOptimizer
open ReBindings

// Global mocks for DOM and Canvas
%%raw(`
  class MockImage {
    constructor() {
      this.onload = null;
      this.onerror = null;
      this.src = "";
      this.naturalWidth = 1000;
      this.naturalHeight = 500;
      this.width = 1000;
      this.height = 500;
    }
    setAttribute(attr, val) {
      if (attr === 'src') {
        setTimeout(() => {
          if (val === 'error-url') this.onerror();
          else this.onload();
        }, 0);
      }
    }
    addEventListener(evt, cb) {
      if (evt === 'load') this.onload = cb;
      if (evt === 'error') this.onerror = cb;
    }
  }

  class MockCanvas {
    constructor() { this.width = 0; this.height = 0; }
    getContext() {
      return {
        drawImage: vi.fn(),
        imageSmoothingQuality: 'high'
      };
    }
    toBlob(cb, type, quality) {
      cb({ size: 1024, type: type });
    }
  }

  globalThis.document = {
    createElement: (tag) => {
      if (tag === 'img') return new MockImage();
      if (tag === 'canvas') return new MockCanvas();
      return {};
    }
  };

  globalThis.URL = {
    createObjectURL: (f) => f ? "blob:mock" : "",
    revokeObjectURL: vi.fn()
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
    | Error(msg) => t->expect(msg)->Expect.toBe("Success") // Should not happen
    }
  })

  testAsync("compressToWebP handles object URL failure", async t => {
    // Mock failure
    let _ = %raw(`globalThis.URL.createObjectURL = () => ""`)

    let mockFile: File.t = Obj.magic({"size": 5000})
    let result = await compressToWebP(mockFile, 0.8)

    switch result {
    | Ok(_) => t->expect(true)->Expect.toBe(false)
    | Error(msg) => t->expect(msg)->Expect.String.toContain("Failed to create object URL")
    }

    // Restore
    let _ = %raw(`globalThis.URL.createObjectURL = (f) => "blob:mock"`)
  })

  testAsync("compressToWebP handles image load failure", async t => {
    // We can't easily force error without complex mock signaling, but let's try via src
    // In our MockImage, if src is 'error-url', it triggers error

    // Overwrite the safeCreateObjectURL locally for this test or just mock URL again
    let _ = %raw(`globalThis.URL.createObjectURL = () => "error-url"`)

    let mockFile: File.t = Obj.magic({"size": 5000})
    let result = await compressToWebP(mockFile, 0.8)

    switch result {
    | Ok(_) => t->expect(true)->Expect.toBe(false)
    | Error(msg) => t->expect(msg)->Expect.String.toContain("Failed to load image")
    }

    let _ = %raw(`globalThis.URL.createObjectURL = (f) => "blob:mock"`)
  })

  testAsync("compressToWebP scales down large images", async t => {
    let _ = %raw(`(() => {
      globalThis.originalCreateElement = document.createElement;
      document.createElement = (tag) => {
        if (tag === 'img') {
          const img = new MockImage();
          img.width = 8192;
          img.height = 4096;
          return img;
        }
        if (tag === 'canvas') {
           const c = new MockCanvas();
           globalThis.testCanvas = c;
           return c;
        }
        return {};
      }
    })()`)

    let mockFile: File.t = Obj.magic({"size": 20000000})
    let _ = await compressToWebP(mockFile, 0.8)

    let w = %raw(`globalThis.testCanvas.width`)
    let h = %raw(`globalThis.testCanvas.height`)

    // Restore
    let _ = %raw(`document.createElement = globalThis.originalCreateElement`)

    // Should be scaled to max 4096 width, keeping 2:1 ratio => 4096 x 2048
    t->expect(w)->Expect.toBe(4096)
    t->expect(h)->Expect.toBe(2048)
  })

  testAsync("compressToWebPConstrained respects custom bounds", async t => {
    let _ = %raw(`(() => {
      globalThis.originalCreateElement = document.createElement;
      document.createElement = (tag) => {
        if (tag === 'img') {
          const img = new MockImage();
          img.width = 1000;
          img.height = 1000;
          return img;
        }
        if (tag === 'canvas') {
           const c = new MockCanvas();
           globalThis.testCanvasConstrained = c;
           return c;
        }
        return {};
      }
    })()`)

    let mockFile: File.t = Obj.magic({"size": 1000000})
    let _ = await compressToWebPConstrained(
      mockFile,
      ~quality=0.8,
      ~maxWidth=500.0,
      ~maxHeight=250.0,
    )

    let w = %raw(`globalThis.testCanvasConstrained.width`)
    let h = %raw(`globalThis.testCanvasConstrained.height`)

    // Restore
    let _ = %raw(`document.createElement = globalThis.originalCreateElement`)

    // Source 1000x1000 (1:1), constraints 500x250.
    // Preserving 1:1 ratio, it should fit within 500x250.
    // So it should be 250x250.
    t->expect(w)->Expect.toBe(250)
    t->expect(h)->Expect.toBe(250)
  })
})
