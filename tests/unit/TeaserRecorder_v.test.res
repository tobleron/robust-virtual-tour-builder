// @efficiency: infra-adapter
open Vitest
open Teaser.Recorder

/* Types */
type mockFn
@send external mockResolvedValue: (mockFn, 'a) => unit = "mockResolvedValue"
@send external mockReturnValue: (mockFn, 'a) => unit = "mockReturnValue"
@send external mockImplementation: (mockFn, 'a) => unit = "mockImplementation"
@get external getMock: 'a => mockFn = "mock"

type expectation
@val external expectCall: 'a => expectation = "expect"
@send external toHaveBeenCalled: (expectation, unit) => unit = "toHaveBeenCalled"
@send external toHaveBeenCalledTimes: (expectation, int) => unit = "toHaveBeenCalledTimes"
@send external toHaveBeenCalledWith: (expectation, 'a) => unit = "toHaveBeenCalledWith"

/* Mocks */
@module("../../src/utils/Logger.bs.js") external mockInfo: 'a = "info"

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

  // Mock requestAnimationFrame
  global.requestAnimationFrame = vi.fn((cb) => {
    return 123;
  });
  global.cancelAnimationFrame = vi.fn();

  // Mock DOM
  HTMLCanvasElement.prototype.captureStream = vi.fn(() => ({
    getTracks: () => []
  }));
  
  HTMLCanvasElement.prototype.getContext = vi.fn(() => ({
    drawImage: vi.fn(),
    fillRect: vi.fn(),
    fillStyle: "",
    save: vi.fn(),
    restore: vi.fn(),
    setTransform: vi.fn(),
    translate: vi.fn(),
    scale: vi.fn(),
    globalAlpha: 1.0,
    beginPath: vi.fn(),
    fill: vi.fn(),
    rect: vi.fn(),
    roundRect: vi.fn(),
    setShadowColor: vi.fn(),
    setShadowBlur: vi.fn(),
    setShadowOffsetY: vi.fn(),
    setFillStyle: vi.fn(),
    setGlobalAlpha: vi.fn()
  }));

  // Mock document.getElementById for Overlay
  document.getElementById = vi.fn((id) => {
    if (id === 'teaser-overlay') {
       return {
         style: {},
         setAttribute: vi.fn((k, v) => {}),
         appendChild: vi.fn()
       }
    }
    return null;
  });

  document.createElement = vi.fn((tag) => {
    if (tag === 'img') return { style: {}, setAttribute: vi.fn() };
    if (tag === 'canvas') return {
        width: 0,
        height: 0,
        style: {},
        setAttribute: vi.fn(),
        getContext: vi.fn(() => ({
            drawImage: vi.fn(),
            fillRect: vi.fn(),
            fillStyle: "",
            save: vi.fn(),
            restore: vi.fn(),
            setTransform: vi.fn(),
            translate: vi.fn(),
            scale: vi.fn(),
            globalAlpha: 1.0,
            beginPath: vi.fn(),
            fill: vi.fn(),
            rect: vi.fn(),
            roundRect: vi.fn(),
            setShadowColor: vi.fn(),
            setShadowBlur: vi.fn(),
            setShadowOffsetY: vi.fn(),
            setFillStyle: vi.fn(),
            setGlobalAlpha: vi.fn()
        })),
        captureStream: vi.fn(() => ({
            getTracks: () => []
        }))
    };
    if (tag === 'div') return {
        style: {},
        setAttribute: vi.fn(),
        appendChild: vi.fn(),
        id: ""
    };
    return {};
  });

  document.body.appendChild = vi.fn();

  vi.mock('../../src/utils/Logger.bs.js', () => ({
    info: vi.fn(),
    warn: vi.fn(),
    error: vi.fn(),
    trace: vi.fn(),
    initialized: vi.fn(),
    castToJson: (obj) => obj
  }));
`)

describe("TeaserRecorder", () => {
  beforeEach(() => {
    let _ = %raw(`vi.clearAllMocks()`)
    stopRecording()
  })

  testAsync("startRecording initializes MediaRecorder and Ghost Canvas", async t => {
    let success = startRecording()

    t->expect(success)->Expect.toBe(true)

    let started = %raw(`mockInfo.mock.calls.some(args => args[1] === "RECORDING_START")`)
    t->expect(started)->Expect.toBe(true)
  })

  test("stopRecording stops MediaRecorder", t => {
    let _ = startRecording()
    stopRecording()

    let stopped = %raw(`mockInfo.mock.calls.some(args => args[1] === "RECORDING_STOP")`)
    t->expect(stopped)->Expect.toBe(true)
  })

  test("setFadeOpacity updates overlay", t => {
    setFadeOpacity(0.5)

    let called = %raw(`
      document.getElementById.mock.calls.some(args => args[0] === "teaser-overlay")
    `)
    t->expect(called)->Expect.toBe(true)
  })

  test("startAnimationLoop requests animation frame", t => {
    let logoState: TeaserRecorder.logoResult = {
      img: None,
      loaded: false,
    }
    startAnimationLoop(false, logoState)

    let rafCalls = %raw(`global.requestAnimationFrame.mock.calls.length`)
    t->expect(rafCalls)->Expect.Int.toBeGreaterThan(0)
  })
})
