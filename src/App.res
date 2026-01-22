module Inner = {
  @react.component
  let make = () => {
    let state = AppContext.useAppState()

    <>
      // Sidebar Region
      <div id="sidebar" role="complementary" ariaLabel="Editor Sidebar">
        <Sidebar />
      </div>

      // Main Content Region
      <main id="viewer-container" role="main">
        <div id="viewer-stage">
          // Panorama Layers
          <div
            id="panorama-a"
            className="panorama-layer active"
            role="img"
            ariaLabel="Primary Panorama Viewer"
          />
          <div
            id="panorama-b"
            className="panorama-layer"
            role="img"
            ariaLabel="Secondary Panorama Viewer"
          />

          <div id="cursor-guide" ariaHidden=true />

          // Viewer UI Layer
          <div id="viewer-ui-layer">
            <ViewerUI />
          </div>
        </div>

        <div id="visual-pipeline-container" role="region" ariaLabel="Visual Pipeline" />

        {if Belt.Array.length(state.scenes) == 0 {
          <div id="placeholder-text" className="viewer-placeholder" ariaLive=#polite>
            <h3> {React.string("Ready to build.")} </h3>
          </div>
        } else {
          React.null
        }}
      </main>

      // Modal & Notification Containers
      <div id="modal-container">
        <ModalContext />
      </div>
      <div id="notification-container">
        <NotificationContext />
      </div>

      // Logic Controllers
      <NavigationController />
      <ViewerManager />
      <SimulationDriver />
    </>
  }
}

@react.component
let make = () => {
  <AppContext.Provider>
    <RemaxErrorBoundary>
      <Shadcn.Tooltip.Provider>
        <Inner />
      </Shadcn.Tooltip.Provider>
    </RemaxErrorBoundary>
  </AppContext.Provider>
}
