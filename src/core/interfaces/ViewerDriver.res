/* src/core/interfaces/ViewerDriver.res */

module type Driver = {
  type t
  let name: string

  let initialize: (string, 'a) => t
  let destroy: t => unit

  // View Control
  let getPitch: t => float
  let getYaw: t => float
  let getHfov: t => float

  let setPitch: (t, float, bool) => unit
  let setYaw: (t, float, bool) => unit
  let setHfov: (t, float, bool) => unit
  let setView: (t, ~pitch: float=?, ~yaw: float=?, ~hfov: float=?, ~animated: bool=?, unit) => unit

  // Hotspot Management
  let addHotSpot: (t, 'a) => unit
  let removeHotSpot: (t, string) => unit

  // Scene Logic
  let getScene: t => string
  let loadScene: (t, string, ~pitch: float=?, ~yaw: float=?, ~hfov: float=?, unit) => unit

  // Event Handling
  let on: (t, string, 'a => unit) => unit

  // Meta
  let isLoaded: t => bool
  let setMetaData: (t, string, 'a) => unit
  let getMetaData: (t, string) => option<'a>
}
