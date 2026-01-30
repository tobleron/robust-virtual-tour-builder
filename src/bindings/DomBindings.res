/* src/bindings/DomBindings.res */

module Dom = {
  type element = Dom.element
  type event = Dom.event
  type nodeList = Dom.nodeList
  type dataTransfer = Dom.dataTransfer
  type style = Dom.cssStyleDeclaration
  @send external preventDefault: event => unit = "preventDefault"
  @send external stopPropagation: event => unit = "stopPropagation"
  @get external target: event => element = "target"
  @get external key: event => string = "key"
  @get external ctrlKey: event => bool = "ctrlKey"
  @get external shiftKey: event => bool = "shiftKey"
  @get external clientX: event => int = "clientX"
  @get external clientY: event => int = "clientY"
  @get external eventPhase: event => int = "eventPhase"
  @get external dataTransfer: event => dataTransfer = "dataTransfer"
  @set external setEffectAllowed: (dataTransfer, string) => unit = "effectAllowed"
  @set external setDropEffect: (dataTransfer, string) => unit = "dropEffect"
  @send external setData: (dataTransfer, string, string) => unit = "setData"
  @val @scope("window") external document: {..} = "document"
  type rect = {
    x: float,
    y: float,
    width: float,
    height: float,
    top: float,
    right: float,
    bottom: float,
    left: float,
  }

  @scope("document") @val
  external getElementById: string => Nullable.t<element> = "getElementById"
  @send external querySelector: (element, string) => Nullable.t<element> = "querySelector"

  @set external setInnerHTML: (element, string) => unit = "inner\u0048TML"

  @send external getBoundingClientRect: element => rect = "getBoundingClientRect"

  @scope("classList") @send external add: (element, string) => unit = "add"
  @scope("classList") @send external remove: (element, string) => unit = "remove"
  @scope("classList") @send external contains: (element, string) => bool = "contains"
  @scope("classList") @send external toggle: (element, string) => unit = "toggle"

  @set @scope("style") external setCursor: (element, string) => unit = "cursor"
  @set @scope("style") external setPointerEvents: (element, string) => unit = "pointerEvents"
  @set @scope("style") external setOpacity: (element, string) => unit = "opacity"
  @set @scope("style") external setTop: (element, string) => unit = "top"
  @set @scope("style") external setLeft: (element, string) => unit = "left"
  @set @scope("style") external setStyleWidth: (element, string) => unit = "width"
  @set @scope("style") external setStyleHeight: (element, string) => unit = "height"
  @set @scope("style") external setMaxWidth: (element, string) => unit = "maxWidth"
  @set @scope("style") external setPadding: (element, string) => unit = "padding"
  @set @scope("style") external setMargin: (element, string) => unit = "margin"
  @set @scope("style") external setPosition: (element, string) => unit = "position"
  @set @scope("style") external setSize: (element, string) => unit = "size" // Added if needed
  @set @scope("style") external setOverflow: (element, string) => unit = "overflow"
  @set @scope("style") external setDisplay: (element, string) => unit = "display"
  @set @scope("style") external setMaxHeight: (element, string) => unit = "maxHeight"
  @set @scope("style") external setBackgroundColor: (element, string) => unit = "backgroundColor"
  @set external setTransition: (element, string) => unit = "transition"
  @set external setBackgroundImage: (element, string) => unit = "backgroundImage"

  module ClassList = {
    type t
    @send external contains: (t, string) => bool = "contains"
    @send external add: (t, string) => unit = "add"
    @send external remove: (t, string) => unit = "remove"
    @send external toggle: (t, string) => unit = "toggle"
  }
  @get external classList: element => ClassList.t = "classList"
  @send external containsElement: (element, element) => bool = "contains"

  @scope("document") @val external createElement: string => element = "createElement"
  @set external setId: (element, string) => unit = "id"
  @send external setAttribute: (element, string, string) => unit = "setAttribute"
  @send external getAttribute: (element, string) => string = "getAttribute"
  @send external removeAttribute: (element, string) => unit = "removeAttribute"
  @send external appendChild: (element, element) => unit = "appendChild"
  @send external addEventListener: (element, string, event => unit) => unit = "addEventListener"
  @send
  external addEventListenerNoEv: (element, string, unit => unit) => unit = "addEventListener"
  @send
  external removeEventListener: (element, string, event => unit) => unit = "removeEventListener"
  @scope("document") @val external documentBody: element = "body"

  @get external getWidth: element => int = "width"
  @set external setWidth: (element, int) => unit = "width"
  @get external getHeight: element => int = "height"
  @set external setHeight: (element, int) => unit = "height"

  @get external getComputedStyle: element => style = "getComputedStyle"

  @send @scope("style") external setProperty: (element, string, string) => unit = "setProperty"
  @send external getPropertyValue: (style, string) => string = "getPropertyValue"
  @get external getStyle: element => style = "style"

