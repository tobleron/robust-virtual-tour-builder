/* tests/unit/ProgressBarTest.res */
open ProgressBar

let run = () => {
  Console.log("Running ProgressBar tests...")

  /* Setup mock environment */
  ignore(
    %raw(`(function() {
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

    global.elements = elements; 
    global.document = {
      getElementById: function(id) {
        if (!elements[id]) elements[id] = createMockElement(id);
        return elements[id];
      },
      querySelector: function() { return null; },
      body: {
        querySelector: function() { return null; }
      }
    };

    if (typeof global.window === 'undefined') {
      global.window = global;
    }
    
    // Ensure setTimeout/clearTimeout are available as globals which they should be in Node
  })()`),
  )

  try {
    // 1. Test progress update (Normal case)
    updateProgressBar(45.5, "Processing...", ())

    ignore(
      %raw(`(function() {
      const bar = global.elements["progress-bar"];
      const percentage = global.elements["progress-percentage"];
      const textContent = global.elements["progress-text-content"];
      
      if (!bar) throw new Error("progress-bar element not found");
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
    })()`),
    )
    Console.log("✓ updateProgressBar: updates width, percentage (rounded), and text")

    // 2. Test clamping (Over 100%)
    updateProgressBar(150.0, "Clamping...", ())
    ignore(
      %raw(`(function() {
      const bar = global.elements["progress-bar"];
      if (bar.style.width !== "100%") {
        throw new Error("Progress bar width not clamped to 100%: " + bar.style.width);
      }
    })()`),
    )
    Console.log("✓ updateProgressBar: clamps values > 100")

    // 3. Test clamping (Under 0%)
    updateProgressBar(-10.0, "Clamping Negative...", ())
    ignore(
      %raw(`(function() {
      const bar = global.elements["progress-bar"];
      if (bar.style.width !== "0%") {
        throw new Error("Progress bar width not clamped to 0%: " + bar.style.width);
      }
    })()`),
    )
    Console.log("✓ updateProgressBar: clamps values < 0")

    // 4. Test visibility = false
    updateProgressBar(50.0, "Hiding", ~visible=false, ())
    ignore(
      %raw(`(function() {
      const ui = global.elements["processing-ui"];
      if (ui.style.opacity !== "0") {
        throw new Error("Processing UI opacity not set to 0 when hidden");
      }
    })()`),
    )
    Console.log("✓ updateProgressBar: handles visible=false")

    // 5. Test title update
    updateProgressBar(10.0, "Subtext", ~title="Major Title", ())
    ignore(
      %raw(`(function() {
      const titleEl = global.elements["progress-title"];
      if (titleEl.textContent !== "Major Title") {
        throw new Error("Progress title not updated correctly: " + titleEl.textContent);
      }
    })()`),
    )
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
