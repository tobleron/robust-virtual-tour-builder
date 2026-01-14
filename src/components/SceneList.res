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

    let activeClasses = if isActive {
      "border-primary ring-2 ring-primary/20 bg-slate-50 shadow-lg shadow-primary/5"
    } else {
      "border-slate-100 hover:border-slate-300 bg-white shadow-sm"
    }
    
    let qualityColor = if isLowQuality {
      "bg-danger"
    } else {
      "bg-success"
    }
    let groupColor = ColorPalette.getGroupColor(scene.colorGroup)

    <div
      key={scene.id}
      className={`scene-item group relative flex items-stretch border rounded-2xl mb-4 overflow-hidden transition-all duration-300 select-none touch-pan-y hover:shadow-xl hover:-translate-y-0.5 ${activeClasses}`}
      draggable=true
      onDragStart={onDragStart}
      onDragOver={onDragOver}
      onDrop={onDrop}
      onClick={onClick}
    >
      /* Thumbnail */
      <div className="w-20 min-w-[80px] relative bg-slate-900 overflow-hidden cursor-pointer">
        <img
          src={thumbUrl}
          className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110 opacity-80 group-hover:opacity-100"
          loading=#lazy
        />
        <div className="absolute inset-0 bg-gradient-to-r from-slate-950/40 to-transparent" />

        <div
          className="absolute top-2 left-2 px-2 py-0.5 rounded-lg bg-slate-950/70 backdrop-blur-md text-[10px] font-black text-white border border-white/10 z-10 shadow-lg"
        >
          {React.int(index + 1)}
        </div>

        <div
          className="absolute top-0 right-0 h-full z-20 transition-all duration-500 shadow-xl"
          style={makeStyle({"width": "4px", "backgroundColor": groupColor})}
        />
      </div>

      /* Content */
      <div className="flex-1 min-w-0 p-4 flex flex-col justify-center cursor-pointer">
        <div className="flex items-center justify-between mb-2">
          <h4
            className={`text-[13px] font-bold truncate pr-3 tracking-tight ${if (
                isActive
              ) {
                "text-primary-light"
              } else {
                "text-slate-700"
              }}`}
          >
            {React.string(scene.name)}
          </h4>
          <div className="flex items-center gap-2 shrink-0">
             {if Array.length(scene.hotspots) > 0 {
               <div className="flex items-center gap-1 px-1.5 py-0.5 rounded-full bg-primary/10 text-primary-light border border-primary/10">
                 <span className="material-icons text-[12px]"> {React.string("link")} </span>
                 <span className="text-[10px] font-bold"> {React.int(Array.length(scene.hotspots))} </span>
               </div>
             } else {
               React.null
             }}
          </div>
        </div>

        <div className="flex items-center gap-3">
          <div className="flex-1">
            <div className="w-full bg-slate-100 h-1.5 rounded-full overflow-hidden">
              <div
                className={`h-full transition-all duration-1000 ease-out rounded-full ${qualityColor}`}
                style={makeStyle({"width": Float.toString(qualityScore *. 10.0) ++ "%"})}
              />
            </div>
          </div>
          <span
            className={`text-[11px] font-black uppercase tracking-widest leading-none ${if (
                isLowQuality
              ) {
                "text-danger"
              } else {
                "text-slate-400"
              }}`}
          >
            {React.string(Float.toFixed(qualityScore, ~digits=1))}
          </span>
        </div>
      </div>

      /* Actions Bar */
      <div
        className="w-12 flex flex-col items-center justify-center gap-2 border-l border-slate-50 bg-slate-50/50 group-hover:bg-slate-100 transition-colors"
      >
        <button
          className="w-8 h-8 rounded-xl flex items-center justify-center hover:bg-white hover:shadow-md transition-all text-slate-400 hover:text-primary active:scale-90"
          onClick={onContextMenu}
        >
          <span className="material-icons text-lg"> {React.string("more_vert")} </span>
        </button>
        <div
          className="w-6 h-8 flex flex-col justify-center gap-1 opacity-20 group-hover:opacity-50 cursor-grab active:cursor-grabbing"
        >
          <div className="w-full h-0.5 bg-slate-400 rounded-full"></div>
          <div className="w-full h-0.5 bg-slate-400 rounded-full"></div>
          <div className="w-full h-0.5 bg-slate-400 rounded-full"></div>
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
    dispatch(Actions.SetNavigationStatus(Types.Idle))
    if state.isLinking {
      dispatch(Actions.SetIsLinking(false))
      dispatch(Actions.SetLinkDraft(None))
    }
    let trans: Types.transition = {
      type_: Some("cut"),
      targetHotspotIndex: -1,
      fromSceneName: None,
    }
    dispatch(Actions.SetActiveTimelineStep(None))
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
    className="flex-1 flex flex-col pt-2 pb-12"
    onClick={_ => closeContextMenu()}
  >
    {if Array.length(state.scenes) == 0 {
      <div
        className="flex flex-col items-center justify-center py-20 px-6 text-center animate-fade-in"
      >
        <div className="w-20 h-20 rounded-full bg-slate-50 flex items-center justify-center mb-6 shadow-inner">
           <span className="material-icons text-4xl text-slate-200">
             {React.string("photo_library")}
           </span>
        </div>
        <h4 className="text-sm font-bold text-slate-400 uppercase tracking-widest mb-2">
          {React.string("No scenes")}
        </h4>
        <p className="text-[11px] text-slate-400 font-medium max-w-[200px] leading-relaxed">
          {React.string("Upload your 360 panorama images to start building your tour.")}
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
            className="fixed z-[30000] premium-glass rounded-2xl p-1.5 min-w-[200px] flex flex-col shadow-2xl animate-fade-in border border-white/20"
            style={makeStyle({
              "left": Int.toString(menu["x"] - 200) ++ "px",
              "top": Int.toString(menu["y"]) ++ "px",
            })}
          >
            <div
              className="px-4 py-3 cursor-pointer text-white/80 font-bold text-[11px] uppercase tracking-widest hover:bg-white/10 rounded-xl transition-all flex items-center gap-3 group"
              onClick={_ => handleClearLinks(menu["index"])}
            >
              <span className="material-icons text-lg text-primary-light"> {React.string("link_off")} </span>
              <span> {React.string("Clear Links")} </span>
            </div>
            
            <div className="h-px bg-white/10 my-1 mx-2" />
            
            <div
              className="px-4 py-3 cursor-pointer text-white/80 font-bold text-[11px] uppercase tracking-widest hover:bg-danger/20 hover:text-white rounded-xl transition-all flex items-center gap-3 group"
              onClick={_ => handleDelete(menu["index"])}
            >
              <span className="material-icons text-lg text-danger"> {React.string("delete_outline")} </span>
              <span> {React.string("Remove Scene")} </span>
            </div>
          </div>
        | None => React.null
        }}
      </>
    }}
  </div>
}

