/* src/systems/Viewer/ViewerAdapter.res */
open ReBindings

type t = Viewer.t
type customViewerProps
external asCustom: Viewer.t => customViewerProps = "%identity"
external identity: 'a => 'b = "%identity"
external asAny: 'a => {..} = "%identity"

@get @return(nullable) external getSceneId: customViewerProps => option<string> = "_sceneId"
@set external setSceneId: (customViewerProps, string) => unit = "_sceneId"

@get @return(nullable) external getIsLoaded: customViewerProps => option<bool> = "_isLoaded"
@set external setIsLoaded: (customViewerProps, bool) => unit = "_isLoaded"

let name = "Pannellum"

let initialize = (id, config) => {
  let v = Pannellum.viewer(id, config)

  let lastDown = ref(None)

  let elOpt = Dom.getElementById(id)
  switch Nullable.toOption(elOpt) {
  | Some(element) =>
    Dom.addEventListener(element, "mousedown", e => {
      let clientX = e->Dom.clientX->Int.toFloat
      let clientY = e->Dom.clientY->Int.toFloat
      lastDown := Some((clientX, clientY, Date.now()))
    })

    Dom.addEventListener(element, "mouseup", e => {
      if Viewer.isLoaded(v) {
        let clientX = e->Dom.clientX->Int.toFloat
        let clientY = e->Dom.clientY->Int.toFloat

        switch lastDown.contents {
        | Some((x, y, t)) =>
          let diffX = Math.abs(clientX -. x)
          let diffY = Math.abs(clientY -. y)
          let diffT = Date.now() -. t

          if diffX < 5.0 && diffY < 5.0 && diffT < 500.0 {
            let asEvent: Dom.event => Viewer.mouseEvent = %raw(`function(e) { return { clientX: e.clientX, clientY: e.clientY }; }`)
            let coords = Viewer.mouseEventToCoords(v, asEvent(e))

            let p = Belt.Array.get(coords, 0)->Option.getOr(0.0)
            let y = Belt.Array.get(coords, 1)->Option.getOr(0.0)

            let cp = Viewer.getPitch(v)
            let cy = Viewer.getYaw(v)
            let hf = Viewer.getHfov(v)

            let dispatchEvent: (float, float, float, float, float, float, float) => unit = %raw(`
                    function(p, y, cp, cy, hf, clientX, clientY) {
                      window.document.dispatchEvent(new CustomEvent("viewer-click", {
                        detail: {
                          pitch: p,
                          yaw: y,
                          camPitch: cp,
                          camYaw: cy,
                          camHfov: hf,
                          clientX: clientX,
                          clientY: clientY
                        }
                      }));
                    }
                  `)
            dispatchEvent(p, y, cp, cy, hf, clientX, clientY)

            Logger.debug(~module_="ViewerSystem", ~message="VIEWER_CLICK_DISPATCHED", ())
          }
        | None => ()
        }
      }
      lastDown := None
    })
  | None => Logger.warn(~module_="ViewerSystem", ~message="CONTAINER_NOT_FOUND_FOR_EVENTS", ())
  }

  v
}
let initializeViewer = initialize

let destroy = v => {
  let logDestroyWarning = e => {
    let errorMessage = switch JsExn.message(e) {
    | Some(message) => message
    | None => "Unknown destroy error"
    }
    Logger.warn(
      ~module_="ViewerSystem",
      ~message="PANNELLUM_DESTROY_ERROR_CAUGHT",
      ~data=Some({"error": errorMessage}),
      (),
    )
  }
  let _ = %raw(`
    (v, logDestroyWarning) => {
      if (!v) return;
      try {
        if (v.destroy) {
          v.destroy();
        }
      } catch(e) {
        logDestroyWarning(e);
      }

      try {
        v._sceneId = null;
        v._isLoaded = null;
      } catch(e) {}
    }
  `)(v, logDestroyWarning)
}

let getPitch = v => Viewer.getPitch(v)
let getYaw = v => Viewer.getYaw(v)
let getHfov = v => Viewer.getHfov(v)
let setPitch = (v, p, a) => Viewer.setPitch(v, p, a)
let setYaw = (v, y, a) => Viewer.setYaw(v, y, a)
let setHfov = (v, h, a) => Viewer.setHfov(v, h, a)
let setView = (v, ~pitch=?, ~yaw=?, ~hfov=?, ~animated=false, ()) => {
  pitch->Option.forEach(p => Viewer.setPitch(v, p, animated))
  yaw->Option.forEach(y => Viewer.setYaw(v, y, animated))
  hfov->Option.forEach(h => Viewer.setHfov(v, h, animated))
}
let addHotSpot = (v, config) => Viewer.addHotSpot(v, config)
let removeHotSpot = (v, id) => Viewer.removeHotSpot(v, id)
let getScene = v => Viewer.getScene(v)
let loadScene = (v, sceneId, ~pitch=?, ~yaw=?, ~hfov=?, ()) => {
  let p = pitch->Option.getOr(Viewer.getPitch(v))
  let y = yaw->Option.getOr(Viewer.getYaw(v))
  let h = hfov->Option.getOr(Viewer.getHfov(v))
  Viewer.loadScene(v, sceneId, p, y, h)
}
let addScene = (v, id, config) => Viewer.addScene(v, id, config)
let on = (v, ev, cb) => Viewer.on(v, ev, cb)
let isLoaded = v => Viewer.isLoaded(v)
let setMetaData = (v, key, value) => {
  let c = asCustom(v)
  if key == "sceneId" {
    setSceneId(c, identity(value))
  } else if key == "isLoaded" {
    setIsLoaded(c, identity(value))
  }
}
let getMetaData = (v, key) => {
  let c = asCustom(v)
  if key == "sceneId" {
    Some(identity(getSceneId(c)))
  } else if key == "isLoaded" {
    Some(identity(getIsLoaded(c)))
  } else {
    None
  }
}
