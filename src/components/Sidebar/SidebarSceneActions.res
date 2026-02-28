open SidebarBase
open ReBindings

let handleDeleteScene = async (index: int) => {
  let _ = await OptimisticAction.execute(~action=Actions.DeleteScene(index), ~apiCall=state => {
    switch state.sessionId {
    | Some(sid) =>
      let projectData = SidebarBase.getProjectData(state)
      Api.ProjectApi.saveProject(sid, projectData)
    | None => Promise.resolve(Error("No active session"))
    }
  })
}

let isMissingPanoramaFile = (f: Types.file) => {
  switch f {
  | Url(u) => u == ""
  | Blob(_) | File(_) => false
  }
}

let repairRestoredState = (~restoredState: Types.state, ~currentState: Types.state) => {
  let repairedInventory =
    restoredState.inventory
    ->Belt.Map.String.toArray
    ->Belt.Array.reduce(Belt.Map.String.empty, (acc, (id, entry)) => {
      let restoredScene = entry.scene
      let repairedFile = if !isMissingPanoramaFile(restoredScene.file) {
        restoredScene.file
      } else {
        switch currentState.inventory->Belt.Map.String.get(id) {
        | Some(currentEntry) if !isMissingPanoramaFile(currentEntry.scene.file) =>
          currentEntry.scene.file
        | _ =>
          switch restoredScene.originalFile {
          | Some(f) if !isMissingPanoramaFile(f) => f
          | _ =>
            switch restoredScene.tinyFile {
            | Some(f) if !isMissingPanoramaFile(f) => f
            | _ => restoredScene.file
            }
          }
        }
      }

      let repairedScene = {...restoredScene, file: repairedFile}
      acc->Belt.Map.String.set(id, {...entry, scene: repairedScene})
    })

  let rebuilt = {...restoredState, inventory: repairedInventory}
  let activeScenes = SceneInventory.getActiveScenes(rebuilt.inventory, rebuilt.sceneOrder)
  let sceneCount = Belt.Array.length(activeScenes)
  let activeIndex = if sceneCount == 0 {
    -1
  } else {
    let boundedHigh = rebuilt.activeIndex > sceneCount - 1 ? sceneCount - 1 : rebuilt.activeIndex
    boundedHigh < 0 ? 0 : boundedHigh
  }

  {
    ...rebuilt,
    activeIndex,
    activeYaw: activeIndex == -1 ? 0.0 : rebuilt.activeYaw,
    activePitch: activeIndex == -1 ? 0.0 : rebuilt.activePitch,
  }
}

let handleDeleteSceneWithUndo = (
  index: int,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
) => {
  let state = getState()
  let action = Actions.DeleteScene(index)

  let snapId = StateSnapshot.capture(state, action)
  dispatch(action)

  let undoCalled = ref(false)
  let performUndo = () => {
    if !undoCalled.contents {
      undoCalled := true
      switch StateSnapshot.rollback(snapId) {
      | Some(restoredState) =>
        let repaired = repairRestoredState(~restoredState, ~currentState=getState())
        AppContext.restoreState(repaired)
        NotificationManager.dismiss("undo-delete-" ++ snapId)
        NotificationManager.dispatch({
          id: "undone-notif-" ++ snapId,
          importance: Info,
          context: UserAction("undo"),
          message: "Scene deletion undone",
          details: None,
          action: None,
          duration: 3000,
          dismissible: true,
          createdAt: Date.now(),
        })
      | None => ()
      }
    }
  }

  let _ = Window.setTimeout(() => {
    if !undoCalled.contents {
      let currentState = getState()
      switch currentState.sessionId {
      | Some(sid) =>
        let projectData = getProjectData(currentState)
        Api.ProjectApi.saveProject(sid, projectData)->ignore
      | None => ()
      }
    }
  }, 9500)

  NotificationManager.dispatch({
    id: "undo-delete-" ++ snapId,
    importance: Success,
    context: UserAction("delete_scene"),
    message: "Scene deleted. Press U to undo.",
    details: None,
    action: Some({
      label: "Undo",
      onClick: performUndo,
      shortcut: Some("u"),
    }),
    duration: 9000,
    dismissible: true,
    createdAt: Date.now(),
  })
}

let handleClearLinksWithUndo = (
  index: int,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
) => {
  let state = getState()
  let action = Actions.ClearHotspots(index)

  let snapId = StateSnapshot.capture(state, action)
  dispatch(action)

  let undoCalled = ref(false)
  let performUndo = () => {
    if !undoCalled.contents {
      undoCalled := true
      switch StateSnapshot.rollback(snapId) {
      | Some(restoredState) =>
        let repaired = repairRestoredState(~restoredState, ~currentState=getState())
        AppContext.restoreState(repaired)
        NotificationManager.dismiss("undo-clear-" ++ snapId)
        NotificationManager.dispatch({
          id: "undone-clear-notif-" ++ snapId,
          importance: Info,
          context: UserAction("undo"),
          message: "Hotspots restored",
          details: None,
          action: None,
          duration: 3000,
          dismissible: true,
          createdAt: Date.now(),
        })
      | None => ()
      }
    }
  }

  let _ = Window.setTimeout(() => {
    if !undoCalled.contents {
      let currentState = getState()
      switch currentState.sessionId {
      | Some(sid) =>
        let projectData = getProjectData(currentState)
        Api.ProjectApi.saveProject(sid, projectData)->ignore
      | None => ()
      }
    }
  }, 9500)

  NotificationManager.dispatch({
    id: "undo-clear-" ++ snapId,
    importance: Success,
    context: UserAction("clear_links"),
    message: "Links cleared. Press U to undo.",
    details: None,
    action: Some({
      label: "Undo",
      onClick: performUndo,
      shortcut: Some("u"),
    }),
    duration: 9000,
    dismissible: true,
    createdAt: Date.now(),
  })
}
