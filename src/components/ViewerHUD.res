/* src/components/ViewerHUD.res */

external unsafeCastToFile: 'a => ReBindings.File.t = "%identity"

@react.component
let make = React.memo(() => {
  let sceneSlice = AppContext.useSceneSlice()
  let uiSlice = AppContext.useUiSlice()
  let simSlice = AppContext.useSimSlice()
  let state = AppContext.useAppState()

  let logoSrc = switch uiSlice.logo {
  | Some(f) => Types.fileToUrl(f)
  | None => Constants.defaultLogoPath
  }

  let simActive = simSlice.simulation.status == Running
  let scenesLoaded = Belt.Array.length(sceneSlice.scenes) > 0
  let marketingText = MarketingText.compose(
    ~comment=state.marketingComment,
    ~phone1=state.marketingPhone1,
    ~phone2=state.marketingPhone2,
    ~forRent=state.marketingForRent,
    ~forSale=state.marketingForSale,
  )

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

        {if marketingText.full != "" {
          <div
            id="viewer-marketing-banner"
            className="absolute left-1/2 -translate-x-1/2 z-[5003] pointer-events-none flex items-center justify-center text-center"
          >
            {if marketingText.showRent {
              <span
                className="viewer-marketing-chip viewer-marketing-chip-rent viewer-marketing-chip-left viewer-marketing-chip-left-only"
              >
                {React.string("RENT")}
              </span>
            } else {
              React.null
            }}

            {if marketingText.showSale {
              <span
                className={`viewer-marketing-chip viewer-marketing-chip-sale ${!marketingText.showRent
                    ? "viewer-marketing-chip-left"
                    : ""}`}
              >
                {React.string("SALE")}
              </span>
            } else {
              React.null
            }}

            {if marketingText.body != "" {
              <span
                className={`viewer-marketing-text-wrap ${!marketingText.showRent &&
                  !marketingText.showSale
                    ? "viewer-marketing-text-wrap-left"
                    : ""}`}
              >
                <span className="viewer-marketing-banner-text">
                  {React.string(marketingText.body)}
                </span>
              </span>
            } else {
              React.null
            }}
          </div>
        } else {
          React.null
        }}

        /* Permanent Branding with Perfect Masking & Editable Support */
        <div
          id="viewer-logo"
          className="absolute bottom-5 right-6 z-[5002] w-[126px] h-[66px] viewer-logo-masked rounded-lg shadow-xl overflow-hidden transition-all p-[6px] pointer-events-none"
        >
          <div className="w-full h-full relative pointer-events-none">
            <img
              src=logoSrc
              alt="Logo"
              className="w-full h-full object-contain block pointer-events-none"
              onError={_ => ()}
            />
          </div>
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
  </>
})
