open Vitest
open ProgressBar

let setupMockDom = () => {
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
    global.document.body.querySelector = function() { return null; };

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
    t->expect(opacity)->Expect.toBe("0")
  })

  test("updateProgressBar updates title when provided", t => {
    setupMockDom()
    updateProgressBar(10.0, "Subtext", ~title="Major Title", ())
    let title: string = %raw(`global.elements["progress-title"].textContent`)
    t->expect(title)->Expect.toBe("Major Title")
  })
})
