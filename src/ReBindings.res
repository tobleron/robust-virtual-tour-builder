/* src/ReBindings.res - Refactored for dependency order */

/* 1. Core Browser Types must come first */
module Blob = {
  type t
  @new external newBlob: (array<'a>, {..}) => t = "Blob"
  @get external size: t => float = "size"
  @get external type_: t => string = "type"
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

/* 2. Then Modules dependent on Core Types */
module JSZip = {
  type t
  type zipObject

  @module("jszip") @new external create: unit => t = "default"
  /* Now Blob.t is defined */
  @module("jszip") external loadAsync: Blob.t => Promise.t<t> = "loadAsync"

  @send external file: (t, string) => Nullable.t<zipObject> = "file"
  @send external async: (zipObject, string) => Promise.t<'a> = "async"
  @send external generateAsync: (t, {..}) => Promise.t<Blob.t> = "generateAsync"
}

/* 3. Rest of the bindings */


module Constants = {
  @module("./constants.js") external panningVelocity: float = "PANNING_VELOCITY"
  @module("./constants.js") external panningMinDuration: float = "PANNING_MIN_DURATION"
  @module("./constants.js") external panningMaxDuration: float = "PANNING_MAX_DURATION"
  @module("./constants.js") external backendUrl: string = "BACKEND_URL"
  @module("./constants.js") external roomLabelPresets: dict<array<string>> = "ROOM_LABEL_PRESETS"
  @module("./constants.js") external idleSnapshotDelay: int = "IDLE_SNAPSHOT_DELAY"
  @module("./constants.js") external sceneLoadTimeout: int = "SCENE_LOAD_TIMEOUT"
  @module("./constants.js") external blobUrlCleanupDelay: int = "BLOB_URL_CLEANUP_DELAY"
  @module("./constants.js") external progressBarAutoHideDelay: int = "PROGRESS_BAR_AUTO_HIDE_DELAY"
}

module Debug = {
  @module("./utils/Debug.js") @val @scope("Debug")
  external info: (string, string, ~data: 'a=?, unit) => unit = "info"

  @module("./utils/Debug.js") @val @scope("Debug")
  external warn: (string, string, ~data: 'a=?, unit) => unit = "warn"

  @module("./utils/Debug.js") @val @scope("Debug")
  external error: (string, string, ~data: 'a=?, unit) => unit = "error"

  @module("./utils/Debug.js") @val @scope("Debug")
  external debug: (string, string, ~data: 'a=?, unit) => unit = "debug"
}

module Notification = {
  @module("./utils/NotificationSystem.js")
  external notify: (string, string) => unit = "notify"
}

module Viewer = {
  type t
  /* The viewer is attached to window.pannellumViewer */
  @scope("window") @val external instance: Nullable.t<t> = "pannellumViewer"

  @send external getPitch: t => float = "getPitch"
  @send external getYaw: t => float = "getYaw"
  @send external getHfov: t => float = "getHfov"

  @send external setPitch: (t, float, bool) => unit = "setPitch"
  @send external setYaw: (t, float, bool) => unit = "setYaw"
  @send external setHfov: (t, float, bool) => unit = "setHfov"

  @send external mouseEventToCoords: (t, 'event) => array<float> = "mouseEventToCoords"
  @send external setYawWithDuration: (t, float, int) => unit = "setYaw"

  @send external getConfig: t => {..} = "getConfig"
  @send external removeHotSpot: (t, string) => unit = "removeHotSpot"
  @send external addHotSpot: (t, {..}) => unit = "addHotSpot"

  @send external destroy: t => unit = "destroy"
  @send external on: (t, string, 'event => unit) => unit = "on"
  @send external getScene: t => string = "getScene"
  @send external loadScene: (t, string, float, float, float) => unit = "loadScene"
}

module Pannellum = {
  @scope("pannellum") @val external viewer: (string, {..}) => Viewer.t = "viewer"
}

/* DOM Bindings needed for some UI updates */
module Dom = {
  type element
  type event
  @send external preventDefault: event => unit = "preventDefault"
  @send external stopPropagation: event => unit = "stopPropagation"
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

  @scope("document") @val external getElementById: string => Nullable.t<element> = "getElementById"
  @send external querySelector: (element, string) => Nullable.t<element> = "querySelector"

  @set external setInnerHTML: (element, string) => unit = "innerHTML"

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
  @set @scope("style") external setMaxWidth: (element, string) => unit = "maxWidth"
  @set @scope("style") external setPadding: (element, string) => unit = "padding"
  @set @scope("style") external setMargin: (element, string) => unit = "margin"
  @set @scope("style") external setPosition: (element, string) => unit = "position"
  @set @scope("style") external setOverflow: (element, string) => unit = "overflow"
  @set @scope("style") external setDisplay: (element, string) => unit = "display"
  @set @scope("style") external setMaxHeight: (element, string) => unit = "maxHeight"
  @set @scope("style") external setBackgroundColor: (element, string) => unit = "backgroundColor"
  @set @scope("style") external setTransition: (element, string) => unit = "transition"
  @set @scope("style") external setBackgroundImage: (element, string) => unit = "backgroundImage"

  @get external classList: element => {..} = "classList"

  @scope("document") @val external createElement: string => element = "createElement"
  @set external setId: (element, string) => unit = "id"
  @send external setAttribute: (element, string, string) => unit = "setAttribute"
  @send external appendChild: (element, element) => unit = "appendChild"
  @send external addEventListener: (element, string, event => unit) => unit = "addEventListener"
  @send external addEventListenerNoEv: (element, string, unit => unit) => unit = "addEventListener"
  @scope("document") @val external documentBody: element = "body"

  @get external getWidth: element => int = "width"
  @set external setWidth: (element, int) => unit = "width"
  @get external getHeight: element => int = "height"
  @set external setHeight: (element, int) => unit = "height"

  @get external getValue: element => string = "value"
  @send external focus: element => unit = "focus"
  @send external closest: (element, string) => Nullable.t<element> = "closest"
  @send
  external addEventListenerCapture: (element, string, 'a => unit, bool) => unit = "addEventListener"
}

module Canvas = {
  type context2d
  @send external getContext2d: (Dom.element, string, {..}) => context2d = "getContext"

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
  external drawImage: (context2d, Dom.element, float, float, float, float) => unit = "drawImage"
  @send
  external drawImageCoords: (
    context2d,
    Dom.element,
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

  /* Helper for rounded rect if needed, or polyfill */
  @send external roundRect: (context2d, float, float, float, float, float) => unit = "roundRect"
  @send external rect: (context2d, float, float, float, float) => unit = "rect"
}

module Svg = {
  let namespace = "http://www.w3.org/2000/svg"

  @scope("document") @val
  external createElementNS: (string, string) => Dom.element = "createElementNS"
  @send external setAttribute: (Dom.element, string, string) => unit = "setAttribute"
  @send external appendChild: (Dom.element, Dom.element) => unit = "appendChild"

  @set external setOnMouseOver: (Dom.element, unit => unit) => unit = "onmouseover"
  @set external setOnMouseOut: (Dom.element, unit => unit) => unit = "onmouseout"
}

module URL = {
  @scope("URL") @val external createObjectURL: 'a => string = "createObjectURL"
  @scope("URL") @val external revokeObjectURL: string => unit = "revokeObjectURL"
}

module AbortController = {
  type t
  type signal

  @new external newAbortController: unit => t = "AbortController"
  @get external signal: t => signal = "signal"
  @send external abort: t => unit = "abort"
}

module Window = {
  @val external requestAnimationFrame: (unit => unit) => int = "requestAnimationFrame"
  @val external cancelAnimationFrame: int => unit = "cancelAnimationFrame"
  @val external setTimeout: (unit => unit, int) => int = "setTimeout"
  @val external clearTimeout: int => unit = "clearTimeout"
  @val external addEventListener: (string, 'a => unit) => unit = "addEventListener"
  @val external removeEventListener: (string, 'a => unit) => unit = "removeEventListener"
  @scope("navigator") @val external navigatorUserAgent: string = "userAgent"
  @val external window: {..} = "window"
  @val external alert: string => unit = "alert"
  @val external getComputedStyle: Dom.element => {..} = "getComputedStyle"
}

module ModalManager = {
  type button = {
    label: string,
    @as("class") class_: string,
    onClick: unit => unit,
    autoClose: Nullable.t<bool>,
  }

  type options = {
    title: string,
    description: option<string>,
    icon: option<string>,
    iconHtml: option<string>,
    onClose: option<unit => unit>,
    contentHtml: option<string>,
    buttons: array<button>,
  }

  @module("./utils/ModalManager.js") @scope("ModalManager")
  external show: options => unit = "show"

  @module("./utils/ModalManager.js") @scope("ModalManager")
  external close: unit => unit = "close"
}

module Fetch = {
  type response
  type requestInit<'body> = {
    method: string,
    body: 'body,
    headers: Nullable.t<dict<string>>,
  }

  @val external fetch: (string, requestInit<'body>) => Promise.t<response> = "fetch"
  @val external fetchSimple: string => Promise.t<response> = "fetch"

  @send external json: response => Promise.t<'a> = "json"
  @send external arrayBuffer: response => Promise.t<BrowserArrayBuffer.t> = "arrayBuffer"
  @send external blob: response => Promise.t<Blob.t> = "blob"
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
