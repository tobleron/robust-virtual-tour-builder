/* src/systems/ThumbnailProjectSystem.res */
open ReBindings
open AppContext

@react.component
let make = () => {
  let state = useAppState()
  let dispatch = useAppDispatch()
  let (processedIds, setProcessedIds) = React.useState(_ => Belt.Set.String.empty)
  let isProcessing = React.useRef(false)

  React.useEffect2(() => {
    if !isProcessing.current {
      let scenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)

      // Find FIRST scene that needs enhancement:
      // 1. Must NOT have been processed in this session
      // 2. Must either have NO thumbnail OR a server-side URL thumbnail (equirectangular)
      let sceneToEnhance = scenes->Belt.Array.getBy(s => {
        if Belt.Set.String.has(processedIds, s.id) {
          false
        } else {
          switch s.tinyFile {
          | None => true // Missing thumbnail entirely
          | Some(Url(_)) => true // Legacy equirectangular URL from server
          | Some(Blob(_)) | Some(File(_)) => false // Already high-quality local cache
          }
        }
      })

      switch sceneToEnhance {
      | Some(s) =>
        Logger.info(
          ~module_="ThumbnailProjectSystem",
          ~message="ENHANCING_SCENE",
          ~data=Some({"id": s.id, "name": s.name}),
          (),
        )
        isProcessing.current = true
        setProcessedIds(prev => Belt.Set.String.add(prev, s.id))

        let srcUrl = Types.fileToUrl(s.file)
        let img = Dom.createElement("img")

        let cleanup = () => {
          isProcessing.current = false
        }

        let onLoad = () => {
          Logger.info(
            ~module_="ThumbnailProjectSystem",
            ~message="GENERATING_RECTILINEAR",
            ~data=Some({"id": s.id}),
            (),
          )
          ThumbnailGenerator.generateRectilinearThumbnail(img, 120, 80)
          ->Promise.then(blob => {
            Logger.info(
              ~module_="ThumbnailProjectSystem",
              ~message="PATCHING_THUMBNAIL",
              ~data=Some({"id": s.id}),
              (),
            )
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
            cleanup()
            Promise.resolve()
          })
          ->ignore
        }

        let onError = () => {
          Logger.error(
            ~module_="ThumbnailProjectSystem",
            ~message="LOAD_ERROR",
            ~data=Some({"id": s.id}),
            (),
          )
          cleanup()
        }

        Dom.addEventListenerNoEv(img, "load", onLoad)
        Dom.addEventListenerNoEv(img, "error", onError)
        // crossOrigin MUST be set BEFORE src to avoid tainting the canvas
        Dom.setAttribute(img, "crossOrigin", "anonymous")
        Dom.setAttribute(img, "src", srcUrl)
      | None => ()
      }
    }
    None
  }, (state.inventory, processedIds))

  React.null
}
