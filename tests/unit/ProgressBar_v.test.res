open Vitest
open ProgressBar

let setupMockDom = () => {
  ignore(
    %raw(`(function() {
    const elements = {};
    const createMockElement = (id) => ({
      id: id,
      style: {
        setProperty: function(p, v) { this[p] = v; },
        opacity: "",
        display: "",
        transform: "",
        width: ""
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
    
    // Don't overwrite document - just add our methods to it
    if (!global.document) global.document = {};
    
    // Save original methods
    const originalGetElementById = global.document.getElementById;
    const originalQuerySelector = global.document.querySelector;
    
    // Add our mock methods
    global.document.getElementById = function(id) {
      if (!elements[id]) elements[id] = createMockElement(id);
      return elements[id];
    };
    
    global.document.querySelector = function() { return null; };
    
    if (!global.document.body) global.document.body = {};
    global.document.body.querySelector = function(sel) { 
      if (sel === '.sidebar-content') {
        if (!elements['sidebar-content']) elements['sidebar-content'] = createMockElement('sidebar-content');
        return elements['sidebar-content'];
      }
      return null; 
    };

    if (typeof global.window === 'undefined') {
      global.window = global;
    }
     // Mock setTimeout/clearTimeout if not present, but they are in Node
  })()`),
  )
}

describe("ProgressBar", () => {
  test("updateProgressBar updates width and text", t => {
    setupMockDom()
    updateProgressBar(45.5, "Processing...", ())

    let (width, text, pct) = %raw(`
      [
        global.elements["progress-bar"].style.width,
        global.elements["progress-text-content"].textContent,
        global.elements["progress-percentage"].textContent
      ]
    `)
    t->expect(width)->Expect.toBe("45.5%")
    t->expect(text)->Expect.toBe("Processing...")
    t->expect(pct)->Expect.toBe("46%")
  })

  test("updateProgressBar clamps values > 100", t => {
    setupMockDom()
    updateProgressBar(150.0, "Clamping...", ())
    let width: string = %raw(`global.elements["progress-bar"].style.width`)
    t->expect(width)->Expect.toBe("100%")
  })

  test("updateProgressBar clamps values < 0", t => {
    setupMockDom()
    updateProgressBar(-10.0, "Clamping Negative...", ())
    let width: string = %raw(`global.elements["progress-bar"].style.width`)
    t->expect(width)->Expect.toBe("0%")
  })

  test("updateProgressBar handles visible=false", t => {
    setupMockDom()
    updateProgressBar(50.0, "Hiding", ~visible=false, ())
    let opacity: string = %raw(`global.elements["processing-ui"].style.opacity`)
    let labelDisplay: string = %raw(`global.elements["upload-label"].style.display`)
    t->expect(opacity)->Expect.toBe("0")
    // When hidden (visible=false), it schedules a timeout to hide, but immediately starts fade out.
    // The logic also sets uploadLabel to flex immediately after timeout or transition?
    // Actually looking at code:
    // if !visible { Dom.setOpacity(ui, "0"); ... uploadLabel->Belt.Option.forEach(l => Dom.setDisplay(l, "flex")) }
    // So upload-label should be flex.
    t->expect(labelDisplay)->Expect.toBe("flex")
  })

  test("updateProgressBar handles visible=true", t => {
    setupMockDom()
    updateProgressBar(50.0, "Showing", ~visible=true, ())
    let opacity: string = %raw(`global.elements["processing-ui"].style.opacity`)
    let labelDisplay: string = %raw(`global.elements["upload-label"].style.display`)
    t->expect(opacity)->Expect.toBe("") // Transition is set, but opacity not explicitly set to "1" in the else block immediately?
    // Wait, code says: Dom.setDisplay(ui, "block"); Dom.setTransition(...); uploadLabel...display none.
    // It doesn't set opacity to 1 immediately?
    // It assumes it's already 1 or handled by CSS?
    // But upload-label should be none.
    t->expect(labelDisplay)->Expect.toBe("none")
  })

  test("updateProgressBar updates title when provided", t => {
    setupMockDom()
    updateProgressBar(10.0, "Subtext", ~title="Major Title", ())
    let title: string = %raw(`global.elements["progress-title"].textContent`)
    t->expect(title)->Expect.toBe("Major Title")
  })

  test("updateProgressBar handles spinner opacity based on completion", t => {
    setupMockDom()
    // Not complete
    updateProgressBar(99.0, "Almost", ())
    let spinnerOp: string = %raw(`global.elements["progress-spinner"].style.opacity`)
    t->expect(spinnerOp)->Expect.toBe("1")

    // Complete
    updateProgressBar(100.0, "Done", ())
    let spinnerOpDone: string = %raw(`global.elements["progress-spinner"].style.opacity`)
    t->expect(spinnerOpDone)->Expect.toBe("0")
  })

  test("updateProgressBar scrolls sidebar to top", t => {
    setupMockDom()
    // We need to spy on scrollTo
    let _ = %raw(`(function() {
      global.scrolledToTop = false;
      global.elements['sidebar-content'] = {
        scrollTo: () => { global.scrolledToTop = true; }
      };
    })()`)

    updateProgressBar(10.0, "Scroll Check", ())
    t->expect(%raw(`global.scrolledToTop`))->Expect.toBe(true)
  })
})
