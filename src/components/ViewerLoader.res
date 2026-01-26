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
  UrlUtils.fileToUrl(file)
}

module Loader = {
  let loadStartTime = SceneLoader.loadStartTime

  type customViewerProps = PannellumLifecycle.customViewerProps
  let asCustom = PannellumLifecycle.asCustom

  let initializeViewer = PannellumLifecycle.initializeViewer
  let destroyViewer = PannellumLifecycle.destroyViewer

  let performSwap = loadedScene => {
    SceneTransitionManager.performSwap(loadedScene, loadStartTime.contents)
  }

  let loadNewScene = (prev, target, ~isAnticipatory=false) =>
    SceneLoader.loadNewScene(prev, target, ~isAnticipatory)
}
