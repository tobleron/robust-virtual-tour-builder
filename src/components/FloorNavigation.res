/* src/components/FloorNavigation.res */
open Types

@react.component
let make = React.memo((~scenesLoaded, ~activeIndex, ~isLinking, ~simActive=false) => {
  let dispatch = AppContext.useAppDispatch()
  let sceneSlice = AppContext.useSceneSlice()

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
    "absolute bottom-6 left-5 z-[5002] flex flex-col-reverse gap-2 items-center transition-all duration-500" ++ if (
      !scenesLoaded && !simActive
    ) {
      " grayscale opacity-60 pointer-events-none"
    } else {
      ""
    }

  let renderFloorButtons = (~keySuffix: string) =>
    Constants.Scene.floorLevels
    ->Belt.Array.map(f => {
      let isSelected = (scenesLoaded || simActive) && f.id == currentFloor
      let buttonStateClass = if isSelected {
        "state-active border-2 border-[#ea580c] bg-[#ea580c] text-white hover:bg-[#ea580c] hover:text-white"
      } else {
        "state-idle border border-white/20 hover:border-[#ea580c] bg-[#0e2d52]/80 text-white hover:bg-[#0e2d52] hover:text-white"
      }

      <Tooltip key={f.id ++ keySuffix} content={f.label} alignment=#Right disabled={isLinking}>
        <Shadcn.Button
          size="icon"
          variant="ghost"
          className={"w-8 h-8 min-w-8 min-h-8 rounded-full text-[15px] font-medium opacity-100 transition-all " ++
          buttonStateClass}
          onClick={e => handleFloorClick(f.id, f.label, e)}
          disabled={isLinking}
        >
          <span className="floor-combo">
            <span className="floor-main"> {React.string(f.short)} </span>
            {switch f.suffix {
            | Some(s) if s != "" => <sup className="floor-suffix"> {React.string(s)} </sup>
            | _ => React.null
            }}
          </span>
        </Shadcn.Button>
      </Tooltip>
    })
    ->React.array

  <>
    <div id="viewer-floor-nav" className={floorNavClass}>
      {renderFloorButtons(~keySuffix="-primary")}
    </div>
  </>
})
