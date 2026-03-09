// @efficiency-role: state-hook
open Types
open Actions
open ReBindings

@val external setTimeoutMs: (unit => unit, int) => int = "setTimeout"
@val external clearTimeoutMs: int => unit = "clearTimeout"
@val @scope("document") external documentVisibilityState: string = "visibilityState"

type cadencePolicy = {
  idleDelayMs: int,
  burstDelayMs: int,
  maxStalenessMs: int,
  burstThreshold: int,
}

type syncRefs = {
  snapshotTimeoutRef: React.ref<option<int>>,
  lastSnapshotRevisionRef: React.ref<int>,
  lastAssetSyncSignatureRef: React.ref<string>,
  latestStateRef: React.ref<state>,
  dirtySinceMsRef: React.ref<float>,
  lastChangeAtMsRef: React.ref<float>,
  lastServerSyncAtMsRef: React.ref<float>,
  burstChangeCountRef: React.ref<int>,
  syncInFlightRef: React.ref<bool>,
}

let intMax = (a: int, b: int) => if a > b {a} else {b}
let intMin = (a: int, b: int) => if a < b {a} else {b}

let useScheduledServerAutosave = (
  ~state: state,
  ~isProjectLoading: bool,
  ~dispatch: action => unit,
  ~refs: syncRefs,
  ~cadencePolicy: PersistencePreferences.snapshotCadence => cadencePolicy,
  ~canSyncToServer: unit => bool,
  ~localAssetSyncSignature: state => string,
) => {
  React.useEffect2(() => {
    let prefs = PersistencePreferences.get()
    let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
    let canUseServerAutosave = switch prefs.autosaveMode {
    | PersistencePreferences.Hybrid => true
    | PersistencePreferences.Off | PersistencePreferences.LocalOnly => false
    }
    let shouldSync =
      canUseServerAutosave && canSyncToServer() && Array.length(activeScenes) > 0 && !isProjectLoading

    let scheduleSync = (delayMs: int) => {
      switch refs.snapshotTimeoutRef.current {
      | Some(id) => clearTimeoutMs(id)
      | None => ()
      }
      let timeoutId = setTimeoutMs(() => {
        let syncState = refs.latestStateRef.current
        let latestScenes = SceneInventory.getActiveScenes(syncState.inventory, syncState.sceneOrder)
        if refs.syncInFlightRef.current || Array.length(latestScenes) == 0 {
          ()
        } else if syncState.structuralRevision > refs.lastSnapshotRevisionRef.current {
          refs.syncInFlightRef.current = true
          let projectData = ProjectSystem.encodeProjectFromState(syncState)
          let syncPromise = switch syncState.sessionId {
          | Some(id) => Api.ProjectApi.syncSnapshot(~sessionId=id, ~projectData, ~origin=Auto)
          | None => Api.ProjectApi.syncSnapshot(~projectData, ~origin=Auto)
          }
          syncPromise
          ->Promise.then(result => {
            switch result {
            | Ok(syncResult) =>
              refs.lastSnapshotRevisionRef.current = syncState.structuralRevision
              refs.lastServerSyncAtMsRef.current = Date.now()
              refs.dirtySinceMsRef.current = 0.0
              refs.burstChangeCountRef.current = 0
              let assetSignature = localAssetSyncSignature(syncState)
              if assetSignature != "" && assetSignature != refs.lastAssetSyncSignatureRef.current {
                Api.ProjectApi.syncSnapshotAssets(~sessionId=syncResult.sessionId, ~state=syncState)
                ->Promise.then(assetResult => {
                  switch assetResult {
                  | Ok(_) => refs.lastAssetSyncSignatureRef.current = assetSignature
                  | Error(_) => ()
                  }
                  Promise.resolve()
                })
                ->ignore
              }
              switch syncState.sessionId {
              | Some(_) => ()
              | None => dispatch(SetSessionId(syncResult.sessionId))
              }
            | Error(_) => ()
            }
            refs.syncInFlightRef.current = false
            Promise.resolve()
          })
          ->Promise.catch(_ => {
            refs.syncInFlightRef.current = false
            Promise.resolve()
          })
          ->ignore
        }
      }, delayMs)
      refs.snapshotTimeoutRef.current = Some(timeoutId)
    }

    if !shouldSync {
      switch refs.snapshotTimeoutRef.current {
      | Some(id) =>
        clearTimeoutMs(id)
        refs.snapshotTimeoutRef.current = None
      | None => ()
      }
      None
    } else {
      let now = Date.now()
      if refs.dirtySinceMsRef.current == 0.0 {
        refs.dirtySinceMsRef.current = now
        refs.burstChangeCountRef.current = 1
      } else if now -. refs.lastChangeAtMsRef.current < 12000.0 {
        refs.burstChangeCountRef.current = refs.burstChangeCountRef.current + 1
      } else {
        refs.burstChangeCountRef.current = 1
      }
      refs.lastChangeAtMsRef.current = now

      let policy = cadencePolicy(prefs.snapshotCadence)
      let burstDelay =
        if refs.burstChangeCountRef.current >= policy.burstThreshold {
          policy.burstDelayMs
        } else {
          policy.idleDelayMs
        }
      let sinceLastSync = now -. refs.lastServerSyncAtMsRef.current
      let cooldownRemaining = intMax(0, 800 - (sinceLastSync->Belt.Int.fromFloat))
      let maxStalenessRemaining = intMax(
        0,
        policy.maxStalenessMs - (now -. refs.dirtySinceMsRef.current)->Belt.Int.fromFloat,
      )
      let baseDelay = intMax(cooldownRemaining, burstDelay)
      let finalDelay = if maxStalenessRemaining == 0 {250} else {intMin(baseDelay, maxStalenessRemaining)}
      scheduleSync(finalDelay)
      Some(() => ())
    }
  }, (state.structuralRevision, isProjectLoading))
}

