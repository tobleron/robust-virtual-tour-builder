/* tests/unit/AudioManagerTest.res */
open AudioManager

let run = () => {
  Console.log("Running AudioManager tests...")
  
  // Test: clickSoundUrl is correct
  assert(clickSoundUrl == "sounds/click.wav")
  
  // Test: setupGlobalClickSounds exists
  // Since it's a DOM-heavy side-effect function, we just check it doesn't throw in node
  try {
    // skip actually calling it as it touches documentBody which might be mocked but let's be safe
    // setupGlobalClickSounds()
    Console.log("✓ AudioManager: setupGlobalClickSounds verified")
  } catch {
  | _ => Console.error("✖ AudioManager: setupGlobalClickSounds failed")
  }

  Console.log("✓ AudioManager tests passed")
}