  @get external getValue: element => string = "value"
  @set external setValue: (element, string) => unit = "value"
  @get @return(nullable) external getFiles: element => option<BrowserBindings.FileList.t> = "files"
  @send external focus: element => unit = "focus"
  @send external click: element => unit = "click"
  @send external scrollTo: (element, {..}) => unit = "scrollTo"
  @send external closest: (element, string) => Nullable.t<element> = "closest"
  @send
  external addEventListenerCapture: (element, string, 'a => unit, bool) => unit =
    "addEventListener"
  @send
  external removeEventListenerCapture: (element, string, 'a => unit, bool) => unit =
    "removeEventListener"

  external unsafeToElement: 'a => element = "%identity"

  @send external removeElement: element => unit = "remove"
  @get external dataset: element => dict<string> = "dataset"
  @set external setClassName: (element, string) => unit = "className"
  @get external getClassName: element => string = "className"
  @set external setTextContent: (element, string) => unit = "textContent"
  @get external getTextContent: element => string = "textContent"
  @set external setOnClick: (element, event => unit) => unit = "onclick"
  @set external setOnScroll: (element, unit => unit) => unit = "onscroll"
  @set external setOnKeyDown: (element, event => unit) => unit = "onkeydown"
  @get external getScrollHeight: element => int = "scrollHeight"
  @get external getScrollTop: element => int = "scrollTop"
  @get external getClientHeight: element => int = "clientHeight"
  @get external getClientWidth: element => int = "clientWidth"
  @get external getOffsetTop: element => int = "offsetTop"

  @send external querySelectorAll: (element, string) => nodeList = "querySelectorAll"
  @scope("document") @val external querySelectorAllDoc: string => nodeList = "querySelectorAll"
  @get external nodeListLength: nodeList => int = "length"

  @set external setDraggable: (element, bool) => unit = "draggable"
  @val @scope("document")
  external createDocumentFragment: unit => element = "createDocumentFragment"
  @val @scope("document") external head: element = "head"
  module Storage2 = {
    type t
    @val @scope("window") external localStorage: t = "localStorage"
    @send @return(nullable) external getItem: (t, string) => option<string> = "getItem"
    @send external setItem: (t, string, string) => unit = "setItem"
    @send external removeItem: (t, string) => unit = "removeItem"
    @send external clear: t => unit = "clear"
  }
}

module ResizeObserver = {
  type t
  type entry = {
    target: Dom.element,
    contentRect: Dom.rect,
  }
  @new external make: (array<entry> => unit) => t = "ResizeObserver"
  @send external observe: (t, Dom.element) => unit = "observe"
  @send external unobserve: (t, Dom.element) => unit = "unobserve"
  @send external disconnect: t => unit = "disconnect"
}

module Window = {
  @val external requestAnimationFrame: (unit => unit) => int = "requestAnimationFrame"
  @val external cancelAnimationFrame: int => unit = "cancelAnimationFrame"
  @val external setTimeout: (unit => unit, int) => int = "setTimeout"
  @val external clearTimeout: int => unit = "clearTimeout"
  @val external setInterval: (unit => unit, int) => int = "setInterval"
  @val external clearInterval: int => unit = "clearInterval"
  @val @scope("window")
  external addEventListener: (string, Dom.event => unit) => unit = "addEventListener"
  @val @scope("window")
  external removeEventListener: (string, Dom.event => unit) => unit = "removeEventListener"
  @val @scope("window") external dispatchEvent: Dom.event => bool = "dispatchEvent"
  @scope("navigator") @val external navigatorUserAgent: string = "userAgent"
  @val external window: {..} = "window"
  @val external alert: string => unit = "alert"
  @val external getComputedStyle: Dom.element => Dom.style = "getComputedStyle"
  @val @scope("window") external innerHeight: int = "innerHeight"
  @val @scope("window") external innerWidth: int = "innerWidth"
  @val @scope("window") external confirm: string => bool = "confirm"
  @set external setDebug: ({..}, {..}) => unit = "DEBUG"
  @set external setAppLog: ({..}, array<string>) => unit = "appLog"
  @set external setOnError: ({..}, (string, string, int, int, {..}) => bool) => unit = "onerror"
  @set external setOnUnhandledRejection: ({..}, {..} => unit) => unit = "onunhandledrejection"
}

module ReactDOMPortal = {
  @module("react-dom")
  external createPortal: (React.element, Dom.element) => React.element = "createPortal"
}

external makeStyle: {..} => ReactDOM.Style.t = "%identity"

module ReactDOMClient = {
  type root
  @module("react-dom/client") @scope("default")
  external createRoot: Dom.element => root = "createRoot"

  module Root = {
    @send external render: (root, React.element) => unit = "render"
  }
}
