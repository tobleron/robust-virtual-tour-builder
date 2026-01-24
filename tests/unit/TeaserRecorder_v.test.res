open Vitest
open TeaserRecorder

/* Types */
type mockFn
@send external mockResolvedValue: (mockFn, 'a) => unit = "mockResolvedValue"
@send external mockReturnValue: (mockFn, 'a) => unit = "mockReturnValue"

type expectation
@val external expectCall: 'a => expectation = "expect"
@send external toHaveBeenCalled: (expectation, unit) => unit = "toHaveBeenCalled"
@send external toHaveBeenCalledWith: (expectation, 'a) => unit = "toHaveBeenCalledWith"

/* Mocks */
%%raw(`
  import { vi } from 'vitest';

  // Mock MediaRecorder
  global.MediaRecorder = class MediaRecorder {
    constructor(stream, options) {
      this.stream = stream;
      this.state = "inactive";
      this.ondataavailable = null;
      this.onstop = null;
    }
    start() { this.state = "recording"; }
    stop() { 
      this.state = "inactive"; 
      if (this.onstop) this.onstop();
    }
    pause() { this.state = "paused"; }
    resume() { this.state = "recording"; }
  };

  HTMLCanvasElement.prototype.captureStream = vi.fn(() => ({
    getTracks: () => []
  }));
  
  HTMLCanvasElement.prototype.getContext = vi.fn(() => ({
    // Mock minimal context
    drawImage: vi.fn(),
    fillRect: vi.fn(),
    fillStyle: "",
  }));

  // Mock ReBindings Canvas/Dom if needed, but JSDOM handles basic creation.
  // TeaserRecorder uses ReBindings.Dom.createElement("canvas").
 
  vi.mock('../../src/utils/Logger.bs.js', () => ({
    info: vi.fn(),
    warn: vi.fn(),
    error: vi.fn(),
    trace: vi.fn(),
    castToJson: (obj) => obj
  }));
`)

describe("TeaserRecorder", () => {
  beforeEach(() => {
    %raw(`vi.clearAllMocks()`)
    // Reset internal state if possible or rely on fresh restart.
    // Since internalState is mutable and global, tests might leak state.
    // Ideally we should expose a reset method or use internalState access.
    // But since startRecording re-initializes chunks/mediaRecorder, it might be fine.
  })

  testAsync("startRecording initializes MediaRecorder", async t => {
    let success = startRecording()

    // It creates ghost canvas if not exists.
    // It calls captureStream.
    // It creates MediaRecorder.
    // It returns true (if success).

    // Check if captureStream was called.
    // Since we mocked the prototype, we can check calls differently?
    // Or check if success is true.

    if success {
      t->expect(true)->Expect.toBe(true)
    } else {
      // If failed, verify logs or reason
      t->expect(success)->Expect.toBe(true)
    }

    // Clean up
    stopRecording()
    t->expect(true)->Expect.toBe(true)
  })

  test("getRecordedBlobs returns empty initially", t => {
    let blobs = getRecordedBlobs()
    t->expect(blobs)->Expect.toEqual([])
  })
})
