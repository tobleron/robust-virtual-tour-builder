/* src/ReBindings.res - Lightweight facade for specialized bindings */

module Browser_ = {
  module Blob = {
    type t
    @new external newBlob: (array<'a>, {..}) => t = "Blob"
    @get external size: t => float = "size"
    @get external type_: t => string = "type"
  }

  module JsHelpers = {
    @scope("Array") @val external from: 'a => array<'b> = "from"
  }

  module JSWeakMap = {
    type t<'k, 'v>
    @new external make: unit => t<'k, 'v> = "WeakMap"
    @send external get: (t<'k, 'v>, 'k) => Nullable.t<'v> = "get"
    @send external set: (t<'k, 'v>, 'k, 'v) => unit = "set"
  }

  module BrowserArrayBuffer = {
    type t = Js.Typed_array.ArrayBuffer.t
  }

  module File = {
    type t
    @new external newFile: (array<'a>, string, {..}) => t = "File"
    @get external name: t => string = "name"
    @get external size: t => float = "size"
    @get external type_: t => string = "type"
  }

  module FileList = {
    type t
    @get external length: t => int = "length"
    @send @return(nullable) external item: (t, int) => option<File.t> = "item"
    @get_index @return(nullable) external item_get: (t, int) => option<File.t> = ""
  }

  module JSZip = {
    type t
    type zipObject

    @new external create: unit => t = "JSZip"
    @val @scope("JSZip") external loadAsync: Blob.t => Promise.t<t> = "loadAsync"

    @send external file: (t, string) => Nullable.t<zipObject> = "file"
    @send external async: (zipObject, string) => Promise.t<'a> = "async"
    @send external generateAsync: (t, {..}) => Promise.t<Blob.t> = "generateAsync"
  }

  module AbortController = {
    type t
    type signal

    @new external newAbortController: unit => t = "AbortController"
    @get external signal: t => signal = "signal"
    @send external abort: t => unit = "abort"
  }
}
include Browser_

module Dom_ = {
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
    @get @return(nullable) external getFiles: element => option<Browser_.FileList.t> = "files"
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
}
include Dom_

module WebApi_ = {
  module URL = {
    @scope("URL") @val external createObjectURL: 'a => string = "createObjectURL"
    @scope("URL") @val external revokeObjectURL: string => unit = "revokeObjectURL"
  }

  module Fetch = {
    type response
    type requestInit<'body>
    @obj
    external requestInit: (
      ~method: string,
      ~body: 'body=?,
      ~headers: dict<string>=?,
      ~signal: Browser_.AbortController.signal=?,
      unit,
    ) => requestInit<'body> = ""

    @val external fetch: (string, requestInit<'body>) => Promise.t<response> = "fetch"
    @val external fetchSimple: string => Promise.t<response> = "fetch"

    @send external json: response => Promise.t<'a> = "json"
    @send external text: response => Promise.t<string> = "text"
    @send
    external arrayBuffer: response => Promise.t<Browser_.BrowserArrayBuffer.t> = "arrayBuffer"
    @send external blob: response => Promise.t<Browser_.Blob.t> = "blob"
    @get external ok: response => bool = "ok"
    @get external status: response => int = "status"
    @get external statusText: response => string = "statusText"
  }

  module FormData = {
    type t
    @new external newFormData: unit => t = "FormData"
    @send external append: (t, string, 'a) => unit = "append"
    @send external appendWithFilename: (t, string, 'a, string) => unit = "append"
  }
}
include WebApi_

module Graphics_ = {
  module Canvas = {
    type context2d
    @send external getContext2d: (Dom_.Dom.element, string, {..}) => context2d = "getContext"

