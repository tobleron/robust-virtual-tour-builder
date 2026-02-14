/* src/components/ViewerHUD.res */

@react.component
let make = React.memo(() => {
  let sceneSlice = AppContext.useSceneSlice()
  let uiSlice = AppContext.useUiSlice()
  let simSlice = AppContext.useSimSlice()

  let extensions = ["png", "jpg", "jpeg", "webp"]
  let (extIndex, setExtIndex) = React.useState(_ => 0)
  let logoSrc = `images/logo.${Belt.Array.get(extensions, extIndex)->Option.getOr("png")}`

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

    <FloorNavigation
      scenesLoaded activeIndex={sceneSlice.activeIndex} isLinking={uiSlice.isLinking} simActive
    />

    /* Return Prompt Banner */
    <ReturnPrompt incomingLink={simSlice.incomingLink} scenes={sceneSlice.scenes} />

    <NotificationCenter />

    /* Permanent Branding with Format Fallback */
    <div
      id="viewer-logo"
      className="absolute bottom-6 right-6 z-[5002] flex items-center justify-center max-w-[126px] max-h-[66px] overflow-hidden viewer-logo-masked pointer-events-none p-[3px] rounded-lg bg-white/10 backdrop-blur-md border border-white/20 shadow-lg"
    >
      <img
        src=logoSrc
        alt="Logo"
        className="w-full h-auto object-contain block rounded-lg"
        onError={_ => {
          if extIndex < Array.length(extensions) - 1 {
            setExtIndex(prev => prev + 1)
          }
        }}
      />
    </div>
  </>
})
