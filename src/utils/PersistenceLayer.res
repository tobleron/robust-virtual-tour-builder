/* src/utils/PersistenceLayer.res */

open IdbBindings
open Types

type serializedSession = PersistenceLayerPayload.serializedSession = {
  version: int,
  timestamp: float,
  projectData: JSON.t,
}

type sliceManifest = PersistenceLayerPayload.sliceManifest = {
  version: int,
  timestamp: float,
  slices: array<string>,
}

type logoSlice = PersistenceLayerPayload.logoSlice = {
  kind: string,
  url: option<string>,
}

type metadataSliceDecoded = PersistenceLayerPayload.metadataSliceDecoded = {
  tourName: string,
  lastUsedCategory: string,
  sessionId: option<string>,
  nextSceneSequenceId: int,
  logo: option<logoSlice>,
}

type autosaveCostStats = PersistenceLayerStats.autosaveCostStats = {
  sampleCount: int,
  lastMs: float,
  averageMs: float,
  maxMs: float,
  overTargetCount: int,
}

let key = "autosave_session_latest" // Legacy monolithic payload for compatibility fallback.
let manifestKey = "autosave_session_manifest_v2"
let sliceKeyPrefix = "autosave_session_slice_"
let debounceMs = 2000
let currentSchemaVersion = 2
let coalesceMs = 500
let autosaveCostTargetMs = 10.0
let autosaveCostWindowSize = 30

@val external requestIdleCallback: (unit => unit) => int = "requestIdleCallback"
@val external cancelIdleCallback: int => unit = "cancelIdleCallback"
@val external structuredCloneAny: 'a => 'a = "structuredClone"

let stateGetterRef: ref<unit => state> = ref(() => State.initialState)
let lastSaveTimeout = ref(None)
let lastSavedRevision = ref(-1)
let beforeUnloadListener: ref<option<DomBindings.Dom.event => unit>> = ref(None)
let subscriberRef: ref<option<unit => unit>> = ref(None)
let lastQueuedAtMs = ref(0.0)
let pendingStateRef: ref<option<state>> = ref(None)
let lastSliceSignatureRef: ref<Dict.t<string>> = ref(Dict.make())
let performSaveRef: ref<state => unit> = ref(_ => ())
let autosaveCostSamplesRef: ref<array<float>> = ref([])

let sliceKey = (name: string) => sliceKeyPrefix ++ name

let encodeMetadataSlice = (state: state): JSON.t => {
  PersistenceLayerPayload.encodeMetadataSlice(state)
}

let signatureOfJson = (value: JSON.t): string => JsonCombinators.Json.stringify(value)

let recordAutosaveCost = (~durationMs: float, ~changedSlices: int, ~sceneCount: int) => {
  PersistenceLayerStats.recordAutosaveCost(
    ~samplesRef=autosaveCostSamplesRef,
    ~durationMs,
    ~changedSlices,
    ~sceneCount,
    ~targetMs=autosaveCostTargetMs,
    ~windowSize=autosaveCostWindowSize,
  )
}

let getAutosaveCostStats = (): autosaveCostStats => {
  PersistenceLayerStats.buildAutosaveCostStats(
    ~samples=autosaveCostSamplesRef.contents,
    ~targetMs=autosaveCostTargetMs,
  )
}

let queueIncrementalSave = (state: state) => {
  let clonedState = try {
    structuredCloneAny(state)
  } catch {
  | _ => state
  }
  pendingStateRef := Some(clonedState)
  lastQueuedAtMs := Date.now()
}

let rec processQueuedSave = () => {
  let now = Date.now()
  let elapsed = now -. lastQueuedAtMs.contents
  if elapsed < Float.fromInt(coalesceMs) {
    let waitMs = coalesceMs - Belt.Int.fromFloat(elapsed)
    ignore(setTimeout(processQueuedSave, waitMs))
  } else {
    switch pendingStateRef.contents {
    | Some(queuedState) =>
      pendingStateRef := None
      try {
        ignore(requestIdleCallback(() => performSaveRef.contents(queuedState)))
      } catch {
      | _ =>
        let _ = Promise.resolve()->Promise.then(_ => {
          performSaveRef.contents(queuedState)
          Promise.resolve()
        })
      }
    | None => ()
    }
  }
}

let normalizeProjectData = (projectData: JSON.t): option<JSON.t> => {
  PersistenceLayerPayload.normalizeProjectData(projectData)
}

