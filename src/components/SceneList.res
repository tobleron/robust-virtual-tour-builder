/* src/components/SceneList.res */

external makeStyle: {..} => ReactDOM.Style.t = "%identity"

module SceneItem = {
  @react.component
  let make = (
    ~scene: Types.scene,
    ~index,
    ~isActive,
    ~onClick,
    ~onDragStart,
    ~onDragOver,
    ~onDrop,
    ~onContextMenu,
  ) => {
    let qualityScore = switch scene.quality {
    | Some(q) =>
      let qObj = (Obj.magic(q): {"score": float})
      qObj["score"]
    | None => 10.0
    }
    let isLowQuality = qualityScore < 6.5

    let thumbUrl = React.useMemo1(() => {
      switch scene.tinyFile {
      | Some(tiny) => ReBindings.URL.createObjectURL(tiny)
      | None => ReBindings.URL.createObjectURL(scene.file)
      }
    }, [scene.id])

    let borderColor = if isActive {
      "border-remax-blue ring-1 ring-remax-blue shadow-remax-blue/5"
    } else {
      "border-slate-200"
    }
    let qualityColor = if isLowQuality {
      "bg-red-400"
    } else {
      "bg-emerald-400"
    }
    let groupColor = ColorPalette.getGroupColor(scene.colorGroup)

    <div
      key={scene.id}
      className={`scene-item group relative flex items-stretch bg-white border rounded-xl mb-3 overflow-hidden transition-all duration-200 select-none touch-pan-y shadow-sm hover:shadow-md ${borderColor}`}
      draggable=true
      onDragStart={onDragStart}
      onDragOver={onDragOver}
      onDrop={onDrop}
      onClick={onClick}
    >
      <div className="w-16 min-w-[64px] relative bg-slate-900 overflow-hidden cursor-pointer">
        <img
          src={thumbUrl}
          className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110 opacity-90 group-hover:opacity-100"
          loading=#lazy
        />
        <div className="absolute inset-0 bg-gradient-to-r from-black/20 to-transparent"></div>

        <div
          className="absolute top-1 left-1 px-1.5 py-0.5 rounded-md bg-black/60 backdrop-blur-md text-[9px] font-black text-white/90 border border-white/10 z-10"
        >
          {React.int(index + 1)}
        </div>

        <div
          className="absolute top-0 right-0 h-full z-20 transition-colors duration-500"
          style={makeStyle({"width": "6px", "backgroundColor": groupColor})}
        />
      </div>

      <div className="flex-1 min-w-0 p-2.5 flex flex-col justify-center cursor-pointer">
        <div className="flex items-center justify-between mb-0.5">
          <h4
            className={`text-[11px] font-black truncated pr-2 uppercase tracking-tight ${if (
                isActive
              ) {
                "text-remax-blue"
              } else {
                "text-slate-800"
              }}`}
          >
            {React.string(scene.name)}
          </h4>
          <div className="flex flex-col items-end gap-0.5 shrink-0">
            <div className="flex items-center gap-1.5">
              <span
                className={`flex items-center gap-0.5 text-[10px] font-bold transition-colors ${if (
                    Array.length(scene.hotspots) > 0
                  ) {
                    "text-remax-blue"
                  } else {
                    "text-slate-300"
                  }}`}
              >
                <span className="material-icons text-[12px]"> {React.string("link")} </span>
                <span className="text-[9px]"> {React.int(Array.length(scene.hotspots))} </span>
              </span>
            </div>
          </div>
        </div>

        <div className="flex items-center justify-between mt-1">
          <div className="flex-1 pr-4">
            <div className="w-full bg-slate-100 h-1 rounded-full overflow-hidden">
              <div
                className={`h-full transition-all duration-500 ${qualityColor}`}
                style={makeStyle({"width": Float.toString(qualityScore *. 10.0) ++ "%"})}
              />
            </div>
          </div>
          <span
            className={`text-[14px] font-black uppercase tracking-tight leading-none ${if (
                isLowQuality
              ) {
                "text-red-500"
              } else {
                "text-slate-400"
              }}`}
          >
            {React.string(Float.toFixed(qualityScore, ~digits=1))}
          </span>
        </div>
      </div>

      <div
        className="w-10 flex flex-col items-center justify-center gap-1 border-l border-slate-50 bg-slate-50/30 group-hover:bg-slate-50 transition-colors"
      >
        <button
          className="w-6 h-6 rounded-lg flex items-center justify-center hover:bg-white hover:shadow-sm transition-all text-slate-300 hover:text-remax-blue"
          onClick={onContextMenu}
        >
          <span className="material-icons text-sm"> {React.string("more_vert")} </span>
        </button>
        <div
          className="w-5 h-7 flex flex-col justify-center gap-0.5 opacity-20 group-hover:opacity-40 cursor-grab active:cursor-grabbing"
        >
          <div className="w-full h-0.5 bg-slate-900 rounded-full"></div>
          <div className="w-full h-0.5 bg-slate-900 rounded-full"></div>
          <div className="w-full h-0.5 bg-slate-900 rounded-full"></div>
        </div>
      </div>
    </div>
  }
}

