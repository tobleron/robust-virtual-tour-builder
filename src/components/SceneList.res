// @efficiency-role: ui-component

external makeStyle: {..} => ReactDOM.Style.t = "%identity"

@react.component
let make = React.memo(() => {
  let sceneSlice = AppContext.useSceneSlice()
  let uiSlice = AppContext.useUiSlice()
  let canNavigate = Capability.useCapability(CanNavigate)
  let canMutateProject = Capability.useCapability(CanMutateProject)
  let isSystemLocked = Capability.useIsSystemLocked()
  let dispatch = AppContext.useAppDispatch()
  let getState = AppContext.getBridgeState

  let (_draggedIndex, setDraggedIndex) = React.useState(_ => None)

  // Virtualization constants
  let itemHeight = 72.0 // 64px (h-16) + 8px (mb-2)
  let buffer = 10

  let containerRef = React.useRef(Nullable.null)
  let (scrollState, setScrollState) = React.useState(_ => (0.0, 800.0)) // (scrollTop, viewportHeight)

  React.useEffect0(() => {
    Logger.initialized(~module_="SceneListMain")

    let scrollContainer = switch Nullable.toOption(containerRef.current) {
    | Some(el) =>
      let sc = ReBindings.Dom.closest(el, ".sidebar-content")
      switch Nullable.toOption(sc) {
      | Some(s) => Some(s)
      | None =>
        let globalSc = ReBindings.Dom.querySelector(ReBindings.Dom.documentBody, ".sidebar-content")
        Nullable.toOption(globalSc)
      }
    | None => None
    }

    switch scrollContainer {
    | Some(sc) =>
      let rafId = ref(None)

      let updateScroll = () => {
        setScrollState(
          _ => (
            ReBindings.Dom.getScrollTop(sc)->Int.toFloat,
            ReBindings.Dom.getClientHeight(sc)->Int.toFloat,
          ),
        )
      }

      let handleScroll = _ => {
        switch rafId.contents {
        | Some(_) => ()
        | None =>
          rafId :=
            Some(
              ReBindings.Window.requestAnimationFrame(
                () => {
                  updateScroll()
                  rafId := None
                },
              ),
            )
        }
      }

      ReBindings.Dom.addEventListener(sc, "scroll", handleScroll)

      updateScroll()

      let resizeObserver = ReBindings.ResizeObserver.make(
        _entries => {
          updateScroll()
        },
      )
      ReBindings.ResizeObserver.observe(resizeObserver, sc)

      Some(
        () => {
          ReBindings.Dom.removeEventListener(sc, "scroll", handleScroll)
          ReBindings.ResizeObserver.disconnect(resizeObserver)
          rafId.contents->Option.forEach(ReBindings.Window.cancelAnimationFrame)
        },
      )
    | None => None
    }
  })

  let (scrollTop, viewportHeight) = scrollState
  let totalHeight = Array.length(sceneSlice.scenes)->Int.toFloat *. itemHeight

  let startIndex = Math.floor(scrollTop /. itemHeight) -. buffer->Int.toFloat
  let startIndex = Math.max(0.0, startIndex)->Float.toInt

  let rawVisibleCount = Math.ceil(viewportHeight /. itemHeight)
  let visibleCount = Math.max(10.0, rawVisibleCount)

  let endIndex = startIndex + visibleCount->Float.toInt + buffer * 2
  let endIndex = Math.Int.min(Array.length(sceneSlice.scenes) - 1, endIndex)

  let handleSceneClick = React.useMemo3(() =>
    index => {
      if index == sceneSlice.activeIndex {
        ()
      } else if !canNavigate {
        // LockFeedback component handles timeout notification independently
        // No notification dispatch here to avoid redundant "System is busy" message
        Logger.debug(
          ~module_="SceneList",
          ~message="SCENE_CLICK_REJECTED_LOCK_HELD",
          ~data=Some({
            "index": index,
            "supervisorStatus": NavigationSupervisor.statusToString(
              NavigationSupervisor.getStatus(),
            ),
          }),
          (),
        )
      } else {
        Logger.debug(
          ~module_="SceneList",
          ~message="SCENE_SWITCH_CLICKED",
          ~data=Some({"index": index}),
          (),
        )

        if uiSlice.isLinking {
          dispatch(Actions.StopLinking)
        }

        // Get target scene and call Supervisor - it handles FSM events and navigation coordination
        switch Belt.Array.get(sceneSlice.scenes, index) {
        | Some(targetScene) => NavigationSupervisor.requestNavigation(targetScene.id)
        | None => ()
        }
      }
    }
  , (sceneSlice.activeIndex, uiSlice.isLinking, canNavigate))

  let handleDelete = React.useMemo1(() =>
    index => {
      if canMutateProject {
        Logger.info(
          ~module_="SceneList",
          ~message="SCENE_DELETE_REQUESTED_WITH_UNDO",
          ~data=Some({"index": index}),
          (),
        )
        SidebarLogic.handleDeleteSceneWithUndo(index, ~getState, ~dispatch)
      } else {
        Logger.warn(
          ~module_="SceneList",
          ~message="SCENE_DELETE_REJECTED_LOCK_HELD",
          ~data=Some({"index": index}),
          (),
        )
      }
    }
  , [canMutateProject])

  let handleClearLinks = React.useMemo1(() =>
    index => {
      if canMutateProject {
        Logger.info(
          ~module_="SceneList",
          ~message="SCENE_CLEAR_LINKS_REQUESTED_WITH_UNDO",
          ~data=Some({"index": index}),
          (),
        )
        SidebarLogic.handleClearLinksWithUndo(index, ~getState, ~dispatch)
      } else {
        Logger.warn(
          ~module_="SceneList",
          ~message="SCENE_CLEAR_LINKS_REJECTED_LOCK_HELD",
          ~data=Some({"index": index}),
          (),
        )
      }
    }
  , [canMutateProject])

  let onDragStart = React.useMemo0(() =>
    (index, _e) => {
      setDraggedIndex(_ => Some(index))
    }
  )

  let onDragOver = React.useMemo0(() =>
    (_index, e) => {
      JsxEvent.Mouse.preventDefault(e)
    }
  )

  let onDrop = React.useMemo2(() =>
    (targetIndex, e) => {
      JsxEvent.Mouse.preventDefault(e)
      setDraggedIndex(
        current => {
          switch current {
          | Some(fromIndex) =>
            if canMutateProject && fromIndex != targetIndex {
              Logger.info(
                ~module_="SceneList",
                ~message="SCENE_REORDER",
                ~data=Some({"from": fromIndex, "to": targetIndex}),
                (),
              )
              dispatch(Actions.ReorderScenes(fromIndex, targetIndex))
            }
            None
          | None => None
          }
        },
      )
    }
  , (dispatch, canMutateProject))

  <div
    className="flex-1 flex flex-col pt-2 pb-12 relative"
    ref={ReactDOM.Ref.domRef(containerRef)}
    style={makeStyle({
      "height": if Array.length(sceneSlice.scenes) > 0 {
        totalHeight->Float.toString ++ "px"
      } else {
        "auto"
      },
    })}
  >
    {if Array.length(sceneSlice.scenes) == 0 {
      <div
        className="flex flex-col items-center justify-center py-20 px-6 text-center animate-fade-in"
      >
        <div
          className="w-20 h-20 rounded-full bg-slate-100 flex items-center justify-center mb-6 shadow-inner"
        >
          <LucideIcons.Images className="text-[#f97316]" size=56 strokeWidth=1.5 />
        </div>
        <h4 className="text-sm font-semibold text-slate-600 uppercase tracking-widest mb-2">
          {React.string("No scenes")}
        </h4>
        <p className="text-[11px] text-slate-600 font-medium max-w-[200px] leading-relaxed">
          {React.string("Upload your 360 panorama images to start building your tour.")}
        </p>
      </div>
    } else {
      <>
        {sceneSlice.scenes
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
              isActive={actualIndex == sceneSlice.activeIndex}
              interactionLocked=isSystemLocked
              onItemClick={handleSceneClick}
              onItemDragStart={onDragStart}
              onItemDragOver={onDragOver}
              onItemDrop={onDrop}
              onItemDelete={handleDelete}
              onItemClearLinks={handleClearLinks}
            />
          </div>
        })
        ->React.array}
      </>
    }}
  </div>
})
