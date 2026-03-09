/* src/utils/PersistenceLayerSave.res */

open IdbBindings
open Types

type preparedSave = {
  changedSliceNames: array<(string, JSON.t)>,
  signatures: Dict.t<string>,
  timestamp: float,
  legacyPayload: JSON.t,
  manifestJson: JSON.t,
}

let prepareIncrementalSave = (
  ~state: state,
  ~currentSchemaVersion: int,
  ~previousSignatures: Dict.t<string>,
): preparedSave => {
  let projectData = PersistenceLayerPayload.buildProjectData(state)
  let slices = PersistenceLayerPayload.buildSlices(state)
  let signatures = PersistenceLayerPayload.buildSignatures(slices)
  let changedSliceNames = PersistenceLayerPayload.collectChangedSlices(
    ~slices,
    ~previousSignatures,
  )
  let timestamp = Date.now()
  let legacyPayload = JsonParsers.Encoders.persistedSession(
    ~version=currentSchemaVersion,
    ~timestamp,
    ~projectData,
  )
  let manifest =
    PersistenceLayerPayload.buildManifest(~version=currentSchemaVersion, ~timestamp, ~slices)
  let manifestJson = PersistenceLayerPayload.buildManifestJson(manifest)
  {changedSliceNames, signatures, timestamp, legacyPayload, manifestJson}
}

let writeChangedSlices = (
  ~changedSliceNames: array<(string, JSON.t)>,
  ~sliceKey: string => string,
): Promise.t<unit> =>
  changedSliceNames->Belt.Array.reduce(Promise.resolve(), (acc, (name, json)) =>
    acc->Promise.then(_ => set(sliceKey(name), json)->Promise.then(_ => Promise.resolve()))
  )

let finalizeSuccessfulSave = (
  ~state: state,
  ~signatures: Dict.t<string>,
  ~timestamp: float,
  ~currentSchemaVersion: int,
  ~changedSliceNames: array<(string, JSON.t)>,
  ~activeSceneCount: int,
  ~lastSavedRevision: ref<int>,
  ~lastSliceSignatureRef: ref<Dict.t<string>>,
): Promise.t<unit> => {
  lastSavedRevision := state.structuralRevision
  lastSliceSignatureRef := signatures
  Logger.debug(
    ~module_="Persistence",
    ~message="Auto-saved session via incremental IndexedDB slices",
    ~data={
      "timestamp": timestamp,
      "scenes": activeSceneCount,
      "version": currentSchemaVersion,
      "changedSlices": changedSliceNames->Belt.Array.map(((name, _)) => name),
    },
    (),
  )
  Promise.resolve()
}

let handleSaveFailure = (e: exn): Promise.t<unit> => {
  Logger.errorWithAppError(
    ~module_="Persistence",
    ~message="Auto-save failed",
    ~appError=SharedTypes.InternalError({
      message: "IndexedDB autosave failed",
      code: None,
      retryable: true,
    }),
    ~operationContext="persistence_autosave",
    ~data=JsonCombinators.Json.Encode.object([("error", Logger.castToJson(e))]),
    (),
  )
  NotificationManager.dispatch({
    id: "",
    importance: Error,
    context: SystemEvent("persistence"),
    message: "Auto-save failed! Please backup your data.",
    details: None,
    action: None,
    duration: NotificationTypes.defaultTimeoutMs(Error),
    dismissible: true,
    createdAt: Date.now(),
  })
  Promise.resolve()
}
