/* tests/unit/ProgressBarTest.res */
open ProgressBar

let run = () => {
  Console.log("Running ProgressBar tests...")

  // Mock DOM and Global State for Node.js environment
  %raw(`
    if (typeof global !== 'undefined' && !global.document) {
      const elements = {};
      const createMockElement = (id) => ({
        id: id,
        style: {
          setProperty: function(p, v) { this[p] = v; }
        },
        textContent: "",
        scrollTo: () => {},
        classList: {
          add: () => {},
          remove: () => {},
          contains: () => false,
          toggle: () => {}
        },
        querySelector: () => null
      });

      global.elements = elements; // Expose for inspection in tests
      global.document = {
        getElementById: (id) => {
          if (!elements[id]) elements[id] = createMockElement(id);
          return elements[id];
        },
        querySelector: () => null,
        body: {
          querySelector: () => null
        }
      };

      global.window = {
        setTimeout: (fn, delay) => { 
          fn(); 
          return 1; 
        },
        clearTimeout: () => {}
      };
    }
  `)

  try {
    // 1. Test progress update (Normal case)
    updateProgressBar(45.5, "Processing...", ())
    
    %raw(`
      const bar = global.elements["progress-bar"];
      const percentage = global.elements["progress-percentage"];
      const textContent = global.elements["progress-text-content"];
      
      if (bar.style.width !== "45.5%") {
        throw new Error("Progress bar width not updated correctly: " + bar.style.width);
      }
      // Rounding check: 45.5 -> 46%
      if (percentage.textContent !== "46%") {
        throw new Error("Progress percentage text not updated correctly: " + percentage.textContent);
      }
      if (textContent.textContent !== "Processing...") {
        throw new Error("Progress text not updated correctly: " + textContent.textContent);
      }
    `)
    Console.log("✓ updateProgressBar: updates width, percentage (rounded), and text")

    // 2. Test clamping (Over 100%)
    updateProgressBar(150.0, "Clamping...", ())
    %raw(`
      const bar = global.elements["progress-bar"];
      if (bar.style.width !== "100%") {
        throw new Error("Progress bar width not clamped to 100%: " + bar.style.width);
      }
    `)
    Console.log("✓ updateProgressBar: clamps values > 100")

    // 3. Test clamping (Under 0%)
    updateProgressBar(-10.0, "Clamping Negative...", ())
    %raw(`
      const bar = global.elements["progress-bar"];
      if (bar.style.width !== "0%") {
        throw new Error("Progress bar width not clamped to 0%: " + bar.style.width);
      }
    `)
    Console.log("✓ updateProgressBar: clamps values < 0")

    // 4. Test visibility = false
    updateProgressBar(50.0, "Hiding", ~visible=false, ())
    %raw(`
      const ui = global.elements["processing-ui"];
      if (ui.style.opacity !== "0") {
        throw new Error("Processing UI opacity not set to 0 when hidden");
      }
    `)
    Console.log("✓ updateProgressBar: handles visible=false")

    // 5. Test title update
    updateProgressBar(10.0, "Subtext", ~title="Major Title", ())
    %raw(`
      const titleEl = global.elements["progress-title"];
      if (titleEl.textContent !== "Major Title") {
        throw new Error("Progress title not updated correctly: " + titleEl.textContent);
      }
    `)
    Console.log("✓ updateProgressBar: updates title when provided")

  } catch {
  | Js.Exn.Error(e) => 
    let msg = Js.Exn.message(e)->Belt.Option.getWithDefault("Unknown error")
    Console.error("✗ ProgressBar tests failed: " ++ msg)
    assert(false)
  | _ => 
    Console.error("✗ ProgressBar tests failed with unknown error")
    assert(false)
  }

  Console.log("✓ All ProgressBar tests passed")
}