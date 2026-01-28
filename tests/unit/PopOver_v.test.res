// @efficiency: infra-adapter
open Vitest
open ReBindings

external makeStyle: {..} => ReactDOM.Style.t = "%identity"

describe("PopOver", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  // Setup global mocks
  beforeEach(() => {
    let _ = %raw(`
      (function() {
        Object.defineProperty(window, 'innerWidth', { writable: true, configurable: true, value: 1024 });
        Object.defineProperty(window, 'innerHeight', { writable: true, configurable: true, value: 768 });
        
        const original = window.Element.prototype.getBoundingClientRect;
        window.Element.prototype.getBoundingClientRect = function() {
          if (this.classList.contains('popover-root')) {
            return { width: 200, height: 100, top: 0, left: 0, bottom: 100, right: 200, x: 0, y: 0 };
          }
          if (this.id === 'anchor-element') {
             return this._mockRect || { top: 0, left: 0, width: 0, height: 0, bottom: 0, right: 0, x: 0, y: 0 };
          }
          return { top: 0, left: 0, width: 0, height: 0, bottom: 0, right: 0, x: 0, y: 0 };
        };
        window.Element.prototype._originalGetBoundingClientRect = original;
      })()
    `)
  })

  afterEach(() => {
    let _ = %raw(`
      (function() {
        if (window.Element.prototype._originalGetBoundingClientRect) {
          window.Element.prototype.getBoundingClientRect = window.Element.prototype._originalGetBoundingClientRect;
        }
        // Clean up portal root
        const portal = document.getElementById('portal-root');
        if (portal) portal.innerHTML = '';
      })()
    `)
  })

  testAsync("should calculate position and render in portal", async t => {
    let anchor = Dom.createElement("div")
    Dom.setId(anchor, "anchor-element")
    Dom.appendChild(Dom.documentBody, anchor)

    let _ = %raw(`
      anchor._mockRect = {
        top: 100, left: 100, bottom: 120, right: 150,
        width: 50, height: 20
      }
    `)

    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)
    let root = ReactDOMClient.createRoot(container)

    ReactDOMClient.Root.render(
      root,
      <PopOver anchor={anchor} onClose={() => ()} alignment=#BottomLeft>
        <div style={makeStyle({"width": "200px", "height": "100px"})}>
          {React.string("Popover Content")}
        </div>
      </PopOver>,
    )

    await wait(150)

    let portalRoot = Dom.getElementById("portal-root")
    t->expect(Belt.Option.isSome(Nullable.toOption(portalRoot)))->Expect.toBe(true)

    switch Nullable.toOption(portalRoot) {
    | Some(rootEl) =>
      let popover = Dom.querySelector(rootEl, ".popover-root")
      t->expect(Belt.Option.isSome(Nullable.toOption(popover)))->Expect.toBe(true)

      switch Nullable.toOption(popover) {
      | Some(el) =>
        let style = Dom.getAttribute(el, "style")
        t->expect(String.includes(style, "top: 128px"))->Expect.toBe(true)
        t->expect(String.includes(style, "left: 100px"))->Expect.toBe(true)
      | None => ()
      }
    | None => ()
    }

    Dom.removeElement(container)
    Dom.removeElement(anchor)
  })

  testAsync("should handle outside click", async t => {
    let anchor = Dom.createElement("div")
    Dom.setId(anchor, "anchor-element")
    Dom.appendChild(Dom.documentBody, anchor)
    let closed = ref(false)

    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)
    let root = ReactDOMClient.createRoot(container)

    ReactDOMClient.Root.render(
      root,
      <PopOver anchor={anchor} onClose={() => closed := true} alignment=#BottomLeft>
        <div> {React.string("Content")} </div>
      </PopOver>,
    )

    await wait(150)

    let _ = %raw(`document.body.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }))`)

    t->expect(closed.contents)->Expect.toBe(true)

    Dom.removeElement(container)
    Dom.removeElement(anchor)
  })

  testAsync("should reposition to TopLeft when space below is insufficient", async t => {
    let anchor = Dom.createElement("div")
    Dom.setId(anchor, "anchor-element")
    Dom.appendChild(Dom.documentBody, anchor)

    // Place anchor near bottom-right
    let _ = %raw(`
      anchor._mockRect = {
        top: 700, left: 800, bottom: 720, right: 850,
        width: 50, height: 20
      }
    `)

    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)
    let root = ReactDOMClient.createRoot(container)

    ReactDOMClient.Root.render(
      root,
      <PopOver anchor={anchor} onClose={() => ()} alignment=#Auto>
        <div style={makeStyle({"width": "200px", "height": "100px"})}>
          {React.string("Content")}
        </div>
      </PopOver>,
    )

    await wait(150)

    let portalRoot = Dom.getElementById("portal-root")
    switch Nullable.toOption(portalRoot) {
    | Some(rootEl) =>
      let popover = Dom.querySelector(rootEl, ".popover-root")
      switch Nullable.toOption(popover) {
      | Some(el) =>
        let style = Dom.getAttribute(el, "style")
        // top = anchorRect.top (700) - popoverRect.height (100) - offset (8) = 592
        t->expect(String.includes(style, "top: 592px"))->Expect.toBe(true)
        // left = anchorRect.left (800)
        t->expect(String.includes(style, "left: 800px"))->Expect.toBe(true)
      | None => ()
      }
    | None => ()
    }

    Dom.removeElement(container)
    Dom.removeElement(anchor)
  })

  testAsync("should clamp position to viewport", async t => {
    let anchor = Dom.createElement("div")
    Dom.setId(anchor, "anchor-element")
    Dom.appendChild(Dom.documentBody, anchor)

    // Place anchor at top-left corner
    let _ = %raw(`
      anchor._mockRect = {
        top: 0, left: 0, bottom: 10, right: 10,
        width: 10, height: 10
      }
    `)

    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)
    let root = ReactDOMClient.createRoot(container)

    // Request TopLeft alignment which would normally result in negative top/left
    ReactDOMClient.Root.render(
      root,
      <PopOver anchor={anchor} onClose={() => ()} alignment=#TopLeft>
        <div style={makeStyle({"width": "200px", "height": "100px"})}>
          {React.string("Content")}
        </div>
      </PopOver>,
    )

    await wait(150)

    let portalRoot = Dom.getElementById("portal-root")
    switch Nullable.toOption(portalRoot) {
    | Some(rootEl) =>
      let popover = Dom.querySelector(rootEl, ".popover-root")
      switch Nullable.toOption(popover) {
      | Some(el) =>
        let style = Dom.getAttribute(el, "style")
        // Should be clamped to offset (8)
        t->expect(String.includes(style, "top: 8px"))->Expect.toBe(true)
        t->expect(String.includes(style, "left: 8px"))->Expect.toBe(true)
      | None => ()
      }
    | None => ()
    }

    Dom.removeElement(container)
    Dom.removeElement(anchor)
  })

  testAsync("should add popover-tooltip class when isTooltip is true", async t => {
    let anchor = Dom.createElement("div")
    Dom.setId(anchor, "anchor-element")
    Dom.appendChild(Dom.documentBody, anchor)

    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)
    let root = ReactDOMClient.createRoot(container)

    ReactDOMClient.Root.render(
      root,
      <PopOver anchor={anchor} onClose={() => ()} isTooltip=true>
        <div> {React.string("Tooltip")} </div>
      </PopOver>,
    )

    await wait(150)

    let portalRoot = Dom.getElementById("portal-root")
    switch Nullable.toOption(portalRoot) {
    | Some(rootEl) =>
      let popover = Dom.querySelector(rootEl, ".popover-root")
      switch Nullable.toOption(popover) {
      | Some(el) => t->expect(Dom.contains(el, "popover-tooltip"))->Expect.toBe(true)
      | None => ()
      }
    | None => ()
    }

    Dom.removeElement(container)
    Dom.removeElement(anchor)
  })
})
