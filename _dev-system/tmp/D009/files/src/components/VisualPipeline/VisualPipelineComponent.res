@react.component
let make = () => {
  Logger.info(~module_="VisualPipelineComponent", ~message="MAKE_CALLED", ())
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
      let pipeline = VisualPipeline.initByElement(c)
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
    | Some(p) => VisualPipeline.render(p, appState, ~getState, ~dispatch)
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
