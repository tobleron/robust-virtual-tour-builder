type hoverPreview = {thumbUrl: string, sceneName: string}

let clearHoverTimer = (hoverTimerRef: React.ref<option<int>>) => {
  switch hoverTimerRef.current {
  | Some(id) => ReBindings.Window.clearTimeout(id)
  | None => ()
  }
  hoverTimerRef.current = None
}

let hideHoverPreview = (
  ~hoverTimerRef: React.ref<option<int>>,
  ~activePreviewUrlRef: React.ref<string>,
  ~setHoverPreview: ((option<hoverPreview> => option<hoverPreview>)) => unit,
) => {
  clearHoverTimer(hoverTimerRef)
  let prevUrl = activePreviewUrlRef.current
  if prevUrl != "" {
    UrlUtils.revokeUrl(prevUrl)
    activePreviewUrlRef.current = ""
  }
  setHoverPreview(_ => None)
}

let showHoverPreview = (
  ~isSystemLocked: bool,
  ~hoverTimerRef: React.ref<option<int>>,
  ~activePreviewUrlRef: React.ref<string>,
  ~setHoverPreview: ((option<hoverPreview> => option<hoverPreview>)) => unit,
  ~sceneOpt: option<Types.scene>,
) => {
  if isSystemLocked {
    hideHoverPreview(~hoverTimerRef, ~activePreviewUrlRef, ~setHoverPreview)
    ()
  } else {
    clearHoverTimer(hoverTimerRef)
    hoverTimerRef.current = Some(ReBindings.Window.setTimeout(() => {
        switch sceneOpt {
        | Some(scene) =>
          switch scene.tinyFile {
          | Some(Blob(_) as tiny) | Some(File(_) as tiny) =>
            let nextUrl = UrlUtils.fileToUrl(tiny)
            if nextUrl == "" {
              hideHoverPreview(~hoverTimerRef, ~activePreviewUrlRef, ~setHoverPreview)
            } else {
              let prevUrl = activePreviewUrlRef.current
              if prevUrl != "" && prevUrl != nextUrl {
                UrlUtils.revokeUrl(prevUrl)
              }
              activePreviewUrlRef.current = nextUrl
              setHoverPreview(_ => Some({thumbUrl: nextUrl, sceneName: scene.name}))
            }
          | _ => hideHoverPreview(~hoverTimerRef, ~activePreviewUrlRef, ~setHoverPreview)
          }
        | None => hideHoverPreview(~hoverTimerRef, ~activePreviewUrlRef, ~setHoverPreview)
        }
      }, 50))
  }
}
