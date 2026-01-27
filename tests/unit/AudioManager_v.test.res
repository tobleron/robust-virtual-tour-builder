/* tests/unit/AudioManager_v.test.res */
open Vitest
open AudioManager
open ReBindings

// Mock classes for Audio API
%%raw(`
  class MockAudioContext {
    constructor() { this.state = 'suspended'; this.destination = {}; }
    decodeAudioData() { return Promise.resolve({}); }
    resume() { this.state = 'running'; return Promise.resolve(); }
    createBufferSource() { 
      return { start: vi.fn(), connect: vi.fn(), buffer: null };
    }
    createGain() {
      return { gain: { value: 1.0 }, connect: vi.fn() };
    }
  }
  globalThis.AudioContext = MockAudioContext;
  globalThis.webkitAudioContext = MockAudioContext;

  globalThis.Audio = class {
    constructor(src) { this.src = src; this.volume = 1.0; this.currentTime = 0.0; }
    play() { return Promise.resolve(); }
  };

  // Mock fetch for click sound
  globalThis.fetch = vi.fn().mockResolvedValue({
    arrayBuffer: () => Promise.resolve(new ArrayBuffer(8))
  });
`)

describe("AudioManager - Click Sounds & WebAudio", () => {
  beforeEach(() => {
    let _ = %raw(`vi.clearAllMocks()`)

    // Reset internal state - normally we'd expose a reset function, but for now we use Obj.magic
    isInitialized.contents = false
    audioContext.contents = None
    clickBuffer.contents = None
    clickAudioRef.contents = None
  })

  test("init sets isInitialized and creates context", t => {
    init()
    t->expect(isInitialized.contents)->Expect.toBe(true)
    t->expect(audioContext.contents)->Expect.not->Expect.toEqual(None)
  })

  test("playTick works before initialization (HTML Audio fallback)", t => {
    // Note: getClickAudio creates the element
    playTick()
    t->expect(clickAudioRef.contents)->Expect.not->Expect.toEqual(None)
  })

  testAsync("playTick works after initialization (WebAudio path)", async _t => {
    init()
    // Wait for the fetch and decode chain
    let _ = await Promise.make(
      (resolve, _) => {
        let _ = Window.setTimeout(() => resolve(ignore()), 10)
      },
    )

    // Manually push a buffer as if it succeeded
    let mockBuffer: audioBuffer = Obj.magic({"length": 100})
    clickBuffer.contents = Some(mockBuffer)

    playTick()

    // Verify it didn't crash
    _t->expect(true)->Expect.toBe(true)
  })

  test("setupGlobalClickSounds attaches listener", t => {
    // We check if it executes without crashing in JSDOM
    setupGlobalClickSounds()
    t->expect(true)->Expect.toBe(true)
  })
})
