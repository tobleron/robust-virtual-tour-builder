/* src/components/VisualPipeline.res - VisualPipeline Component */

open ReBindings

// Alias to new logic module
module Logic = VisualPipelineLogic

let injectStyles = () => {
  let existing = Dom.getElementById("visual-pipeline-styles")
  switch Nullable.toOption(existing) {
  | Some(_) => ()
  | None =>
    Logger.info(~module_="VisualPipelineStyles", ~message="INJECT_STYLES", ())
    let style = Dom.createElement("style")
    Dom.setId(style, "visual-pipeline-styles")
    Dom.setTextContent(style, Logic.Styles.styles)
    Dom.appendChild(Dom.head, style)
  }
}

let initByElement = (c: Dom.element) => {
  Logger.info(~module_="VisualPipeline", ~message="INIT_BY_ELEMENT_START", ())
  Logger.initialized(~module_="VisualPipeline")
  injectStyles()
  let wrapper = Dom.createElement("div")
  Dom.setClassName(wrapper, "visual-pipeline-wrapper")

  let track = Dom.createElement("div")
  Dom.setClassName(track, "pipeline-track")
  Dom.appendChild(wrapper, track)

  Dom.appendChild(c, wrapper)

  let pipeline: Logic.t = {
    container: c,
    wrapper,
    dragSourceId: ref(Nullable.null),
    thumbCache: Dict.make(),
  }

  pipeline
}

let init = (containerId: string) => {
  let container = Dom.getElementById(containerId)
  switch Nullable.toOption(container) {
  | Some(c) => Some(initByElement(c))
  | None => None
  }
}

@react.component
let make = () => {
  Logger.info(~module_="VisualPipeline", ~message="MAKE_CALLED", ())
  injectStyles()
  let containerRef = React.useRef(Nullable.null)

  let appState = AppContext.useAppState()
  let dispatch = AppContext.useAppDispatch()
  let stateRef = React.useRef(appState)
  React.useEffect1(() => {
    stateRef.current = appState
    None
  }, [appState])
  let getState = () => stateRef.current

  let pipelineRef = React.useRef(None)

  React.useEffect0(() => {
    switch Nullable.toOption(containerRef.current) {
    | Some(c) =>
      let pipeline = initByElement(c)
      pipelineRef.current = Some(pipeline)
    | None => ()
    }

    Some(
      () => {
        pipelineRef.current = None
      },
    )
  })

  React.useEffect1(() => {
    switch pipelineRef.current {
    | Some(p) => Logic.Render.render(p, appState, ~getState, ~dispatch)
    | None => ()
    }
    None
  }, [appState])

  <div
    ref={ReactDOM.Ref.domRef(containerRef)}
    id="visual-pipeline-container"
    role="region"
    ariaLabel="Visual Pipeline"
  />
}
