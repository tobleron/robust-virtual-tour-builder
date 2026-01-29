open ReBindings

external castToString: 'a => string = "%identity"
external castToBlob: 'a => Blob.t = "%identity"
external castToDict: 'a => dict<'b> = "%identity"
external asDynamic: 'a => {..} = "%identity"

let getComputedOpacity = el => {
  switch Nullable.toOption(el) {
  | Some(e) =>
    let style = Window.getComputedStyle(e)
    Float.parseFloat(Dom.getPropertyValue(style, "opacity"))
  | None => 1.0
  }
}

let getPanoramaUrl = (file: Types.file): string => {
  Types.fileToUrl(file)
}

module Loader = {
  let loadStartTime = Scene.Loader.loadStartTime

  type customViewerProps = HotspotLine.HotspotLineTypes.customViewerProps
  let asCustom = HotspotLine.asCustom

  let initializeViewer = ViewerSystem.Adapter.initialize
  let destroyViewer = ViewerSystem.Adapter.destroy

  let performSwap = loadedScene => {
    Scene.Transition.performSwap(loadedScene, loadStartTime.contents)
  }

  let loadNewScene = (prev, target, ~isAnticipatory=false) =>
    Scene.Loader.loadNewScene(prev, target, ~isAnticipatory)
}
