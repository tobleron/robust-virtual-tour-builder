/* src/components/ViewerUI.res */

@react.component
let make = React.memo(() => {
  <>
    /* Background logic/HUD layers */
    <SnapshotOverlay />
    <HotspotLayer />

    /* Interactive UI layers */
    <ViewerHUD />
    <HotspotMenuLayer />

    /* Global Notification layer */
    <NotificationLayer />
  </>
})
