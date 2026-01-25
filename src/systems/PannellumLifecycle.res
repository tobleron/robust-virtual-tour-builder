open ReBindings

type customViewerProps = {
  @as("_sceneId") mutable sceneId: string,
  @as("_isLoaded") mutable isLoaded: bool,
}

external asCustom: ReBindings.Viewer.t => customViewerProps = "%identity"

let initializeViewer = (containerId: string, config: {..}) => {
  Pannellum.viewer(containerId, config)
}

let destroyViewer = (v: ReBindings.Viewer.t) => {
  try {
    Viewer.destroy(v)
  } catch {
  | _ => ()
  }
}
