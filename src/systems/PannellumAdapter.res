/* src/systems/PannellumAdapter.res */

open ReBindings

type t = Viewer.t

type customViewerProps = {
  @as("_sceneId") mutable sceneId: string,
  @as("_isLoaded") mutable isLoaded: bool,
}

external asCustom: Viewer.t => customViewerProps = "%identity"

let name = "Pannellum"

let initialize = (id, config) => {
  Pannellum.viewer(id, config)
}

let destroy = v => {
  try {
    Viewer.destroy(v)
  } catch {
  | _ => ()
  }
}

let getPitch = v => Viewer.getPitch(v)
let getYaw = v => Viewer.getYaw(v)
let getHfov = v => Viewer.getHfov(v)

let setPitch = (v, p, a) => Viewer.setPitch(v, p, a)
let setYaw = (v, y, a) => Viewer.setYaw(v, y, a)
let setHfov = (v, h, a) => Viewer.setHfov(v, h, a)

let setView = (v, ~pitch=?, ~yaw=?, ~hfov=?, ~animated=false, ()) => {
  switch pitch {
  | Some(p) => Viewer.setPitch(v, p, animated)
  | None => ()
  }
  switch yaw {
  | Some(y) => Viewer.setYaw(v, y, animated)
  | None => ()
  }
  switch hfov {
  | Some(h) => Viewer.setHfov(v, h, animated)
  | None => ()
  }
}

let addHotSpot = (v, config) => Viewer.addHotSpot(v, config)
let removeHotSpot = (v, id) => Viewer.removeHotSpot(v, id)

let getScene = v => Viewer.getScene(v)

let loadScene = (v, sceneId, ~pitch=?, ~yaw=?, ~hfov=?, ()) => {
  let p = pitch->Belt.Option.getWithDefault(Viewer.getPitch(v))
  let y = yaw->Belt.Option.getWithDefault(Viewer.getYaw(v))
  let h = hfov->Belt.Option.getWithDefault(Viewer.getHfov(v))
  Viewer.loadScene(v, sceneId, p, y, h)
}

let on = (v, ev, cb) => Viewer.on(v, ev, cb)

let isLoaded = v => asCustom(v).isLoaded

let setMetaData = (v, key, value) => {
  let custom = asCustom(v)
  if key == "sceneId" {
    custom.sceneId = Obj.magic(value)
  } else if key == "isLoaded" {
    custom.isLoaded = Obj.magic(value)
  }
}

let getMetaData = (v, key) => {
  let custom = asCustom(v)
  if key == "sceneId" {
    Some(Obj.magic(custom.sceneId))
  } else if key == "isLoaded" {
    Some(Obj.magic(custom.isLoaded))
  } else {
    None
  }
}
