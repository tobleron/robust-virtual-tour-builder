@react.component
let make = () => {
  Logger.info(~module_="VisualPipelineComponent", ~message="MAKE_CALLED", ())
  let containerRef = React.useRef(Nullable.null)

  React.useEffect0(() => {
    let unsubRef = ref(None)

    switch Nullable.toOption(containerRef.current) {
    | Some(c) =>
      let (_, unsubscribe) = VisualPipeline.initByElement(c)
      unsubRef := Some(unsubscribe)
    | None => ()
    }

    Some(
      () => {
        switch unsubRef.contents {
        | Some(u) => u()
        | None => ()
        }
      },
    )
  })

  <div
    ref={ReactDOM.Ref.domRef(containerRef)}
    id="visual-pipeline-container"
    role="region"
    ariaLabel="Visual Pipeline"
  />
}
