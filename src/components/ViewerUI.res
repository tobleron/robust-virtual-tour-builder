/* src/components/ViewerUI.res */

@react.component
let make = React.memo(() => {
  <>
    /* Background logic/HUD layers */
    <SnapshotOverlay />
    <HotspotLayer />
    <LockFeedback />

    /* Interactive UI layers */
    <ViewerHUD />
    <HotspotMenuLayer />
  </>
})
