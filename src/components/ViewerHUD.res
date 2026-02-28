/* src/components/ViewerHUD.res */

external unsafeCastToFile: 'a => ReBindings.File.t = "%identity"

@react.component
let make = React.memo(() => {
  let sceneSlice = AppContext.useSceneSlice()
  let uiSlice = AppContext.useUiSlice()
  let simSlice = AppContext.useSimSlice()
  let canUpload = Capability.useCapability(CanUpload)

  let dispatch = AppContext.useAppDispatch()
  let fileInputRef = React.useRef(Nullable.null)

  let extensions = ["png", "jpg", "jpeg", "webp"]
  let (extIndex, setExtIndex) = React.useState(_ => 0)

  let logoSrc = switch uiSlice.logo {
  | Some(f) => Types.fileToUrl(f)
  | None => `images/logo.${Belt.Array.get(extensions, extIndex)->Option.getOr("png")}`
  }

  let handleLogoClick = _ => {
    if canUpload {
      switch fileInputRef.current->Nullable.toOption {
      | Some(input) => {
          let _ = %raw("(input) => input.click()")(input)
        }
      | None => ()
      }
    } else {
      Logger.debug(~module_="ViewerHUD", ~message="LOGO_UPLOAD_REJECTED_LOCK_HELD", ())
    }
  }

  let handleFileChange = e => {
    let files = ReactEvent.Form.target(e)["files"]
    if Belt.Array.length(files) > 0 {
      let file = files[0]->unsafeCastToFile
      ImageOptimizer.compressToWebPConstrained(
        file,
        ~quality=Constants.Media.logoWebpQuality,
        ~maxWidth=Constants.Media.logoMaxWidth,
        ~maxHeight=Constants.Media.logoMaxHeight,
      )
      ->Promise.then(result => {
        switch result {
        | Ok(blob) =>
          let optimized = BrowserBindings.File.newFile(
            [blob],
            Constants.Media.logoOutputFilename,
            {"type": "image/webp"},
          )
          dispatch(SetLogo(Some(Types.File(optimized))))
        | Error(msg) =>
          Logger.warn(
            ~module_="ViewerHUD",
            ~message="LOGO_OPTIMIZATION_FAILED_FALLBACK_ORIGINAL",
            ~data=Some({"error": msg}),
            (),
          )
          dispatch(SetLogo(Some(Types.File(file))))
        }
        Promise.resolve()
      })
      ->Promise.catch(exn => {
        let (msg, _) = Logger.getErrorDetails(exn)
        Logger.warn(
          ~module_="ViewerHUD",
          ~message="LOGO_OPTIMIZATION_THROW_FALLBACK_ORIGINAL",
          ~data=Some({"error": msg}),
          (),
        )
        dispatch(SetLogo(Some(Types.File(file))))
        Promise.resolve()
      })
      ->ignore
    }
  }

  let simActive = simSlice.simulation.status == Running
  let scenesLoaded = Belt.Array.length(sceneSlice.scenes) > 0

  <>
    /* Interaction Shield for Teaser/Automation */
    {if uiSlice.isTeasing {
      <div
        className="absolute inset-0 z-[4500] cursor-wait"
        onClick={e => JsxEvent.Mouse.stopPropagation(e)}
        onMouseDown={e => JsxEvent.Mouse.stopPropagation(e)}
      >
        /* REC Indicator (Top Left) */
        <div
          className="absolute top-6 left-6 flex items-center gap-2 px-3 py-1.5 bg-black/40 backdrop-blur-sm rounded-full border border-white/10 select-none"
        >
          <div
            className="w-2.5 h-2.5 bg-red-600 rounded-full animate-pulse-record shadow-[0_0_8px_rgba(220,38,38,0.8)]"
          />
          <span className="text-white text-[11px] font-bold tracking-widest uppercase">
            {React.string("REC")}
          </span>
        </div>
      </div>
    } else {
      React.null
    }}

    /* Primary Action Bar */
    <UtilityBar
      scenesLoaded
      isLinking={uiSlice.isLinking}
      simActive
      currentJourneyId={simSlice.currentJourneyId}
      isTeasing={uiSlice.isTeasing}
    />

    {if !uiSlice.isLinking && !uiSlice.isTeasing {
      <>
        /* Information Overlays */
        <PersistentLabel activeIndex={sceneSlice.activeIndex} scenes={sceneSlice.scenes} />
        <QualityIndicator activeIndex={sceneSlice.activeIndex} scenes={sceneSlice.scenes} />

        <FloorNavigation
          scenesLoaded activeIndex={sceneSlice.activeIndex} isLinking={uiSlice.isLinking} simActive
        />

        /* Return Prompt Banner */
        <ReturnPrompt incomingLink={simSlice.incomingLink} scenes={sceneSlice.scenes} />

        /* Permanent Branding with Perfect Masking & Editable Support */
        <div
          id="viewer-logo"
          className={"absolute bottom-5 right-6 z-[5002] w-[126px] h-[66px] viewer-logo-masked rounded-lg shadow-xl overflow-hidden transition-all p-[6px] " ++ if (
            canUpload
          ) {
            "cursor-pointer active:scale-95 group pointer-events-auto"
          } else {
            "opacity-70 cursor-not-allowed pointer-events-none"
          }}
          onClick=handleLogoClick
          title="Click to change logo"
        >
          <div className="w-full h-full relative group">
            <img
              src=logoSrc
              alt="Logo"
              className="w-full h-full object-contain block"
              onError={_ => {
                if uiSlice.logo == None && extIndex < Array.length(extensions) - 1 {
                  setExtIndex(prev => prev + 1)
                }
              }}
            />
            <div
              className="absolute inset-0 bg-black/40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity"
            >
              <LucideIcons.Upload size=20 className="text-white" />
            </div>
          </div>
          <input
            type_="file"
            ref={fileInputRef->ReactDOM.Ref.domRef}
            onChange=handleFileChange
            className="hidden"
            id="viewer-logo-upload"
            accept="image/*"
          />
        </div>
      </>
    } else if !uiSlice.isLinking {
      React.null
    } else {
      /* Top Yellow Linking Hint Bar */
      <div
        className="absolute top-0 left-1/2 -translate-x-1/2 z-[5003] pointer-events-none w-fit bg-[var(--accent)] text-black py-1 px-8 shadow-md rounded-b-lg flex items-center justify-center text-center border-x border-b border-black/10"
      >
        <span className="font-bold text-[13px] tracking-wide whitespace-nowrap">
          {React.string("Click to set waypoint, then ENTER to save hotspot button. ESC to cancel")}
        </span>
      </div>
    }}

    <NotificationCenter />
  </>
})
