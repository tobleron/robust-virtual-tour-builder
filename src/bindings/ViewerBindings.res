/* src/bindings/ViewerBindings.res */

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
  @send external addScene: (t, string, {..}) => unit = "addScene"
  @send external isLoaded: t => bool = "isLoaded"
}

module Pannellum = {
  @scope("pannellum") @val external viewer: (string, {..}) => Viewer.t = "viewer"
}
