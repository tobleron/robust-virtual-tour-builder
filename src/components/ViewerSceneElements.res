/* src/components/ViewerSceneElements.res */

@react.component
let make = React.memo(() => {
  <>
    /* Background scene elements (Waypoints, Arrows, etc.)
     These carry z-index: 5000 internally and should be below Builder UI */
    <SnapshotOverlay />
    <HotspotLayer />
  </>
})
