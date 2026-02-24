open Types

let recoverSaveProject = (
  ~getState: unit => state,
  ~dispatch: Actions.action => unit,
  ~subscribe: (state => unit) => unit => unit,
) =>
  (entry: OperationJournal.journalEntry) => {
    let expectedSceneCount = switch JsonCombinators.Json.decode(
      entry.context,
      ProjectUtils.saveRecoveryContextDecoder,
    ) {
    | Ok(decoded) => decoded.sceneCount
    | Error(_) => None
    }

    let hasRecoverableScenes = (candidate: state) => {
      let count = Array.length(
        SceneInventory.getActiveScenes(candidate.inventory, candidate.sceneOrder),
      )
      switch expectedSceneCount {
      | Some(expected) => expected > 0 && count >= expected
      | None => count > 0
      }
    }

    let waitForStateUpdate = () => {
      Promise.make((resolve, _reject) => {
        let unsubscribeRef = ref(() => ())
        let timerId: ref<int> = ref(0)

        let callback = (newState: state) => {
          if hasRecoverableScenes(newState) {
            unsubscribeRef.contents()
            DomBindings.Window.clearTimeout(timerId.contents)
            resolve(newState)
          }
        }

        unsubscribeRef := subscribe(callback)

        timerId := DomBindings.Window.setTimeout(() => {
            unsubscribeRef.contents()
            resolve(getState())
          }, 5000)
      })
    }

    let state = getState()
    Logger.info(
      ~module_="ProjectManager",
      ~message="SAVE_RECOVERY_START",
      ~data=Some({
        "entryId": entry.id,
        "expectedSceneCount": expectedSceneCount->Option.getOr(-1),
        "currentSceneCount": Array.length(
          SceneInventory.getActiveScenes(state.inventory, state.sceneOrder),
        ),
      }),
      (),
    )

    let restorePromise = if hasRecoverableScenes(state) {
      Promise.resolve(Some(state))
    } else {
      PersistenceLayer.checkRecovery()->Promise.then(recovery => {
        switch recovery {
        | Some(session) =>
          Logger.info(
            ~module_="ProjectManager",
            ~message="SAVE_RECOVERY_RESTORE_SESSION",
            ~data=Some({"entryId": entry.id}),
            (),
          )
          dispatch(Actions.LoadProject(session.projectData))
          waitForStateUpdate()->Promise.then(s => Promise.resolve(Some(s)))
        | None =>
          Logger.warn(
            ~module_="ProjectManager",
            ~message="SAVE_RECOVERY_NO_SESSION",
            ~data=Some({"entryId": entry.id}),
            (),
          )
          Promise.resolve(None)
        }
      })
    }

    restorePromise->Promise.then(finalStateOpt => {
      switch finalStateOpt {
      | Some(finalState) =>
        Logger.info(
          ~module_="ProjectManager",
          ~message="SAVE_RECOVERY_RETRY",
          ~data=Some({
            "entryId": entry.id,
            "sceneCount": Array.length(
              SceneInventory.getActiveScenes(finalState.inventory, finalState.sceneOrder),
            ),
          }),
          (),
        )
        ProjectSave.saveProject(finalState)
      | None =>
        NotificationManager.dispatch({
          id: "",
          importance: Warning,
          context: SystemEvent("recovery"),
          message: "Unable to recover interrupted save. Please save again manually.",
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Warning),
          dismissible: true,
          createdAt: Date.now(),
        })
        Promise.resolve(false)
      }
    })
  }
