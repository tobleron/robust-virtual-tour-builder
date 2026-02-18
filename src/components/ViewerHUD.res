/* src/components/ViewerHUD.res */

external unsafeCastToFile: 'a => ReBindings.File.t = "%identity"

@react.component
let make = React.memo(() => {
  let sceneSlice = AppContext.useSceneSlice()
  let uiSlice = AppContext.useUiSlice()
  let simSlice = AppContext.useSimSlice()

  let dispatch = AppContext.useAppDispatch()
  let fileInputRef = React.useRef(Nullable.null)

  let extensions = ["png", "jpg", "jpeg", "webp"]
  let (extIndex, setExtIndex) = React.useState(_ => 0)

  let logoSrc = switch uiSlice.logo {
  | Some(f) => Types.fileToUrl(f)
  | None => `images/logo.${Belt.Array.get(extensions, extIndex)->Option.getOr("png")}`
  }

  let handleLogoClick = _ => {
    switch fileInputRef.current->Nullable.toOption {
    | Some(input) => {
        let _ = %raw("(input) => input.click()")(input)
      }
    | None => ()
    }
  }

  let handleFileChange = e => {
    let files = ReactEvent.Form.target(e)["files"]
    if Belt.Array.length(files) > 0 {
      let file = files[0]
      dispatch(SetLogo(Some(Types.File(file->unsafeCastToFile))))
    }
  }

  let simActive = simSlice.simulation.status == Running
  let scenesLoaded = Belt.Array.length(sceneSlice.scenes) > 0

  <>
    /* Primary Action Bar */
    <UtilityBar
      scenesLoaded
      isLinking={uiSlice.isLinking}
      simActive
      currentJourneyId={simSlice.currentJourneyId}
    />

    /* Information Overlays */
    <PersistentLabel activeIndex={sceneSlice.activeIndex} scenes={sceneSlice.scenes} />
    <QualityIndicator activeIndex={sceneSlice.activeIndex} scenes={sceneSlice.scenes} />

    {if uiSlice.isLinking {
      <div
        className="absolute top-[64px] left-1/2 -translate-x-1/2 z-[5003] pointer-events-none flex flex-col items-center gap-1"
      >
        <span className="linking-hint-text">
          {React.string("Click ENTER to save hotspot, ESC to cancel")}
        </span>
      </div>
    } else {
      React.null
    }}

    <FloorNavigation
      scenesLoaded activeIndex={sceneSlice.activeIndex} isLinking={uiSlice.isLinking} simActive
    />

    /* Return Prompt Banner */
    <ReturnPrompt incomingLink={simSlice.incomingLink} scenes={sceneSlice.scenes} />

    <NotificationCenter />

    /* Permanent Branding with Perfect Masking & Editable Support */
    <div
      id="viewer-logo"
      className="absolute bottom-6 right-6 z-[5002] w-[126px] h-[66px] viewer-logo-masked rounded-lg shadow-xl overflow-hidden cursor-pointer transition-all active:scale-95 group pointer-events-auto p-[6px]"
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
        accept="image/*"
      />
    </div>
  </>
})