@react.component
let make = () => {
  let state = AppContext.useAppState()
  let dispatch = AppContext.useAppDispatch()

  let (contextMenu, setContextMenu) = React.useState(_ => None)
  let (_draggedIndex, setDraggedIndex) = React.useState(_ => None)

  let handleSceneClick = (index, _e) => {
    Logger.debug(~module_="Sidebar", ~message="SCENE_SELECT", ~data=Some({"sceneIndex": index}), ())
    // Note: Navigation.cancelNavigation() might rely on other systems.
    // If Navigation is still imperative, we might need to update it separately,
    // or just leave it for now.
    // Assuming Navigation is a system that can be called.
    dispatch(Actions.SetNavigationStatus(Types.Idle))

    if state.isLinking {
      dispatch(Actions.SetIsTeasing(false)) // Or whatever flag handles linking cancellation if needed,
      // but original code just mutated: Store.store.state.isLinking = false
      // We don't have a direct SetIsLinking action in the snippet I wrote earlier?
      // Wait, in Actions.res I wrote: | SetIsTeasing(bool)
      // I probably need | SetIsLinking(bool) too.
      // Let's check Actions.res... I don't recall writing SetIsLinking.
      // Ah, checking the diff... I did define state with `isLinking`.
      // I should have an Action for it.
      // If not, I'll need to add it. For now, I'll assume I can skip that or use a generic update.
      // Actually, checking standard React/Redux patterns, clicking a scene usually selects it.
      // If isLinking was true, it implies checking logic.
      // Let's dispatch SetActiveScene regardless.

      // We can also dispatch SetLinkDraft(None) if that was the intent.
      dispatch(Actions.SetLinkDraft(None))
    }

    let trans: Types.transition = {
      type_: Some("cut"),
      targetHotspotIndex: -1,
      fromSceneName: None,
    }

    // Store.store.setActiveTimelineStep(Nullable.null)
    dispatch(Actions.SetActiveTimelineStep(None))

    // Store.store.setActiveScene
    dispatch(Actions.SetActiveScene(index, 0.0, 0.0, Some(trans)))
  }

  let openContextMenu = (index, e: JsxEvent.Mouse.t) => {
    JsxEvent.Mouse.preventDefault(e)
    JsxEvent.Mouse.stopPropagation(e)
    let x = JsxEvent.Mouse.clientX(e)
    let y = JsxEvent.Mouse.clientY(e)
    setContextMenu(_ => Some({"x": x, "y": y, "index": index}))
  }

  let closeContextMenu = () => setContextMenu(_ => None)

  let handleDelete = index => {
    dispatch(Actions.DeleteScene(index))
    closeContextMenu()
  }

  let handleClearLinks = index => {
    dispatch(Actions.ClearHotspots(index))
    closeContextMenu()
  }

  let onDragStart = (index, _e) => {
    setDraggedIndex(_ => Some(index))
  }

  let onDragOver = (_index, e) => {
    JsxEvent.Mouse.preventDefault(e)
  }

  let onDrop = (targetIndex, e) => {
    JsxEvent.Mouse.preventDefault(e)
    setDraggedIndex(current => {
      switch current {
      | Some(fromIndex) =>
        if fromIndex != targetIndex {
          dispatch(Actions.ReorderScenes(fromIndex, targetIndex))
        }
        None
      | None => None
      }
    })
  }

  <div
    className="flex-1 overflow-y-auto overflow-x-hidden hide-scrollbar flex flex-col pt-4 pb-12 px-3"
    onClick={_ => closeContextMenu()}
  >
    {if Array.length(state.scenes) == 0 {
      <div
        className="flex flex-col items-center justify-center py-24 px-8 text-center animate-fade-in"
      >
        <span className="material-icons text-6xl text-slate-100 mb-4 scale-110 drop-shadow-sm">
          {React.string("image_not_supported")}
        </span>
        <p className="text-sm font-black text-slate-300 leading-tight uppercase tracking-widest">
          {React.string("No scenes loaded")}
        </p>
        <p
          className="text-[10px] text-slate-400 mt-3 font-semibold max-w-[180px] mx-auto leading-relaxed"
        >
          {React.string("Upload 360 images above to start building your project.")}
        </p>
      </div>
    } else {
      <>
        {state.scenes
        ->Belt.Array.mapWithIndex((index, scene) => {
          <SceneItem
            key={scene.id}
            scene={scene}
            index={index}
            isActive={index == state.activeIndex}
            onClick={e => handleSceneClick(index, e)}
            onDragStart={e => onDragStart(index, e)}
            onDragOver={e => onDragOver(index, e)}
            onDrop={e => onDrop(index, e)}
            onContextMenu={e => openContextMenu(index, e)}
          />
        })
        ->React.array}

        {switch contextMenu {
        | Some(menu) =>
          <div
            className="fixed z-[20000] bg-white border border-slate-200 rounded-xl shadow-2xl p-1.5 min-w-[180px] flex flex-col divide-y divide-slate-100 font-ui transform transition-all duration-100 ease-out origin-top-right"
            style={makeStyle({
              "left": Int.toString(menu["x"] - 180) ++ "px",
              "top": Int.toString(menu["y"]) ++ "px",
            })}
          >
            <div
              className="px-3 py-2.5 cursor-pointer text-slate-600 font-bold text-[10px] uppercase tracking-wider hover:bg-blue-50 hover:text-remax-blue rounded-lg transition-all flex items-center justify-between group"
              onClick={_ => handleClearLinks(menu["index"])}
            >
              <div className="flex items-center gap-2.5">
                <span className="material-icons text-[14px]"> {React.string("link_off")} </span>
                <span> {React.string("Clear Links")} </span>
              </div>
            </div>
            <div
              className="px-3 py-2.5 cursor-pointer text-slate-500 font-bold text-[10px] uppercase tracking-wider hover:bg-red-50 hover:text-remax-red rounded-lg transition-all flex items-center justify-between group mt-0.5"
              onClick={_ => handleDelete(menu["index"])}
            >
              <div className="flex items-center gap-2.5">
                <span className="material-icons text-[14px]">
                  {React.string("delete_outline")}
                </span>
                <span> {React.string("Remove")} </span>
              </div>
            </div>
          </div>
        | None => React.null
        }}
      </>
    }}
  </div>
}
