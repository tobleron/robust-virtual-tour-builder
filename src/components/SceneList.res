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
    ~onDelete,
    ~onClearLinks,
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
      // Drag Handle
      <div className="flex items-center justify-center w-6 text-slate-300 hover:text-slate-500 cursor-grab active:cursor-grabbing transition-colors">
        <LucideIcons.GripVertical size=16 />
      </div>

      // Thumbnail with Quality Bar
      <div className="flex flex-col gap-1">
        <div className="w-28 aspect-video relative bg-slate-900 overflow-hidden cursor-pointer rounded-lg">
          <img
            src={thumbUrl}
            alt={`Thumbnail of ${scene.name}`}
            className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110 opacity-80 group-hover:opacity-100"
            loading=#lazy
          />
          <div className="absolute inset-0 bg-gradient-to-r from-slate-950/40 to-transparent" />

          <div
            className="absolute top-1.5 left-1.5 px-1.5 py-0.5 rounded bg-slate-950/70 backdrop-blur-md text-[9px] font-black text-white border border-white/10 z-10 shadow-lg"
          >
            {React.int(index + 1)}
          </div>

          <div
            className={`absolute top-0 right-0 h-full z-20 transition-all duration-500 shadow-xl w-1 ${groupColorClass}`}
          />
        </div>

        /* Quality Bar under thumbnail */
        <div className="flex items-center gap-2">
          <div className="flex-1">
            <div className="w-full bg-slate-100 h-1 rounded-full overflow-hidden">
              <div
                className={`h-full transition-all duration-1000 ease-out rounded-full ${qualityColor}`}
                // EXCEPTION: Dynamic progress percentage (CSS_ARCHITECTURE.md §3.1)
                // Value changes continuously 0-100% based on quality score
                style={makeStyle({"width": Float.toString(qualityScore *. 10.0) ++ "%"})}
              />
            </div>
          </div>
          <span
            className={`text-[9px] font-black uppercase tracking-wider leading-none ${if (
                isLowQuality
              ) {
                "text-danger"
              } else {
                "text-slate-500"
              }}`}
          >
            {React.string(Float.toFixed(qualityScore, ~digits=1))}
          </span>
        </div>
      </div>

      /* Content */
      <div className="flex-1 min-w-0 py-2 px-3 flex flex-col justify-center cursor-pointer">
        <div className="flex items-center justify-between gap-2">
          <h4
            className={`text-[13px] font-normal truncate tracking-tight ${if isActive {
                "text-primary-light"
              } else {
                "text-slate-700"
              }}`}
          >
            {React.string(scene.name)}
          </h4>
          {if Array.length(scene.hotspots) > 0 {
            <div className="flex items-center gap-1.5 text-primary-dark transition-colors shrink-0">
              <LucideIcons.Link size=14 />
              <span className="text-[11px] font-bold">
                {React.int(Array.length(scene.hotspots))}
              </span>
            </div>
          } else {
            React.null
          }}
        </div>
      </div>

      /* Actions Bar */
      <div
        className="w-12 flex flex-col items-center justify-center gap-2 border-l border-slate-50 bg-slate-50/50 group-hover:bg-slate-100 transition-colors"
      >
        <Shadcn.DropdownMenu>
          <Shadcn.DropdownMenu.Trigger asChild=true>
            <button
              className="w-8 h-8 rounded-xl flex items-center justify-center hover:bg-white hover:shadow-md transition-all text-slate-600 hover:text-primary active:scale-90 focus-visible:ring-2 focus-visible:ring-primary focus-visible:outline-none"
              ariaLabel={`Actions for ${scene.name}`}
            >
              <LucideIcons.MoreVertical className="text-lg" />
            </button>
          </Shadcn.DropdownMenu.Trigger>
          <Shadcn.DropdownMenu.Content side="right" sideOffset=10 className="w-56 p-1.5 z-[10000]">
            <Shadcn.DropdownMenu.Item onClick={_ => onClearLinks()}>
              <LucideIcons.Unlink className="text-lg mr-2 text-primary" />
              <span> {React.string("Clear Links")} </span>
            </Shadcn.DropdownMenu.Item>
            <Shadcn.DropdownMenu.Separator />
            <Shadcn.DropdownMenu.Item
              onClick={_ => onDelete()} className="text-danger hover:bg-danger/10"
            >
              <LucideIcons.Trash2 className="text-lg mr-2 text-danger" />
              <span> {React.string("Remove Scene")} </span>
            </Shadcn.DropdownMenu.Item>
          </Shadcn.DropdownMenu.Content>
        </Shadcn.DropdownMenu>
        <div
          className="w-6 h-8 flex flex-col justify-center gap-1 opacity-20 group-hover:opacity-50 cursor-grab active:cursor-grabbing"
        >
          <div className="w-full h-0.5 bg-slate-400 rounded-full" />
          <div className="w-full h-0.5 bg-slate-400 rounded-full" />
          <div className="w-full h-0.5 bg-slate-400 rounded-full" />
        </div>
      </div>
    </div>
  }
}

@react.component
let make = () => {
  let state = AppContext.useAppState()
  let dispatch = AppContext.useAppDispatch()

  let (_draggedIndex, setDraggedIndex) = React.useState(_ => None)

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
    if index == state.activeIndex {
      // Already selected, do nothing and don't trigger "too fast" warning
      ()
    } else {
      let now = Date.now()
      let timeDiff = now -. ViewerState.state.lastSwitchTime
      let throttleLimit = 650.0

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
  }

  let handleDelete = index => {
    dispatch(Actions.DeleteScene(index))
    EventBus.dispatch(ShowNotification("Scene Removed", #Info))
  }

  let handleClearLinks = index => {
    dispatch(Actions.ClearHotspots(index))
    EventBus.dispatch(ShowNotification("Links Cleared", #Info))
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
    ref={ReactDOM.Ref.domRef(containerRef)}
    // EXCEPTION: Dynamic container height (CSS_ARCHITECTURE.md §3.1)
    // Required for virtualization to maintain scroll layout
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
          <LucideIcons.ImageIcon className="text-4xl text-slate-200" />
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
            // EXCEPTION: Dynamic item position (CSS_ARCHITECTURE.md §3.1)
            // Required for virtualization to position elements in scroll window
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
              onDelete={() => handleDelete(actualIndex)}
              onClearLinks={() => handleClearLinks(actualIndex)}
            />
          </div>
        })
        ->React.array}
      </>
    }}
  </div>
}
