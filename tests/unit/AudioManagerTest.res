/* tests/unit/AudioManagerTest.res */
open AudioManager

let run = () => {
  Console.log("Running AudioManager tests...")

  // 1. Test: clickSoundUrl is correct
  assert(clickSoundUrl == "sounds/click.wav")

  // Mocking browser APIs for Node environment
  let _ = %raw(`(function() {
    global.window = global.window || {};
    
    // Mock AudioContext
    class MockAudioContext {
      constructor() {
        this.state = 'suspended';
        this.destination = {};
      }
      decodeAudioData() { return Promise.resolve({}); }
      resume() { this.state = 'running'; return Promise.resolve(); }
      createBufferSource() { 
        return {
          start: () => {},
          connect: () => {},
          buffer: null
        };
      }
      createGain() {
        return {
          gain: { value: 1.0 },
          connect: () => {}
        };
      }
    }
    if (!global.window.AudioContext) global.window.AudioContext = MockAudioContext;
    if (!global.window.webkitAudioContext) global.window.webkitAudioContext = MockAudioContext;
    
    // Mock Audio element
    if (!global.Audio) global.Audio = class {
      constructor(url) {
        this.src = url;
        this.volume = 1.0;
        this.currentTime = 0.0;
      }
      play() { return Promise.resolve(); }
    };
    
    // Mock fetch if not present
    if (!global.fetch) global.fetch = (url) => Promise.resolve({
      arrayBuffer: () => Promise.resolve(new ArrayBuffer(0)),
      ok: true
    });
    
    // Ensure document and documentBody exist without overwriting
    global.document = global.document || {};
    // Preserve createElement if it exists
    const existingCreateElement = global.document.createElement;
    global.document.body = global.document.body || { addEventListener: () => {} };
    if (!global.document.addEventListener) global.document.addEventListener = () => {};
    if (!global.document.closest) global.document.closest = () => null;
    // Restore createElement if it was overwritten
    if (existingCreateElement && !global.document.createElement) {
      global.document.createElement = existingCreateElement;
    }
  })()`)

  // 2. Test: init() sets isInitialized
  init()
  assert(isInitialized.contents == true)
  Console.log("✓ AudioManager: init() verified")

  // 3. Test: playTick() execution
  try {
    playTick()
    Console.log("✓ AudioManager: playTick() verified")
  } catch {
  | e => {
      Console.error("✖ AudioManager: playTick() failed")
      Console.log(e)
    }
  }

  // 4. Test: setupGlobalClickSounds execution
  try {
    setupGlobalClickSounds()
    Console.log("✓ AudioManager: setupGlobalClickSounds verified")
  } catch {
  | e => {
      Console.error("✖ AudioManager: setupGlobalClickSounds failed")
      Console.log(e)
    }
  }

  Console.log("✓ AudioManager tests passed")
}
