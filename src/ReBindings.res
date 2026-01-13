/* src/ReBindings.res */

/* 
 * Centralized bindings for JavaScript dependencies needed by ReScript systems.
 */

module PubSub = {
  type unsubscribe = unit => unit
  
  @module("./utils/PubSub.js") @scope("PubSub")
  external subscribe: (string, 'a => unit) => unsubscribe = "subscribe"
  
  @module("./utils/PubSub.js") @scope("PubSub")
  external publish: (string, 'a) => unit = "publish"
  
  /* Events */
  @module("./utils/PubSub.js") @scope("EVENTS") external navStart: string = "NAV_START"
  @module("./utils/PubSub.js") @scope("EVENTS") external navProgress: string = "NAV_PROGRESS"
  @module("./utils/PubSub.js") @scope("EVENTS") external navCompleted: string = "NAV_COMPLETED"
  @module("./utils/PubSub.js") @scope("EVENTS") external navCancelled: string = "NAV_CANCELLED"
  @module("./utils/PubSub.js") @scope("EVENTS") external sceneArrived: string = "SCENE_ARRIVED"
  @module("./utils/PubSub.js") @scope("EVENTS") external clearSimUi: string = "CLEAR_SIM_UI"
}

module Constants = {
  @module("./constants.js") external panningVelocity: float = "PANNING_VELOCITY"
  @module("./constants.js") external panningMinDuration: float = "PANNING_MIN_DURATION"
  @module("./constants.js") external panningMaxDuration: float = "PANNING_MAX_DURATION"
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
  
  @send external mouseEventToCoords: (t, 'event) => array<float> = "mouseEventToCoords"
  @send external setYawWithDuration: (t, float, int) => unit = "setYaw"
  
  @send external getConfig: t => {..} = "getConfig"
  @send external removeHotSpot: (t, string) => unit = "removeHotSpot"
  @send external addHotSpot: (t, {..}) => unit = "addHotSpot"
}

/* DOM Bindings needed for some UI updates */
module Dom = {
  type element
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
  @scope("document") @val external querySelector: (element, string) => Nullable.t<element> = "querySelector"
  
  @set external setInnerHTML: (element, string) => unit = "innerHTML"
  
  @send external getBoundingClientRect: element => rect = "getBoundingClientRect"
  
  @scope("classList") @send external add: (element, string) => unit = "add"
  @scope("classList") @send external remove: (element, string) => unit = "remove"
  @get external classList: element => {..} = "classList" /* rough binding */
  
  @set @scope("style") external setCursor: (element, string) => unit = "cursor"
  @set @scope("style") external setPointerEvents: (element, string) => unit = "pointerEvents"
}

module Svg = {
  let namespace = "http://www.w3.org/2000/svg"
  
  @scope("document") @val external createElementNS: (string, string) => Dom.element = "createElementNS"
  @send external setAttribute: (Dom.element, string, string) => unit = "setAttribute"
  @send external appendChild: (Dom.element, Dom.element) => unit = "appendChild"
  
  @set external setOnMouseOver: (Dom.element, unit => unit) => unit = "onmouseover"
  @set external setOnMouseOut: (Dom.element, unit => unit) => unit = "onmouseout"



}

module URL = {
  @scope("URL") @val external createObjectURL: 'a => string = "createObjectURL"
  @scope("URL") @val external revokeObjectURL: string => unit = "revokeObjectURL"
}
