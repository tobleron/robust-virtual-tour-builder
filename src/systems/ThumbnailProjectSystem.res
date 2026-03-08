/* src/systems/ThumbnailProjectSystem.res */
open ReBindings
open AppContext

@react.component
let make = () => {
  let state = useAppState()
  let dispatch = useAppDispatch()
  let (processedIds, setProcessedIds) = React.useState(_ => Belt.Set.String.empty)
  let isProcessing = React.useRef(false)

  // Dependencies on global operations
  let isNavigationBusy = OperationLifecycle.useIsBusy(~type_=Navigation)
  let isSimulationBusy = OperationLifecycle.useIsBusy(~type_=Simulation)

  // New project load may reuse scene IDs; reset dedupe state so thumbnails regenerate deterministically.
  React.useEffect1(() => {
    isProcessing.current = false
    setProcessedIds(_ => Belt.Set.String.empty)
    None
  }, [state.sessionId])

  React.useEffect4(() => {
    let isBusy = isNavigationBusy || isSimulationBusy

    if !isProcessing.current && !isBusy {
      let scenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)

      // Find FIRST scene that needs enhancement
      let sceneToEnhance = scenes->Belt.Array.getBy(s => {
        if Belt.Set.String.has(processedIds, s.id) {
          false
        } else {
          switch s.tinyFile {
          | None => true
          | Some(Url(_)) => true
          | Some(Blob(_)) | Some(File(_)) => false
          }
        }
      })

      switch sceneToEnhance {
      | Some(s) =>
        Logger.debug(
          ~module_="ThumbnailProjectSystem",
          ~message="ENHANCING_SCENE",
          ~data=Some({"id": s.id, "name": s.name}),
          (),
        )
        let sourceFile = SceneLoaderLogic.resolveScenePanoramaFile(s)
        let srcUrl = Types.fileToUrl(sourceFile)

        if srcUrl == "" {
          Logger.warn(
            ~module_="ThumbnailProjectSystem",
            ~message="SKIP_MISSING_SOURCE",
            ~data=Some({"id": s.id, "name": s.name}),
            (),
          )
          setProcessedIds(prev => Belt.Set.String.add(prev, s.id))
        } else {
          isProcessing.current = true
          let opId = OperationLifecycle.start(
            ~type_=ThumbnailGeneration,
            ~scope=Ambient,
            ~phase="Generating",
            ~meta=Logger.castToJson({"id": s.id}),
            (),
          )

          let img = Dom.createElement("img")

          let cleanup = () => {
            // Clear processing lock before state update so next render can continue the queue.
            isProcessing.current = false
            setProcessedIds(prev => Belt.Set.String.add(prev, s.id))
          }

          let onLoad = () => {
            Logger.debug(
              ~module_="ThumbnailProjectSystem",
              ~message="GENERATING_RECTILINEAR",
              ~data=Some({"id": s.id}),
              (),
            )
            ThumbnailGenerator.generateRectilinearThumbnail(img, 256, 144)
            ->Promise.then(blob => {
              Logger.debug(
                ~module_="ThumbnailProjectSystem",
                ~message="PATCHING_THUMBNAIL_SUCCESS",
                ~data=Some({"id": s.id}),
                (),
              )
              OperationLifecycle.complete(opId, ())
              dispatch(PatchSceneThumbnail(s.id, Blob(blob)))
              cleanup()
              Promise.resolve()
            })
            ->Promise.catch(err => {
              let (msg, _) = Logger.getErrorDetails(err)
              Logger.error(
                ~module_="ThumbnailProjectSystem",
                ~message="GENERATION_FAILED",
                ~data=Some({"id": s.id, "error": msg}),
                (),
              )
              OperationLifecycle.fail(opId, msg)
              cleanup()
              Promise.resolve()
            })
            ->ignore
          }

          let onError = () => {
            Logger.error(
              ~module_="ThumbnailProjectSystem",
              ~message="LOAD_ERROR",
              ~data=Some({"id": s.id, "url": srcUrl}),
              (),
            )
            OperationLifecycle.fail(opId, "Image load error")
            cleanup()
          }

          Dom.addEventListenerNoEv(img, "load", onLoad)
          Dom.addEventListenerNoEv(img, "error", onError)
          Dom.setAttribute(img, "crossOrigin", "anonymous")
          Dom.setAttribute(img, "src", srcUrl)
        }
      | None => ()
      }
    }
    None
  }, (state.inventory, processedIds, isNavigationBusy, isSimulationBusy))

  React.null
}
