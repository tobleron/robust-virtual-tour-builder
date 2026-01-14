@react.component
let make = () => {
  let sidebarRoot = ReactDOM.querySelector("#sidebar")
  let viewerUiRoot = ReactDOM.querySelector("#viewer-ui-layer")

  <AppContext.Provider>
    <NotificationContext />
    <ModalContext />
    <NavigationController />
    <ViewerManager />
    {switch sidebarRoot {
    | Some(root) => ReactDOM.createPortal(<Sidebar />, root)
    | None => React.null
    }}
    {switch viewerUiRoot {
    | Some(root) => ReactDOM.createPortal(<ViewerUI />, root)
    | None => React.null
    }}
  </AppContext.Provider>
}
