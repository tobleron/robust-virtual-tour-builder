let localAssetCount = (state: Types.state): int => {
  let sceneAssets =
    SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
    ->Belt.Array.keep(scene =>
      switch scene.file {
      | File(_) | Blob(_) => true
      | Url(_) => false
      }
    )
    ->Belt.Array.length
  let logoAssets = switch state.logo {
  | Some(File(_)) | Some(Blob(_)) => 1
  | _ => 0
  }
  sceneAssets + logoAssets
}

let saveToServer = async (~state, ~dispatch, ~onPhase: option<string => unit>=?) => {
  let projectData = ProjectSystem.encodeProjectFromState(state)
  let snapshotResult = switch state.sessionId {
  | Some(id) => await Api.ProjectApi.syncSnapshot(~sessionId=id, ~projectData, ~origin=Manual)
  | None => await Api.ProjectApi.syncSnapshot(~projectData, ~origin=Manual)
  }

  switch snapshotResult {
  | Ok(syncResult) =>
    if state.sessionId == None {
      dispatch(Actions.SetSessionId(syncResult.sessionId))
    }
    let assetsToSync = localAssetCount(state)
    if assetsToSync > 0 {
      switch onPhase {
      | Some(notify) => notify("Uploading " ++ Belt.Int.toString(assetsToSync) ++ " assets...")
      | None => ()
      }
      let assetResult = await Api.ProjectApi.syncSnapshotAssets(~sessionId=syncResult.sessionId, ~state)
      switch assetResult {
      | Ok(_) => true
      | Error(msg) =>
        NotificationManager.dispatch({
          id: "",
          importance: Error,
          context: Operation("sidebar_save_server"),
          message: "Server save failed while uploading assets",
          details: Some(msg),
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Error),
          dismissible: true,
          createdAt: Date.now(),
        })
        false
      }
    } else {
      true
    }
  | Error(msg) =>
    NotificationManager.dispatch({
      id: "",
      importance: Error,
      context: Operation("sidebar_save_server"),
      message: "Server save failed",
      details: Some(msg),
      action: None,
      duration: NotificationTypes.defaultTimeoutMs(Error),
      dismissible: true,
      createdAt: Date.now(),
    })
    false
  }
}

let handleSave = async (~mode, ~getState, ~signal, ~onCancel, ~dispatch) => {
  let opIdRef = ref(None)

  try {
    let state: Types.state = getState()
    let opId = OperationLifecycle.start(
      ~type_=ProjectSave,
      ~scope=Blocking,
      ~phase="Initializing",
      ~meta=Logger.castToJson({
        "sceneCount": Array.length(
          SceneInventory.getActiveScenes(state.inventory, state.sceneOrder),
        ),
      }),
      (),
    )
    opIdRef := Some(opId)
    OperationLifecycle.registerCancel(opId, onCancel)

    let success = switch mode {
    | PersistencePreferences.Offline =>
      await ProjectManager.saveProject(
        state,
        ~signal,
        ~onProgress=(pct, _t, msg) => {
          SidebarLogic.updateProgress(~dispatch, ~onCancel, pct->Int.toFloat, msg, true, "Save")
        },
        ~opId,
      )
    | PersistencePreferences.Server =>
      SidebarLogic.updateProgress(~dispatch, ~onCancel, 10.0, "Saving metadata...", true, "Save")
      OperationLifecycle.progress(opId, 15.0, ~message="Saving metadata...", ~phase="Save", ())
      let assets = localAssetCount(state)
      let success = await saveToServer(
        ~state,
        ~dispatch,
        ~onPhase=message => {
          SidebarLogic.updateProgress(~dispatch, ~onCancel, 70.0, message, true, "Save")
          OperationLifecycle.progress(opId, 70.0, ~message, ~phase="Uploading", ())
        },
      )
      if success {
        let finalMessage = if assets > 0 {
            "Server snapshot saved with assets"
          } else {
            "Server snapshot saved"
          }
        OperationLifecycle.complete(opId, ~result=finalMessage, ())
      } else {
        OperationLifecycle.fail(opId, "Server save failed")
      }
      success
    | PersistencePreferences.Both =>
      SidebarLogic.updateProgress(~dispatch, ~onCancel, 10.0, "Saving metadata...", true, "Save")
      OperationLifecycle.progress(opId, 15.0, ~message="Saving metadata...", ~phase="Save", ())
      let serverSuccess = await saveToServer(
        ~state,
        ~dispatch,
        ~onPhase=message => {
          SidebarLogic.updateProgress(~dispatch, ~onCancel, 45.0, message, true, "Save")
          OperationLifecycle.progress(opId, 45.0, ~message, ~phase="Uploading", ())
        },
      )
      if serverSuccess {
        SidebarLogic.updateProgress(~dispatch, ~onCancel, 55.0, "Creating offline package...", true, "Save")
        await ProjectManager.saveProject(
          state,
          ~signal,
          ~onProgress=(pct, _t, msg) => {
            let adjusted = 55.0 +. (pct->Int.toFloat *. 0.45)
            SidebarLogic.updateProgress(~dispatch, ~onCancel, adjusted, msg, true, "Save")
          },
          ~opId,
        )
      } else {
        false
      }
    }

    if success {
      let successLabel = switch mode {
      | PersistencePreferences.Offline => "Offline save complete"
      | PersistencePreferences.Server => "Server save complete"
      | PersistencePreferences.Both => "Server and offline save complete"
      }
      SidebarLogic.updateProgress(~dispatch, 100.0, successLabel, false, "")
      NotificationManager.dispatch({
        id: "",
        importance: Success,
        context: Operation("sidebar_save"),
        message: successLabel,
        details: None,
        action: None,
        duration: NotificationTypes.defaultTimeoutMs(Success),
        dismissible: true,
        createdAt: Date.now(),
      })
    } else if BrowserBindings.AbortSignal.aborted(signal) {
      SidebarLogic.updateProgress(~dispatch, 0.0, "Cancelled", false, "")
      NotificationManager.dispatch({
        id: "save-cancelled-notification",
        importance: Info,
        context: Operation("sidebar_save"),
        message: "Save Cancelled",
        details: None,
        action: None,
        duration: 5000,
        dismissible: true,
        createdAt: Date.now(),
      })
    } else {
      SidebarLogic.updateProgress(~dispatch, 0.0, "Save Failed", false, "")
    }
  } catch {
  | exn => {
      let (msg, _) = Logger.getErrorDetails(exn)
      SidebarLogic.updateProgress(~dispatch, 0.0, "Error", false, "")
      opIdRef.contents->Option.forEach(id => OperationLifecycle.fail(id, msg))
      NotificationManager.dispatch({
        id: "",
        importance: Error,
        context: Operation("sidebar_save"),
        message: "Save failed: " ++ msg,
        details: None,
        action: None,
        duration: NotificationTypes.defaultTimeoutMs(Error),
        dismissible: true,
        createdAt: Date.now(),
      })
    }
  }
}
