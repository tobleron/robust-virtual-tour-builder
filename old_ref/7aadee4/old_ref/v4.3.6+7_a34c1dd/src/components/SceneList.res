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
      // Middle ground: typed cast for nested JSON
      let qObj = (Obj.magic(q): SharedTypes.qualityAnalysis)
      qObj.score
    | None => 10.0
    }
    let isLowQuality = qualityScore < 6.5

    let thumbUrl = React.useMemo1(() => {
      switch scene.tinyFile {
      | Some(tiny) => UrlUtils.fileToUrl(tiny)
      | None => UrlUtils.fileToUrl(scene.file)
      }
    }, [scene.id])

    let activeClasses = if isActive {
      "border-slate-200 ring-0 bg-slate-50/50"
    } else {
      "border-slate-100 hover:border-slate-200 bg-white"
    }

    let qualityColor = if isLowQuality {
      "bg-danger"
    } else {
      "bg-success"
    }
    let groupColorClass = ColorPalette.getGroupClass(scene.colorGroup)

    <div
      key={scene.id}
      className={`scene-item group relative flex items-stretch border rounded-xl mb-4 overflow-hidden transition-all duration-200 select-none touch-pan-y active-push h-24 focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 focus-visible:outline-none ${activeClasses}`}
      draggable=true
      onDragStart={onDragStart}
      onDragOver={onDragOver}
      onDrop={onDrop}
      onClick={onClick}
      tabIndex=0
      onKeyDown={e => {
        if JsxEvent.Keyboard.key(e) == "Enter" || JsxEvent.Keyboard.key(e) == " " {
          JsxEvent.Keyboard.preventDefault(e)
          // For keyboard, we don't pass the event if it's strictly Mouse event
          // but handleSceneClick doesn't use the event anyway
          onClick(Obj.magic(e)) // Keeping one magic here as fixing onClick type across components is large
        }
      }}
      role="button"
      ariaLabel={`Select scene ${scene.name}`}
    >
      /* Thumbnail */
      <div className="w-20 min-w-[80px] relative bg-slate-900 overflow-hidden cursor-pointer">
        <img
          src={thumbUrl}
          alt={`Thumbnail of ${scene.name}`}
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
          className={`absolute top-0 right-0 h-full z-20 transition-all duration-500 shadow-xl w-1 ${groupColorClass}`}
        />
      </div>

      /* Content */
      <div className="flex-1 min-w-0 p-4 flex flex-col justify-center cursor-pointer">
        <div className="flex items-center justify-between mb-2">
          <h4
            className={`text-[13px] font-medium truncate pr-3 tracking-tight ${if isActive {
                "text-primary-light"
              } else {
                "text-slate-700"
              }}`}
          >
            {React.string(scene.name)}
          </h4>
          <div className="flex items-center gap-2 shrink-0">
            {if Array.length(scene.hotspots) > 0 {
              <div className="flex items-center gap-1.5 text-primary-light transition-colors">
                <span className="material-icons text-[12px]"> {React.string("link")} </span>
                <span className="text-[10px] font-bold">
                  {React.int(Array.length(scene.hotspots))}
                </span>
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
                "text-slate-600"
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
          className="w-8 h-8 rounded-xl flex items-center justify-center hover:bg-white hover:shadow-md transition-all text-slate-600 hover:text-primary active:scale-90 focus-visible:ring-2 focus-visible:ring-primary focus-visible:outline-none"
          onClick={onContextMenu}
          ariaLabel={`Actions for ${scene.name}`}
        >
          <span className="material-icons text-lg" ariaHidden=true>
            {React.string("more_vert")}
          </span>
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

type contextMenuInfo = {
  anchorRect: {"top": float, "left": float, "width": float, "height": float},
  index: int,
}

@react.component
let make = () => {
  let state = AppContext.useAppState()
  let dispatch = AppContext.useAppDispatch()

  let (contextMenu, setContextMenu) = React.useState(_ => None)
  let (_draggedIndex, setDraggedIndex) = React.useState(_ => None)
  let contextMenuTimeout = React.useRef(None)

  let closeContextMenu = () => {
    setContextMenu(_ => None)
    contextMenuTimeout.current = None
  }

  let scheduleMenuClose = () => {
    switch contextMenuTimeout.current {
    | Some(id) => ReBindings.Window.clearTimeout(id)
    | None => ()
    }
    contextMenuTimeout.current = Some(ReBindings.Window.setTimeout(() => {
        closeContextMenu()
      }, 1500))
  }

  // Close context menu on outside click
  React.useEffect0(() => {
    let handleWindowClick = _ => {
      closeContextMenu()
    }
    ReBindings.Window.addEventListener("click", handleWindowClick)
    Some(
      () => {
        ReBindings.Window.removeEventListener("click", handleWindowClick)
        switch contextMenuTimeout.current {
        | Some(id) => ReBindings.Window.clearTimeout(id)
        | None => ()
        }
      },
    )
  })

  // Virtualization constants
  let itemHeight = 112.0 // 96px (h-24) + 16px (mb-4)
  let buffer = 10

  let containerRef = React.useRef(Nullable.null)
  let (scrollState, setScrollState) = React.useState(_ => (0.0, 800.0)) // (scrollTop, viewportHeight)

  React.useEffect0(() => {
    let scrollContainer = switch Nullable.toOption(containerRef.current) {
    | Some(el) =>
      let sc = ReBindings.Dom.closest(el, ".sidebar-content")
      switch Nullable.toOption(sc) {
      | Some(s) => Some(s)
      | None =>
        // Fallback: try finding it globally
        let globalSc = ReBindings.Dom.querySelector(ReBindings.Dom.documentBody, ".sidebar-content")
        Nullable.toOption(globalSc)
      }
    | None => None
    }

    switch scrollContainer {
    | Some(sc) =>
      let updateScroll = () => {
        setScrollState(_ => (
          ReBindings.Dom.getScrollTop(sc)->Int.toFloat,
          ReBindings.Dom.getClientHeight(sc)->Int.toFloat,
        ))
      }

      let handleScroll = _ => updateScroll()
      ReBindings.Dom.addEventListener(sc, "scroll", handleScroll)

      // Initial update
      updateScroll()

      let resizeObserver = ReBindings.ResizeObserver.make(_entries => {
        updateScroll()
      })
      ReBindings.ResizeObserver.observe(resizeObserver, sc)

      Some(
        () => {
          ReBindings.Dom.removeEventListener(sc, "scroll", handleScroll)
          ReBindings.ResizeObserver.disconnect(resizeObserver)
        },
      )
    | None => None
    }
  })

  let (scrollTop, viewportHeight) = scrollState
  let totalHeight = Array.length(state.scenes)->Int.toFloat *. itemHeight

  let startIndex = Math.floor(scrollTop /. itemHeight) -. buffer->Int.toFloat
  let startIndex = Math.max(0.0, startIndex)->Float.toInt

  // Ensure we render at least a screen's worth even if viewport calculation fails
  let rawVisibleCount = Math.ceil(viewportHeight /. itemHeight)
  let visibleCount = Math.max(10.0, rawVisibleCount)

  let endIndex = startIndex + visibleCount->Float.toInt + buffer * 2
  let endIndex = Math.Int.min(Array.length(state.scenes) - 1, endIndex)

  let handleSceneClick = (index, _e) => {
    let now = Date.now()
    let timeDiff = now -. ViewerState.state.lastSwitchTime
    let throttleLimit = 900.0

    // Check if we are clicking the SAME scene (allow re-click only if needed, but generally throttle navigation)
    // Actually, just throttle any rapid switching.

    if timeDiff < throttleLimit {
      EventBus.dispatch(ShowNotification("Switching too fast - Please wait...", #Warning))
    } else {
      ViewerState.state.lastSwitchTime = now

      dispatch(Actions.SetNavigationStatus(Types.Idle))
      if state.isLinking {
        dispatch(Actions.StopLinking)
      }
      let trans: Types.transition = {
        type_: Some("cut"),
        targetHotspotIndex: -1,
        fromSceneName: None,
      }
      dispatch(Actions.SetActiveTimelineStep(None))
      dispatch(Actions.SetActiveScene(index, 0.0, 0.0, Some(trans)))
    }
  }

  let openContextMenu = (index, e: JsxEvent.Mouse.t) => {
    JsxEvent.Mouse.preventDefault(e)
    JsxEvent.Mouse.stopPropagation(e)

    let target: Dom.element = JsxEvent.Mouse.currentTarget(e)->Obj.magic
    let rect = ReBindings.Dom.getBoundingClientRect(target)

    switch contextMenuTimeout.current {
    | Some(id) => ReBindings.Window.clearTimeout(id)
    | None => ()
    }
    contextMenuTimeout.current = None

    setContextMenu(prev => {
      switch prev {
      | Some(menu) if menu.index == index => None
      | _ =>
        Some({
          anchorRect: {
            "top": rect.top,
            "left": rect.left,
            "width": rect.width,
            "height": rect.height,
          },
          index,
        })
      }
    })
  }

  let handleDelete = index => {
    dispatch(Actions.DeleteScene(index))
    scheduleMenuClose()
  }

  let handleClearLinks = index => {
    dispatch(Actions.ClearHotspots(index))
    scheduleMenuClose()
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
    className="flex-1 flex flex-col pt-2 pb-12 relative"
    onClick={_ => closeContextMenu()}
    ref={ReactDOM.Ref.domRef(containerRef)}
    style={makeStyle({
      "height": if Array.length(state.scenes) > 0 {
        totalHeight->Float.toString ++ "px"
      } else {
        "auto"
      },
    })}
  >
    {if Array.length(state.scenes) == 0 {
      <div
        className="flex flex-col items-center justify-center py-20 px-6 text-center animate-fade-in"
      >
        <div
          className="w-20 h-20 rounded-full bg-slate-50 flex items-center justify-center mb-6 shadow-inner"
        >
          <span className="material-icons text-4xl text-slate-200">
            {React.string("photo_library")}
          </span>
        </div>
        <h4 className="text-sm font-bold text-slate-600 uppercase tracking-widest mb-2">
          {React.string("No scenes")}
        </h4>
        <p className="text-[11px] text-slate-600 font-medium max-w-[200px] leading-relaxed">
          {React.string("Upload your 360 panorama images to start building your tour.")}
        </p>
      </div>
    } else {
      <>
        {state.scenes
        ->Belt.Array.slice(~offset=startIndex, ~len=endIndex - startIndex + 1)
        ->Belt.Array.mapWithIndex((i, scene) => {
          let actualIndex = startIndex + i
          <div
            key={scene.id}
            style={makeStyle({
              "position": "absolute",
              "top": (actualIndex->Int.toFloat *. itemHeight)->Float.toString ++ "px",
              "width": "100%",
            })}
          >
            <SceneItem
              key={scene.id}
              scene={scene}
              index={actualIndex}
              isActive={actualIndex == state.activeIndex}
              onClick={e => handleSceneClick(actualIndex, e)}
              onDragStart={e => onDragStart(actualIndex, e)}
              onDragOver={e => onDragOver(actualIndex, e)}
              onDrop={e => onDrop(actualIndex, e)}
              onContextMenu={e => openContextMenu(actualIndex, e)}
            />
          </div>
        })
        ->React.array}

        {switch contextMenu {
        | Some(menu) =>
          let menuWidth = 200.0
          let menuHeight = 110.0 // Estimated height of the menu
          let viewportWidth = ReBindings.Window.innerWidth->Int.toFloat
          let viewportHeight = ReBindings.Window.innerHeight->Int.toFloat

          // Calculate Dynamic Position
          // We want the menu to appear to the left of the 3-dot button
          // with a small gap, aligned slightly below the top of the button.
          let left = menu.anchorRect["left"] -. menuWidth -. 8.0
          let top = menu.anchorRect["top"] +. 8.0

          // Boundary Awareness: Keep menu inside the screen
          let left = Math.max(12.0, Math.min(viewportWidth -. menuWidth -. 12.0, left))
          let top = Math.max(12.0, Math.min(viewportHeight -. menuHeight -. 12.0, top))

          <div
            className="fixed z-[30000] bg-white rounded-2xl p-1.5 min-w-[200px] flex flex-col shadow-2xl animate-fade-in border border-slate-200"
            role="menu"
            onClick={e => JsxEvent.Mouse.stopPropagation(e)}
            style={makeStyle({
              "left": left->Float.toString ++ "px",
              "top": top->Float.toString ++ "px",
              "width": menuWidth->Float.toString ++ "px",
            })}
          >
            <div
              className="px-4 py-3 cursor-pointer text-slate-700 font-bold text-[11px] uppercase tracking-widest hover:bg-slate-50 rounded-xl transition-all flex items-center gap-3 group"
              onClick={_ => handleClearLinks(menu.index)}
              role="menuitem"
              tabIndex=0
              onKeyDown={e => {
                if JsxEvent.Keyboard.key(e) == "Enter" {
                  handleClearLinks(menu.index)
                }
              }}
            >
              <span className="material-icons text-lg text-primary" ariaHidden=true>
                {React.string("link_off")}
              </span>
              <span> {React.string("Clear Links")} </span>
            </div>

            <div className="h-px bg-slate-100 my-1 mx-2" />

            <div
              className="px-4 py-3 cursor-pointer text-slate-700 font-bold text-[11px] uppercase tracking-widest hover:bg-danger/10 hover:text-danger rounded-xl transition-all flex items-center gap-3 group"
              onClick={_ => handleDelete(menu.index)}
              role="menuitem"
              tabIndex=0
              onKeyDown={e => {
                if JsxEvent.Keyboard.key(e) == "Enter" {
                  handleDelete(menu.index)
                }
              }}
            >
              <span className="material-icons text-lg text-danger" ariaHidden=true>
                {React.string("delete_outline")}
              </span>
              <span> {React.string("Remove Scene")} </span>
            </div>
          </div>
        | None => React.null
        }}
      </>
    }}
  </div>
}