let useFlushServerAutosave = (
  ~isProjectLoading: bool,
  ~dispatch: action => unit,
  ~refs: syncRefs,
  ~canSyncToServer: unit => bool,
  ~localAssetSyncSignature: state => string,
) => {
  React.useEffect2(() => {
    let flushServerAutosave = (_event: Dom.event) => {
      let prefs = PersistencePreferences.get()
      let canUseServerAutosave = switch prefs.autosaveMode {
      | PersistencePreferences.Hybrid => true
      | PersistencePreferences.Off | PersistencePreferences.LocalOnly => false
      }
      let flushState = refs.latestStateRef.current
      let activeScenes = SceneInventory.getActiveScenes(flushState.inventory, flushState.sceneOrder)
      if
        canUseServerAutosave &&
        canSyncToServer() &&
        !refs.syncInFlightRef.current &&
        !isProjectLoading &&
        Array.length(activeScenes) > 0 &&
        flushState.structuralRevision > refs.lastSnapshotRevisionRef.current
      {
        let projectData = ProjectSystem.encodeProjectFromState(flushState)
        let syncPromise = switch flushState.sessionId {
        | Some(id) => Api.ProjectApi.syncSnapshot(~sessionId=id, ~projectData, ~origin=Auto)
        | None => Api.ProjectApi.syncSnapshot(~projectData, ~origin=Auto)
        }
        refs.syncInFlightRef.current = true
        syncPromise
        ->Promise.then(result => {
          switch result {
          | Ok(syncResult) =>
            refs.lastSnapshotRevisionRef.current = flushState.structuralRevision
            refs.lastServerSyncAtMsRef.current = Date.now()
            let assetSignature = localAssetSyncSignature(flushState)
            if assetSignature != "" && assetSignature != refs.lastAssetSyncSignatureRef.current {
              Api.ProjectApi.syncSnapshotAssets(~sessionId=syncResult.sessionId, ~state=flushState)
              ->Promise.then(assetResult => {
                switch assetResult {
                | Ok(_) => refs.lastAssetSyncSignatureRef.current = assetSignature
                | Error(_) => ()
                }
                Promise.resolve()
              })
              ->ignore
            }
            switch flushState.sessionId {
            | Some(_) => ()
            | None => dispatch(SetSessionId(syncResult.sessionId))
            }
          | Error(_) => ()
          }
          refs.syncInFlightRef.current = false
          Promise.resolve()
        })
        ->Promise.catch(_ => {
          refs.syncInFlightRef.current = false
          Promise.resolve()
        })
        ->ignore
      }
    }

    let onVisibilityChange = (event: Dom.event) => {
      if documentVisibilityState == "hidden" {
        flushServerAutosave(event)
      }
    }

    DomBindings.Window.addEventListener("pagehide", flushServerAutosave)
    DomBindings.Window.addEventListener("visibilitychange", onVisibilityChange)

    Some(() => {
      DomBindings.Window.removeEventListener("pagehide", flushServerAutosave)
      DomBindings.Window.removeEventListener("visibilitychange", onVisibilityChange)
    })
  }, (isProjectLoading, dispatch))
}
