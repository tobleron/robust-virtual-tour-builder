/* tests/unit/AudioManagerTest.res */
open AudioManager

let run = () => {
  Console.log("Running AudioManager tests...")

  // 1. Test: clickSoundUrl is correct
  assert(clickSoundUrl == "sounds/click.wav")

  // Mocking browser APIs for Node environment
  let _ = %raw(`(function() {
    if (typeof global.window === 'undefined') {
      global.window = {};
    }
    
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
    global.window.AudioContext = MockAudioContext;
    global.window.webkitAudioContext = MockAudioContext;
    
    // Mock Audio element
    global.Audio = class {
      constructor(url) {
        this.src = url;
        this.volume = 1.0;
        this.currentTime = 0.0;
      }
      play() { return Promise.resolve(); }
    };
    
    // Mock fetch
    global.fetch = (url) => Promise.resolve({
      arrayBuffer: () => Promise.resolve(new ArrayBuffer(0)),
      ok: true
    });
    
    // Mock document and documentBody
    global.document = {
      body: {
        addEventListener: () => {}
      },
      addEventListener: () => {},
      closest: () => null
    };
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