let performSave = (state: Types.state) => {
  let autosaveStartedAt = Date.now()
  let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
  let activeSceneCount = Array.length(activeScenes)
  let hasContent = activeSceneCount > 0 || state.tourName != "Tour Name"

  if hasContent {
    let prepared = PersistenceLayerSave.prepareIncrementalSave(
      ~state,
      ~currentSchemaVersion,
      ~previousSignatures=lastSliceSignatureRef.contents,
    )

    recordAutosaveCost(
      ~durationMs=Date.now() -. autosaveStartedAt,
      ~changedSlices=Belt.Array.length(prepared.changedSliceNames),
      ~sceneCount=activeSceneCount,
    )

    let _ =
      PersistenceLayerSave.writeChangedSlices(
        ~changedSliceNames=prepared.changedSliceNames,
        ~sliceKey,
      )
      ->Promise.then(_ => set(manifestKey, prepared.manifestJson))
      ->Promise.then(_ => set(key, prepared.legacyPayload))
      ->Promise.then(_ =>
        PersistenceLayerSave.finalizeSuccessfulSave(
          ~state,
          ~signatures=prepared.signatures,
          ~timestamp=prepared.timestamp,
          ~currentSchemaVersion,
          ~changedSliceNames=prepared.changedSliceNames,
          ~activeSceneCount,
          ~lastSavedRevision,
          ~lastSliceSignatureRef,
        )
      )
      ->Promise.catch(PersistenceLayerSave.handleSaveFailure)
  }
}
let _ = performSaveRef := performSave

let handleStateChange = (state: state) => {
  let prefs = PersistencePreferences.get()
  let localAutosaveEnabled = switch prefs.autosaveMode {
  | Off => false
  | LocalOnly | Hybrid => true
  }

  if localAutosaveEnabled && state.structuralRevision > lastSavedRevision.contents {
    switch lastSaveTimeout.contents {
    | Some(id) => clearTimeout(id)
    | None => ()
    }

    queueIncrementalSave(state)
    lastSaveTimeout := Some(setTimeout(() => processQueuedSave(), debounceMs))
  }
}

let notifyStateChange = (state: state) => handleStateChange(state)

let flushNow = (~state: state, ~reason: string) => {
  let prefs = PersistencePreferences.get()
  let localAutosaveEnabled = switch prefs.autosaveMode {
  | Off => false
  | LocalOnly | Hybrid => true
  }

  if localAutosaveEnabled {
    switch lastSaveTimeout.contents {
    | Some(id) =>
      clearTimeout(id)
      lastSaveTimeout := None
    | None => ()
    }
    pendingStateRef := None
    Logger.info(
      ~module_="Persistence",
      ~message="FORCED_LOCAL_FLUSH",
      ~data=Some(Logger.castToJson({"reason": reason})),
      (),
    )
    performSave(state)
  }
}

let initSubscriber = (
  ~getState: unit => state,
  ~onChange: state => unit,
  ~subscribe: (state => unit) => unit => unit,
) => {
  Logger.info(~module_="Persistence", ~message="Initializing Persistence Layer", ())

  stateGetterRef := getState

  beforeUnloadListener.contents->Option.forEach(listener =>
    DomBindings.Window.removeEventListener("beforeunload", listener)
  )

  let listener = event => {
    OperationJournal.flushAllInFlight()

    let state = stateGetterRef.contents()
    ignore(event)

    let prefs = PersistencePreferences.get()
    let localAutosaveEnabled = switch prefs.autosaveMode {
    | Off => false
    | LocalOnly | Hybrid => true
    }

    switch (localAutosaveEnabled, lastSaveTimeout.contents) {
    | (true, Some(_)) => performSave(state)
    | _ => ()
    }
  }

  beforeUnloadListener := Some(listener)
  DomBindings.Window.addEventListener("beforeunload", listener)

  subscriberRef.contents->Option.forEach(f => f())
  subscriberRef := Some(subscribe(onChange))
}

let clearSession = () => {
  PersistenceLayerRecovery.clearSession(~legacyKey=key, ~manifestKey, ~sliceKey)
}

let decodeManifest = (json: JSON.t): option<sliceManifest> => {
  PersistenceLayerPayload.decodeManifest(json)
}

let extractFromSlice = (_json: JSON.t, _key: string): option<JSON.t> => {
  PersistenceLayerPayload.extractFromSlice(_json, _key)
}

let decodeMetadataSlice = (json: JSON.t): option<metadataSliceDecoded> => {
  PersistenceLayerPayload.decodeMetadataSlice(json)
}

let checkRecovery = () => {
  PersistenceLayerRecovery.checkRecovery(
    ~manifestKey,
    ~legacyKey=key,
    ~sliceKey,
    ~currentSchemaVersion,
  )
}
