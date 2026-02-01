/* src/components/FloorNavigation.res */
open Types
open EventBus

@react.component
let make = React.memo((~scenesLoaded, ~activeIndex, ~isLinking) => {
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
      EventBus.dispatch(ShowNotification("Floor: " ++ label, #Success, None))
    }
  }

  let floorNavClass =
    "absolute bottom-6 left-5 z-[5002] flex flex-col-reverse gap-2 items-center transition-all duration-500" ++ if (
      !scenesLoaded
    ) {
      " grayscale opacity-60 pointer-events-none"
    } else {
      ""
    }

  <div id="viewer-floor-nav" className={floorNavClass}>
    {Constants.Scene.floorLevels
    ->Belt.Array.map(f => {
      let isSelected = scenesLoaded && f.id == currentFloor

      <Tooltip key={f.id} content={f.label} alignment=#Right disabled={isLinking}>
        <Shadcn.Button
          size="icon"
          variant="ghost"
          className={"w-8 h-8 min-w-8 min-h-8 rounded-full text-[15px] font-medium opacity-100 transition-all " ++ if (
            isSelected
          ) {
            "border-2 border-[#ea580c] bg-[#ea580c] text-white hover:bg-[#ea580c] hover:text-white"
          } else {
            "border border-white/20 hover:border-[#ea580c] bg-[#0e2d52]/80 text-white hover:bg-[#0e2d52] hover:text-white"
          }}
          onClick={e => handleFloorClick(f.id, f.label, e)}
          disabled={isLinking}
        >
          {React.string(f.short)}
          {switch f.suffix {
          | Some(s) if s != "" => <sup className="text-[10px] -ml-1"> {React.string(s)} </sup>
          | _ => React.null
          }}
        </Shadcn.Button>
      </Tooltip>
    })
    ->React.array}
  </div>
})
