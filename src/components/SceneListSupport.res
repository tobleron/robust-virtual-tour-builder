@val external parseIntJs: string => float = "parseInt"

module ReorderDialog = {
  @react.component
  let make = (~currentIndex: int, ~sceneCount: int, ~sceneName: string) => {
    <div className="reorder-scene-panel">
      <div className="reorder-scene-current">
        <span className="reorder-scene-current-label"> {React.string("Selected")} </span>
        <strong className="reorder-scene-current-name"> {React.string(sceneName)} </strong>
      </div>
      <label className="reorder-scene-label" htmlFor="scene-reorder-target-select">
        {React.string("Move scene to")}
      </label>
      <select
        id="scene-reorder-target-select"
        defaultValue={Belt.Int.toString(currentIndex)}
        className="reorder-scene-select"
      >
        {Belt.Array.makeBy(sceneCount, idx => {
          <option key={Belt.Int.toString(idx)} value={Belt.Int.toString(idx)}>
            {React.string("Position " ++ Belt.Int.toString(idx + 1))}
          </option>
        })->React.array}
      </select>
    </div>
  }
}

let handleSceneClick = (
  ~sceneSlice: AppContext.sceneSlice,
  ~uiSlice: AppContext.uiSlice,
  ~canNavigate: bool,
  ~dispatch,
  index,
) => {
  if index == sceneSlice.activeIndex {
    ()
  } else if !canNavigate {
    Logger.debug(
      ~module_="SceneList",
      ~message="SCENE_CLICK_REJECTED_LOCK_HELD",
      ~data=Some({
        "index": index,
        "supervisorStatus": NavigationSupervisor.statusToString(NavigationSupervisor.getStatus()),
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

    switch Belt.Array.get(sceneSlice.scenes, index) {
    | Some(targetScene) => NavigationSupervisor.requestNavigation(targetScene.id)
    | None => ()
    }
  }
}

let handleDelete = (~canMutateProject: bool, ~getState, ~dispatch, index) => {
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

let openReorderDialog = (~canMutateProject: bool, ~dispatch, ~scenes, index) => {
  if !canMutateProject {
    Logger.warn(
      ~module_="SceneList",
      ~message="SCENE_REORDER_DIALOG_REJECTED_LOCK_HELD",
      ~data=Some({"index": index}),
      (),
    )
  } else {
    let currentPosition = index + 1
    let sceneName = switch Belt.Array.get(scenes, index) {
    | Some(scene) => TourLogic.formatDisplayLabel(scene)
    | None => "Selected Scene"
    }
    EventBus.dispatch(
      ShowModal({
        title: "Reorder Scene",
        description: Some("Choose a new order position."),
        content: Some(
          <ReorderDialog currentIndex=index sceneCount={Array.length(scenes)} sceneName />,
        ),
        buttons: [
          {
            label: "Confirm",
            class_: "bg-blue-500/20 text-white hover:bg-blue-500/35",
            onClick: () => {
              let selectEl = ReBindings.Dom.getElementById("scene-reorder-target-select")
              switch Nullable.toOption(selectEl) {
              | Some(el) =>
                let rawValue = ReBindings.Dom.getValue(el)
                let parsed = parseIntJs(rawValue)
                if !Float.isNaN(parsed) {
                  let targetIndex = parsed->Float.toInt
                  if targetIndex != index {
                    Logger.info(
                      ~module_="SceneList",
                      ~message="SCENE_REORDER_DIALOG_CONFIRMED",
                      ~data=Some({
                        "from": index,
                        "to": targetIndex,
                        "fromPosition": currentPosition,
                        "toPosition": targetIndex + 1,
                      }),
                      (),
                    )
                    dispatch(Actions.ReorderScenes(index, targetIndex))
                  }
                }
              | None => ()
              }
            },
            autoClose: Some(true),
          },
          {
            label: "Cancel",
            class_: "bg-slate-100/10 text-white hover:bg-white/20",
            onClick: () => (),
            autoClose: Some(true),
          },
        ],
        icon: Some("reorder"),
        allowClose: Some(true),
        onClose: None,
        className: Some("modal-blue modal-reorder-scene"),
      }),
    )
  }
}

let handleClearLinks = (~canMutateProject: bool, ~getState, ~dispatch, index) => {
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

let handleDrop = (~canMutateProject: bool, ~dispatch, ~setDraggedIndex, targetIndex, e) => {
  JsxEvent.Mouse.preventDefault(e)
  setDraggedIndex(current => {
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
  })
}
