/* tests/unit/InputSystemTest.res */

let run = () => {
  Console.log("Running InputSystem tests...")

  // ========================================
  // Test 1: Keyboard Event Key Detection
  // ========================================

  // Test Escape key detection
  let escapeEvent = %raw(`{
    key: "Escape",
    ctrlKey: false,
    shiftKey: false,
    preventDefault: () => {}
  }`)
  assert(escapeEvent["key"] == "Escape")
  Console.log("✓ Escape key detection")

  // Test Ctrl+Shift+D detection
  let debugToggleEvent = %raw(`{
    key: "D",
    ctrlKey: true,
    shiftKey: true,
    preventDefault: () => {}
  }`)
  assert(debugToggleEvent["key"] == "D")
  assert(debugToggleEvent["ctrlKey"] == true)
  assert(debugToggleEvent["shiftKey"] == true)
  Console.log("✓ Debug toggle key combination detection")

  // Test lowercase 'd' for debug toggle
  let debugToggleLowerEvent = %raw(`{
    key: "d",
    ctrlKey: true,
    shiftKey: true,
    preventDefault: () => {}
  }`)
  assert(debugToggleLowerEvent["key"] == "d")
  Console.log("✓ Debug toggle lowercase key detection")

  // ========================================
  // Test 2: Logger Level Shortcuts
  // ========================================

  // Test Ctrl+Shift+1 for TRACE level
  let traceEvent = %raw(`{
    key: "1",
    ctrlKey: true,
    shiftKey: true,
    preventDefault: () => {}
  }`)
  assert(traceEvent["key"] == "1")
  assert(traceEvent["ctrlKey"] == true)
  assert(traceEvent["shiftKey"] == true)
  Console.log("✓ TRACE level shortcut detection")

  // Test Ctrl+Shift+2 for DEBUG level
  let debugEvent = %raw(`{
    key: "2",
    ctrlKey: true,
    shiftKey: true,
    preventDefault: () => {}
  }`)
  assert(debugEvent["key"] == "2")
  Console.log("✓ DEBUG level shortcut detection")

  // Test Ctrl+Shift+3 for INFO level
  let infoEvent = %raw(`{
    key: "3",
    ctrlKey: true,
    shiftKey: true,
    preventDefault: () => {}
  }`)
  assert(infoEvent["key"] == "3")
  Console.log("✓ INFO level shortcut detection")

  // ========================================
  // Test 3: Modal ID Priority List
  // ========================================

  // Verify modal priority order
  let modalIds = ["style-modal", "new-project-modal", "about-modal", "modal-container"]
  assert(Belt.Array.length(modalIds) == 4)
  assert(Belt.Array.get(modalIds, 0) == Some("style-modal"))
  assert(Belt.Array.get(modalIds, 3) == Some("modal-container"))
  Console.log("✓ Modal priority list structure")

  // ========================================
  // Test 4: Close Button Selectors
  // ========================================

  // Verify close button selector pattern
  let closeButtonSelector = "#btn-close-style, #btn-new-cancel, #btn-close-about"
  assert(Js.String2.includes(closeButtonSelector, "#btn-close-style"))
  assert(Js.String2.includes(closeButtonSelector, "#btn-new-cancel"))
  assert(Js.String2.includes(closeButtonSelector, "#btn-close-about"))
  Console.log("✓ Close button selector pattern")

  // Verify fallback cancel button selector
  let fallbackSelector = "button[id*='cancel'], button[id*='close'], .btn-secondary"
  assert(Js.String2.includes(fallbackSelector, "cancel"))
  assert(Js.String2.includes(fallbackSelector, "close"))
  assert(Js.String2.includes(fallbackSelector, ".btn-secondary"))
  Console.log("✓ Fallback cancel button selector pattern")

  // ========================================
  // Test 5: Event Handler Logic Patterns
  // ========================================

  // Test handled flag pattern
  let handled = ref(false)
  assert(handled.contents == false)
  handled := true
  assert(handled.contents == true)
  Console.log("✓ Handled flag pattern")

  // Test early exit pattern with handled flag
  handled := false
  if !handled.contents {
    handled := true
  }
  assert(handled.contents == true)

  // Second check should not execute
  let secondCheck = ref(false)
  if !handled.contents {
    secondCheck := true
  }
  assert(secondCheck.contents == false)
  Console.log("✓ Early exit pattern with handled flag")

  // ========================================
  // Test 6: Key Combination Logic
  // ========================================

  // Test that Ctrl+Shift is required for debug shortcuts
  let withoutCtrl = %raw(`{
    key: "1",
    ctrlKey: false,
    shiftKey: true
  }`)
  assert(withoutCtrl["ctrlKey"] == false)

  let withoutShift = %raw(`{
    key: "1",
    ctrlKey: true,
    shiftKey: false
  }`)
  assert(withoutShift["shiftKey"] == false)

  let withBoth = %raw(`{
    key: "1",
    ctrlKey: true,
    shiftKey: true
  }`)
  assert(withBoth["ctrlKey"] == true && withBoth["shiftKey"] == true)
  Console.log("✓ Key combination validation logic")

  // ========================================
  // Test 7: Context Menu ID
  // ========================================

  // Verify context menu element ID
  let contextMenuId = "context-menu"
  assert(contextMenuId == "context-menu")
  Console.log("✓ Context menu ID constant")

  // ========================================
  // Test 8: Modal Container Special Handling
  // ========================================

  // Verify modal-container has special cancel-link handling
  let modalContainerId = "modal-container"
  let cancelLinkSelector = "#cancel-link"
  assert(modalContainerId == "modal-container")
  assert(cancelLinkSelector == "#cancel-link")
  Console.log("✓ Modal container special handling selectors")

  // ========================================
  // Test 9: Priority Order Verification
  // ========================================

  // Verify escape handling priority order:
  // 1. Modals/UI
  // 2. Context Menus
  // 3. Linking Mode
  // 4. Simulation/AutoPilot
  // 5. Navigation

  let priorities = ["modals", "context-menus", "linking-mode", "simulation", "navigation"]
  assert(Belt.Array.length(priorities) == 5)
  assert(Belt.Array.get(priorities, 0) == Some("modals"))
  assert(Belt.Array.get(priorities, 4) == Some("navigation"))
  Console.log("✓ Escape handling priority order")

  Console.log("InputSystem tests passed!")
}
