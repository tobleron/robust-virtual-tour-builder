/* src/components/FloorNavigation.res */
open Types

@react.component
let make = React.memo((~scenesLoaded, ~activeIndex, ~isLinking, ~simActive=false) => {
  let dispatch = AppContext.useAppDispatch()
  let sceneSlice = AppContext.useSceneSlice()
  let isSystemLocked = Capability.useIsSystemLocked()
  let canMutateProject = Capability.useCapability(CanMutateProject)

  let currentFloor = if activeIndex >= 0 {
    switch Belt.Array.get(sceneSlice.scenes, activeIndex) {
    | Some(s) =>
      if s.floor == "" {
        "ground"
      } else {
        s.floor
      }
    | None => ""
    }
  } else {
    ""
  }

  let handleFloorClick = (fid, label, e) => {
    JsxEvent.Mouse.stopPropagation(e)
    if activeIndex >= 0 {
      dispatch(Actions.UpdateSceneMetadata(activeIndex, Logger.castToJson({"floor": fid})))
      NotificationManager.dispatch({
        id: "",
        importance: Success,
        context: Operation("floor_navigation"),
        message: "Floor: " ++ label,
        details: None,
        action: None,
        duration: NotificationTypes.defaultTimeoutMs(Success),
        dismissible: true,
        createdAt: Date.now(),
      })
    }
  }

  let floorNavClass =
    "viewer-rail viewer-rail--floor" ++ if (
      (!scenesLoaded && !simActive) || isSystemLocked || !canMutateProject
    ) {
      " is-inactive"
    } else {
      ""
    }

  let renderFloorButtons = (~keySuffix: string) =>
    Constants.Scene.floorLevels
    ->Belt.Array.map(f => {
      let isSelected = (scenesLoaded || simActive) && f.id == currentFloor
      let buttonStateClass = if isSelected {
        "viewer-control--active"
      } else {
        "viewer-control--idle"
      }

      <Tooltip key={f.id ++ keySuffix} content={f.label} alignment=#Right disabled={isLinking}>
        <span id={"floor-nav-button-" ++ f.id} className="inline-block">
          <Shadcn.Button
            size="icon"
            variant="ghost"
            className={"viewer-control viewer-control--orb viewer-control--floor " ++
            buttonStateClass}
            onClick={e => handleFloorClick(f.id, f.label, e)}
            disabled={isLinking || isSystemLocked || !canMutateProject}
          >
            <span className="floor-combo">
              <span className="floor-main"> {React.string(f.short)} </span>
              {switch f.suffix {
              | Some(s) if s != "" => <sup className="floor-suffix"> {React.string(s)} </sup>
              | _ => React.null
              }}
            </span>
          </Shadcn.Button>
        </span>
      </Tooltip>
    })
    ->React.array

  <>
    <div id="viewer-floor-nav" className={floorNavClass}>
      {renderFloorButtons(~keySuffix="-primary")}
    </div>
  </>
})
