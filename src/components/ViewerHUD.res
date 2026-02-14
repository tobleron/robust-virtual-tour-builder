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
      className="absolute bottom-6 right-6 z-[5002] bg-white rounded-xl shadow-xl p-[4px] flex items-center justify-center max-w-[120px] max-h-[60px] border border-black/5 overflow-hidden viewer-logo-masked"
    >
      <img
        src=logoSrc
        alt="Logo"
        className="w-full h-auto object-contain block"
        onError={_ => {
          if extIndex < Array.length(extensions) - 1 {
            setExtIndex(prev => prev + 1)
          }
        }}
      />
    </div>
  </>
})
