/* src/components/VisualPipeline/VisualPipelineMain.res */

open ReBindings
open VisualPipelineTypes
open VisualPipelineStyles
open VisualPipelineRender

let init = (containerId: string) => {
  let container = Dom.getElementById(containerId)
  switch Nullable.toOption(container) {
  | Some(c) =>
    Logger.initialized(~module_="VisualPipeline")
    injectStyles()
    let wrapper = Dom.createElement("div")
    Dom.setClassName(wrapper, "visual-pipeline-wrapper")

    let track = Dom.createElement("div")
    Dom.setClassName(track, "pipeline-track")
    Dom.appendChild(wrapper, track)

    Dom.appendChild(c, wrapper)

    let pipeline = {
      container: c,
      wrapper,
      dragSourceId: Nullable.null,
      thumbCache: Dict.make(),
    }

    let _ = GlobalStateBridge.subscribe(state => render(pipeline, state))
    render(pipeline, GlobalStateBridge.getState())
    Some(pipeline)
  | None => None
  }
}
