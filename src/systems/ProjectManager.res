/* src/systems/ProjectManager.res - Consolidated Project Manager System */

open ReBindings
open Types

// --- TYPES ---

type onProgress = (int, int, string) => unit
type apiError = string

// --- INTERNAL LOGIC ---

module Logic = {
  external asJson: 'a => JSON.t = "%identity"

  let validationReportWrapperDecoder = JsonCombinators.Json.Decode.object(field => {
    field.required("validationReport", JsonParsers.Shared.validationReport)
  })

  let validateProjectStructure = (data: JSON.t): result<JSON.t, apiError> => {
    switch JsonCombinators.Json.decode(data, JsonParsers.Domain.project) {
    | Ok(_) => Ok(data)
    | Error(e) => Error("Invalid project structure: " ++ e)
    }
  }

  let createSavePackage = (state: state, ~signal=?, ~onProgress: option<onProgress>=?): Promise.t<
    result<Blob.t, apiError>,
  > => {
    let progress = (curr, total, msg) => {
      switch onProgress {
      | Some(cb) => cb(curr, total, msg)
      | None => ()
      }
    }
    progress(0, 100, "Preparing metadata...")

    let project: Types.project = {
      tourName: state.tourName,
      scenes: state.scenes,
      inventory: state.inventory,
      sceneOrder: state.sceneOrder,
      lastUsedCategory: state.lastUsedCategory,
      exifReport: state.exifReport,
      sessionId: state.sessionId,
      deletedSceneIds: state.deletedSceneIds,
      timeline: state.timeline,
    }

    let jsonStr = JsonCombinators.Json.stringify(JsonParsers.Encoders.project(project))
    let formData = FormData.newFormData()
    FormData.append(formData, "project_data", jsonStr)

    Belt.Array.forEachWithIndex(state.scenes, (_index, scene) => {
      switch scene.file {
      | File(f) => FormData.appendWithFilename(formData, "files", f, scene.name)
      | Blob(b) => FormData.appendWithFilename(formData, "files", b, scene.name)
      | Url(_) => ()
      }
    })
    state.sessionId->Option.forEach(id => FormData.append(formData, "session_id", id))

    progress(10, 100, "Uploading to backend...")
    RequestQueue.schedule(() => {
      Fetch.fetch(
        Constants.backendUrl ++ "/api/project/save",
        Fetch.requestInit(~method="POST", ~body=formData, ~signal?, ()),
      )
      ->Promise.then(BackendApi.handleResponse)
      ->Promise.then(resultRes => {
        switch resultRes {
        | Ok(res) => Fetch.blob(res)->Promise.then(blob => Promise.resolve(Ok(blob)))
        | Error(msg) => Promise.resolve(Error(msg))
        }
      })
    })
    ->Promise.then(blobResult => {
      switch blobResult {
      | Ok(blob) =>
        progress(100, 100, "Package created!")
        Promise.resolve(Ok(blob))
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(err => {
      let (msg, _) = Logger.getErrorDetails(err)
      Promise.resolve(Error(msg))
    })
  }

  let processLoadedProjectData = (
    resultSessionData: result<(string, JSON.t), apiError>,
    ~loadStartTime: float,
    ~onProgress: option<onProgress>=?,
  ): Promise.t<BackendApi.apiResult<(string, JSON.t)>> => {
    let progress = (curr, total, msg) => {
      switch onProgress {
      | Some(cb) => cb(curr, total, msg)
      | None => ()
      }
    }
    switch resultSessionData {
    | Ok((sessionId, projectData)) =>
      progress(70, 100, "Resolving scenes...")

      // Check validation report
      switch JsonCombinators.Json.decode(projectData, validationReportWrapperDecoder) {
      | Ok(r) =>
        if r.brokenLinksRemoved > 0 {
          EventBus.dispatch(
            ShowNotification(
              "Project loaded. " ++
              Belt.Int.toString(r.brokenLinksRemoved) ++ " broken link(s) removed.",
              #Warning,
              None,
            ),
          )
        }
        if Array.length(r.orphanedScenes) > 0 {
          EventBus.dispatch(
            ShowNotification(
              "Warning: " ++
              Belt.Int.toString(Array.length(r.orphanedScenes)) ++ " orphaned scene(s) detected.",
              #Warning,
              None,
            ),
          )
        }
        r.errors->Belt.Array.forEach(error =>
          EventBus.dispatch(ShowNotification("Error: " ++ error, #Error, None))
        )
      | Error(_) => ()
      }

      switch JsonCombinators.Json.decode(projectData, JsonParsers.Domain.project) {
      | Ok(pd) =>
        let token = Dom.Storage2.localStorage->Dom.Storage2.getItem("auth_token")
        let finalToken = switch token {
        | Some(t) => t
        | None => "dev-token" // Professional fallback for local development automation
        }
        let tokenQuery = "?token=" ++ finalToken

        // Rebuild URLs for all active scenes in the inventory
        let resolvedActiveScenes = if Array.length(pd.sceneOrder) > 0 {
          pd.sceneOrder->Belt.Array.keepMap(id => {
            switch pd.inventory->Belt.Map.String.get(id) {
            | Some({scene, status: Active}) => Some(scene)
            | _ => None
            }
          })
        } else {
          []
        }

        // Failsafe: if inventory-based resolution failed but legacy array has data, use legacy
        let scenesToRebuild = if (
          Array.length(resolvedActiveScenes) == 0 && Array.length(pd.scenes) > 0
        ) {
          pd.scenes
        } else {
          resolvedActiveScenes
        }

        let validScenes = ProjectManagerUrl.rebuildSceneUrls(
          scenesToRebuild,
          ~sessionId,
          ~tokenQuery,
        )

        // Sync valid scenes back into inventory
        let updatedInventory = validScenes->Belt.Array.reduce(pd.inventory, (acc, s) => {
          acc->Belt.Map.String.set(s.id, {Types.scene: s, status: Active})
        })

        // Ensure sceneOrder is populated from validScenes if it was empty
        let finalOrder = if Array.length(pd.sceneOrder) > 0 {
          pd.sceneOrder
        } else {
          validScenes->Belt.Array.map(s => s.id)
        }

        let loadedProject: Types.project = {
          ...pd,
          scenes: validScenes,
          inventory: updatedInventory,
          sceneOrder: finalOrder,
        }

        progress(100, 100, "Project Loaded!")
        Logger.endOperation(
          ~module_="ProjectManager",
          ~operation="PROJECT_LOAD",
          ~data=Some({
            "sceneCount": Array.length(validScenes),
            "durationMs": Date.now() -. loadStartTime,
          }),
          (),
        )
        Promise.resolve(Ok((sessionId, JsonParsers.Encoders.project(loadedProject))))
      | Error(e) => Promise.resolve(Error("Failed to parse project data: " ++ e))
      }

    | Error(msg) => Promise.resolve(Error(msg))
    }
  }

  let loadProjectZip = (zipFile: File.t, ~onProgress: option<onProgress>=?) => {
    let progress = (curr, total, msg) => {
      switch onProgress {
      | Some(cb) => cb(curr, total, msg)
      | None => ()
      }
    }
    progress(0, 100, "Uploading project...")
    let loadStartTime = Date.now()
    Logger.startOperation(
      ~module_="ProjectManager",
      ~operation="PROJECT_LOAD",
      ~data=Some({"filename": File.name(zipFile), "size": File.size(zipFile)}),
      (),
    )

    BackendApi.importProject(zipFile)
    ->Promise.then(resultRes => {
      switch resultRes {
      | Ok(response) =>
        progress(50, 100, "Processing response...")
        validateProjectStructure(response.projectData)
        ->Belt.Result.map(pd => (response.sessionId, pd))
        ->Promise.resolve
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.then(resultSessionData =>
      processLoadedProjectData(resultSessionData, ~loadStartTime, ~onProgress?)
    )
  }
}

// --- FACADE ---

let saveProject = (state: state, ~signal=?, ~onProgress: option<onProgress>=?) => {
  if Array.length(state.scenes) == 0 {
    Promise.resolve(false)
  } else {
    OperationJournal.startOperation(
      ~operation="SaveProject",
      ~context=Logic.asJson({
        "sceneCount": Array.length(state.scenes),
        "tourName": state.tourName,
      }),
      ~retryable=true,
    )->Promise.then(journalId => {
      let tourName = if state.tourName == "" {
        "Virtual_Tour"
      } else {
        state.tourName
      }
      let safeName = String.replaceRegExp(tourName, /[^a-z0-9]/gi, "_")->String.toLowerCase
      let dateParts = String.split(Date.toISOString(Date.make()), "T")
      let dateStr = Belt.Array.get(dateParts, 0)->Option.getOr("unknown_date")
      let filename =
        "Saved_RMX_" ++ safeName ++ "_v" ++ Version.version ++ "_" ++ dateStr ++ ".vt.zip"

      let useFileHandle = %raw(`typeof window.showSaveFilePicker !== 'undefined'`)
      let handlePromise = if useFileHandle {
        DownloadSystem.getFileHandle(filename, "application/zip")
        ->Promise.then(h => Promise.resolve(Some(h)))
        ->Promise.catch(exn => {
          let (msg, _) = Logger.getErrorDetails(exn)
          if String.includes(msg, "AbortError") {
            Promise.reject(exn)
          } else {
            Promise.resolve(None)
          }
        })
      } else {
        Promise.resolve(None)
      }

      let saveStartTime = Date.now()
      handlePromise
      ->Promise.then(fileHandle => {
        // Progress starts AFTER the file handle (confirmation) is received
        let progress = (curr, total, msg) => {
          switch onProgress {
          | Some(cb) => cb(curr, total, msg)
          | None => ()
          }
        }
        progress(0, 100, "Initializing save...")

        Logic.createSavePackage(state, ~signal?, ~onProgress?)->Promise.then(
          resultRes => {
            switch resultRes {
            | Ok(blob) =>
              if useFileHandle {
                switch fileHandle {
                | Some(h) =>
                  DownloadSystem.writeFileToHandle(h, blob)->Promise.then(
                    () => Promise.resolve(true),
                  )
                | None =>
                  // This can only happen if useFileHandle was true but handle was skipped (not AbortError)
                  DownloadSystem.saveBlob(blob, filename)
                  Promise.resolve(true)
                }
              } else {
                DownloadSystem.saveBlob(blob, filename)
                Promise.resolve(true)
              }->Promise.then(
                success => {
                  if success {
                    OperationJournal.completeOperation(journalId)->Promise.then(
                      () => {
                        Logger.endOperation(
                          ~module_="ProjectManager",
                          ~operation="PROJECT_SAVE",
                          ~data=Some({"durationMs": Date.now() -. saveStartTime}),
                          (),
                        )
                        Promise.resolve(success)
                      },
                    )
                  } else {
                    OperationJournal.failOperation(
                      journalId,
                      "Save failed during file write",
                    )->Promise.then(() => Promise.resolve(success))
                  }
                },
              )
            | Error(msg) =>
              if String.includes(msg, "AbortError") {
                OperationJournal.updateStatus(journalId, Cancelled)->Promise.then(
                  () => Promise.resolve(false),
                )
              } else {
                OperationJournal.failOperation(journalId, msg)->Promise.then(
                  () => Promise.resolve(false),
                )
              }
            }
          },
        )
      })
      ->Promise.catch(exn => {
        let (msg, _) = Logger.getErrorDetails(exn)
        if String.includes(msg, "AbortError") {
          OperationJournal.updateStatus(journalId, Cancelled)->Promise.then(
            () => {
              Logger.info(~module_="ProjectManager", ~message="SAVE_CANCELLED_PICKER", ())
              Promise.resolve(false)
            },
          )
        } else {
          OperationJournal.failOperation(journalId, msg)->Promise.then(
            () => {
              Logger.error(
                ~module_="ProjectManager",
                ~message="SAVE_FAILED",
                ~data={"error": msg},
                (),
              )
              Promise.resolve(false)
            },
          )
        }
      })
    })
  }
}

let recoverSaveProject = (_entry: OperationJournal.journalEntry) => {
  let waitForStateUpdate = () => {
    Promise.make((resolve, _reject) => {
      let unsubscribeRef = ref(_ => ())
      let callback = (newState: Types.state) => {
        if Array.length(newState.scenes) > 0 {
          unsubscribeRef.contents()
          resolve(newState)
        }
      }

      unsubscribeRef := GlobalStateBridge.subscribe(callback)

      // Safety timeout
      let _ = setTimeout(() => {
        unsubscribeRef.contents()
        resolve(GlobalStateBridge.getState())
      }, 5000)
    })
  }

  let state = GlobalStateBridge.getState()

  let restorePromise = if Array.length(state.scenes) > 0 {
    Promise.resolve(Some(state))
  } else {
    PersistenceLayer.checkRecovery()->Promise.then(recovery => {
      switch recovery {
      | Some(session) =>
        GlobalStateBridge.dispatch(Actions.LoadProject(session.projectData))
        waitForStateUpdate()->Promise.then(s => Promise.resolve(Some(s)))
      | None => Promise.resolve(None)
      }
    })
  }

  restorePromise->Promise.then(finalStateOpt => {
    switch finalStateOpt {
    | Some(finalState) => saveProject(finalState)
    | None => Promise.resolve(false)
    }
  })
}

let loadProject = (zipFile: File.t, ~onProgress: option<onProgress>=?): Promise.t<
  BackendApi.apiResult<(string, JSON.t)>,
> => {
  Logic.loadProjectZip(zipFile, ~onProgress?)
}
