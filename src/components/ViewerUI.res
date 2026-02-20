/* src/components/ViewerUI.res */

@react.component
let make = React.memo(() => {
  <>
    /* Background logic controllers */
    <LockFeedback />

    /* Interactive UI layers */
    <ViewerHUD />
    <HotspotMenuLayer />
  </>
})