    @set external setFillStyle: (context2d, string) => unit = "fillStyle"
    @set external setStrokeStyle: (context2d, string) => unit = "strokeStyle"
    @set external setLineWidth: (context2d, float) => unit = "lineWidth"
    @set external setGlobalAlpha: (context2d, float) => unit = "globalAlpha"
    @set external setShadowColor: (context2d, string) => unit = "shadowColor"
    @set external setShadowBlur: (context2d, float) => unit = "shadowBlur"
    @set external setShadowOffsetX: (context2d, float) => unit = "shadowOffsetX"
    @set external setShadowOffsetY: (context2d, float) => unit = "shadowOffsetY"

    @send external fillRect: (context2d, float, float, float, float) => unit = "fillRect"
    @send
    external drawImage: (context2d, Dom_.Dom.element, float, float, float, float) => unit =
      "drawImage"
    @send
    external drawImageCoords: (
      context2d,
      Dom_.Dom.element,
      float,
      float,
      float,
      float,
      float,
      float,
      float,
      float,
      float,
      float,
    ) => unit = "drawImage"

    @send external beginPath: context2d => unit = "beginPath"
    @send external stroke: context2d => unit = "stroke"
    @send external fill: context2d => unit = "fill"
    @send external save: context2d => unit = "save"
    @send external restore: context2d => unit = "restore"

    @send external roundRect: (context2d, float, float, float, float, float) => unit = "roundRect"
    @send external rect: (context2d, float, float, float, float) => unit = "rect"
  }

  module Svg = {
    let namespace = "http://www.w3.org/2000/svg"

    @scope("document") @val
    external createElementNS: (string, string) => Dom_.Dom.element = "createElementNS"
    @send external setAttribute: (Dom_.Dom.element, string, string) => unit = "setAttribute"
    @send
    external appendChild: (Dom_.Dom.element, Dom_.Dom.element) => unit = "appendChild"

    @set external setOnMouseOver: (Dom_.Dom.element, unit => unit) => unit = "onmouseover"
    @set external setOnMouseOut: (Dom_.Dom.element, unit => unit) => unit = "onmouseout"
  }
}
include Graphics_

module Viewer_ = {
  module Viewer = {
    type t
    @scope("window") @val external instance: Nullable.t<t> = "pannellumViewer"

    type hotspotConfig = {"id": string, "pitch": float, "yaw": float, "type": string}

    type config = {"hotSpots": array<hotspotConfig>}

    type mouseEvent = {"clientX": float, "clientY": float}

    @send external getPitch: t => float = "getPitch"
    @send external getYaw: t => float = "getYaw"
    @send external getHfov: t => float = "getHfov"

    @send external setPitch: (t, float, bool) => unit = "setPitch"
    @send external setYaw: (t, float, bool) => unit = "setYaw"
    @send external setHfov: (t, float, bool) => unit = "setHfov"

    @send external mouseEventToCoords: (t, mouseEvent) => array<float> = "mouseEventToCoords"
    @send external setYawWithDuration: (t, float, int) => unit = "setYaw"

    @send external getConfig: t => config = "getConfig"
    @send external removeHotSpot: (t, string) => unit = "removeHotSpot"
    @send external addHotSpot: (t, {..}) => unit = "addHotSpot"

    @send external destroy: t => unit = "destroy"
    @send external on: (t, string, 'event => unit) => unit = "on"
    @send external getScene: t => string = "getScene"
    @send external loadScene: (t, string, float, float, float) => unit = "loadScene"
    @send external isLoaded: t => bool = "isLoaded"
  }

  module Pannellum = {
    @scope("pannellum") @val external viewer: (string, {..}) => Viewer.t = "viewer"
  }
}
include Viewer_

module Idb_ = {
  @module("idb-keyval")
  external set: (string, 'a) => Promise.t<unit> = "set"

  @module("idb-keyval")
  external get: string => Promise.t<Nullable.t<'a>> = "get"

  @module("idb-keyval")
  external del: string => Promise.t<unit> = "del"

  @module("idb-keyval")
  external clear: unit => Promise.t<unit> = "clear"
}
include Idb_
