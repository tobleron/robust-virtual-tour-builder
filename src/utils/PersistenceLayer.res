/* src/utils/PersistenceLayer.res */

open IdbBindings
open Types

type serializedSession = {
  version: int,
  timestamp: float,
  projectData: JSON.t,
}

type sliceManifest = {
  version: int,
  timestamp: float,
  slices: array<string>,
}

type logoSlice = {
  kind: string,
  url: option<string>,
}

type metadataSliceDecoded = {
  tourName: string,
  lastUsedCategory: string,
  sessionId: option<string>,
  nextSceneSequenceId: int,
  logo: option<logoSlice>,
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

external asJson: unknown => JSON.t = "%identity"

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

type autosaveCostStats = {
  sampleCount: int,
  lastMs: float,
  averageMs: float,
  maxMs: float,
  overTargetCount: int,
}

let sliceKey = (name: string) => sliceKeyPrefix ++ name

let encodeMetadataSlice = (state: state): JSON.t =>
  JsonCombinators.Json.Encode.object([
    ("tourName", JsonCombinators.Json.Encode.string(state.tourName)),
    (
      "lastUsedCategory",
      JsonCombinators.Json.Encode.string(state.lastUsedCategory),
    ),
    (
      "sessionId",
      switch state.sessionId {
      | Some(id) => JsonCombinators.Json.Encode.string(id)
      | None => JsonCombinators.Json.Encode.null
      },
    ),
    ("nextSceneSequenceId", JsonCombinators.Json.Encode.int(state.nextSceneSequenceId)),
    (
      "logo",
      switch state.logo {
      | Some(Blob(_)) => JsonCombinators.Json.Encode.object([("kind", JsonCombinators.Json.Encode.string("blob"))])
      | Some(File(_)) => JsonCombinators.Json.Encode.object([("kind", JsonCombinators.Json.Encode.string("file"))])
      | Some(Url(url)) => JsonCombinators.Json.Encode.object([
          ("kind", JsonCombinators.Json.Encode.string("url")),
          ("url", JsonCombinators.Json.Encode.string(url)),
        ])
      | None => JsonCombinators.Json.Encode.null
      },
    ),
  ])

let signatureOfJson = (value: JSON.t): string => JsonCombinators.Json.stringify(value)

let recordAutosaveCost = (~durationMs: float, ~changedSlices: int, ~sceneCount: int) => {
  let nextSamples = Belt.Array.concat(autosaveCostSamplesRef.contents, [durationMs])
  autosaveCostSamplesRef := if Belt.Array.length(nextSamples) > autosaveCostWindowSize {
    Belt.Array.sliceToEnd(nextSamples, 1)
  } else {
    nextSamples
  }

  let sampleCount = Belt.Array.length(autosaveCostSamplesRef.contents)
  let totalMs = autosaveCostSamplesRef.contents->Belt.Array.reduce(0.0, (acc, item) => acc +. item)
  let averageMs = if sampleCount > 0 {totalMs /. Float.fromInt(sampleCount)} else {0.0}
  let maxMs = autosaveCostSamplesRef.contents->Belt.Array.reduce(0.0, (acc, item) => if item > acc {item} else {acc})
  let overTargetCount =
    autosaveCostSamplesRef.contents->Belt.Array.keep(item => item > autosaveCostTargetMs)->Belt.Array.length

  Logger.debug(
    ~module_="Persistence",
    ~message="AUTOSAVE_MAIN_THREAD_COST",
    ~data={
      "durationMs": durationMs,
      "changedSlices": changedSlices,
      "sceneCount": sceneCount,
      "targetMs": autosaveCostTargetMs,
      "windowSampleCount": sampleCount,
      "windowAverageMs": averageMs,
      "windowMaxMs": maxMs,
      "windowOverTargetCount": overTargetCount,
    },
    (),
  )

  if durationMs > autosaveCostTargetMs {
    Logger.warn(
      ~module_="Persistence",
      ~message="AUTOSAVE_MAIN_THREAD_COST_ABOVE_TARGET",
      ~data={
        "durationMs": durationMs,
        "targetMs": autosaveCostTargetMs,
      },
      (),
    )
  }
}

let getAutosaveCostStats = (): autosaveCostStats => {
  let sampleCount = Belt.Array.length(autosaveCostSamplesRef.contents)
  let lastMs = switch Belt.Array.get(autosaveCostSamplesRef.contents, sampleCount - 1) {
  | Some(value) => value
  | None => 0.0
  }
  let totalMs = autosaveCostSamplesRef.contents->Belt.Array.reduce(0.0, (acc, item) => acc +. item)
  let averageMs = if sampleCount > 0 {totalMs /. Float.fromInt(sampleCount)} else {0.0}
  let maxMs = autosaveCostSamplesRef.contents->Belt.Array.reduce(0.0, (acc, item) => if item > acc {item} else {acc})
  let overTargetCount =
    autosaveCostSamplesRef.contents->Belt.Array.keep(item => item > autosaveCostTargetMs)->Belt.Array.length
  {sampleCount, lastMs, averageMs, maxMs, overTargetCount}
}

let queueIncrementalSave = (state: state) => {
  let clonedState =
    try {
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
  switch JsonCombinators.Json.decode(projectData, JsonParsers.Domain.project) {
  | Ok(project) => Some(JsonParsers.Encoders.project(project))
  | Error(e) =>
    Logger.warn(
      ~module_="Persistence",
      ~message="Persisted project payload failed validation",
      ~data={"error": e},
      (),
    )
    None
  }
}

let performSave = (state: Types.state) => {
  let autosaveStartedAt = Date.now()
  /* Only save if we have scenes or a project name that differs from default */
  let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
  let hasContent = Array.length(activeScenes) > 0 || state.tourName != "Tour Name"

  if hasContent {
    let project: Types.project = {
      tourName: state.tourName,
      inventory: state.inventory,
      sceneOrder: state.sceneOrder,
      lastUsedCategory: state.lastUsedCategory,
      exifReport: state.exifReport,
      sessionId: state.sessionId,
      timeline: state.timeline,
      logo: state.logo,
      marketingComment: state.marketingComment,
      marketingPhone1: state.marketingPhone1,
      marketingPhone2: state.marketingPhone2,
      marketingForRent: state.marketingForRent,
      marketingForSale: state.marketingForSale,
      nextSceneSequenceId: state.nextSceneSequenceId,
    }

    let projectData = JsonParsers.Encoders.project(project)
    let inventorySlice = JsonCombinators.Json.Encode.object([
      ("inventory", JsonParsers.Encoders.inventory(state.inventory)),
    ])
    let sceneOrderSlice = JsonCombinators.Json.Encode.object([
      ("sceneOrder", JsonCombinators.Json.Encode.array(JsonCombinators.Json.Encode.string)(state.sceneOrder)),
    ])
    let timelineSlice = JsonCombinators.Json.Encode.object([
      ("timeline", JsonCombinators.Json.Encode.array(JsonParsers.Encoders.timelineItem)(state.timeline)),
    ])
    let metadataSlice = encodeMetadataSlice(state)

    let slices = [
      ("inventory", inventorySlice),
      ("sceneOrder", sceneOrderSlice),
      ("timeline", timelineSlice),
      ("metadata", metadataSlice),
    ]

    let signatures = Dict.make()
    slices->Belt.Array.forEach(((name, json)) => {
      Dict.set(signatures, name, signatureOfJson(json))
    })

    let changedSliceNames = slices
    ->Belt.Array.keepMap(((name, json)) => {
      let newSig = Dict.get(signatures, name)->Option.getOr("")
      let oldSig = Dict.get(lastSliceSignatureRef.contents, name)->Option.getOr("")
      if newSig != oldSig {
        Some((name, json))
      } else {
        None
      }
    })

    let timestamp = Date.now()

    let legacyPayload = JsonParsers.Encoders.persistedSession(
      ~version=currentSchemaVersion,
      ~timestamp,
      ~projectData,
    )
    let manifest: sliceManifest = {
      version: currentSchemaVersion,
      timestamp,
      slices: slices->Belt.Array.map(((name, _)) => name),
    }
    let manifestJson = JsonCombinators.Json.Encode.object([
      ("version", JsonCombinators.Json.Encode.int(manifest.version)),
      ("timestamp", JsonCombinators.Json.Encode.float(manifest.timestamp)),
      ("slices", JsonCombinators.Json.Encode.array(JsonCombinators.Json.Encode.string)(manifest.slices)),
    ])

    let writeSlicesPromise = changedSliceNames
    ->Belt.Array.reduce(Promise.resolve(), (acc, (name, json)) =>
      acc->Promise.then(_ => set(sliceKey(name), json)->Promise.then(_ => Promise.resolve()))
    )

    recordAutosaveCost(
      ~durationMs=Date.now() -. autosaveStartedAt,
      ~changedSlices=Belt.Array.length(changedSliceNames),
      ~sceneCount=Array.length(activeScenes),
    )

    let _ = writeSlicesPromise
      ->Promise.then(_ => set(manifestKey, manifestJson))
      ->Promise.then(_ => set(key, legacyPayload))
      ->Promise.then(_ => {
        lastSavedRevision := state.structuralRevision
        lastSliceSignatureRef := signatures
        Logger.debug(
          ~module_="Persistence",
          ~message="Auto-saved session via incremental IndexedDB slices",
          ~data={
            "timestamp": timestamp,
            "scenes": Array.length(activeScenes),
            "version": currentSchemaVersion,
            "changedSlices": changedSliceNames->Belt.Array.map(((name, _)) => name),
          },
          (),
        )
        Promise.resolve()
      })
      ->Promise.catch(e => {
        Logger.error(~module_="Persistence", ~message="Auto-save failed", ~data={"error": e}, ())
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
      })
  }
}
let _ = performSaveRef := performSave

let handleStateChange = (state: state) => {
  if state.structuralRevision > lastSavedRevision.contents {
    switch lastSaveTimeout.contents {
    | Some(id) => clearTimeout(id)
    | None => ()
    }

    queueIncrementalSave(state)
    lastSaveTimeout := Some(setTimeout(() => processQueuedSave(), debounceMs))
  }
}

let notifyStateChange = (state: state) => handleStateChange(state)

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
    // Ensure all in-flight operations are flushed to emergency queue
    OperationJournal.flushAllInFlight()

    let state = stateGetterRef.contents()
    ignore(event)

    switch lastSaveTimeout.contents {
    | Some(_) => performSave(state)
    | None => ()
    }
  }

  beforeUnloadListener := Some(listener)
  DomBindings.Window.addEventListener("beforeunload", listener)

  subscriberRef.contents->Option.forEach(f => f())
  subscriberRef := Some(subscribe(onChange))
}

let clearSession = () => {
  let _ = del(key)
  let _ = del(manifestKey)
  let _ = del(sliceKey("inventory"))
  let _ = del(sliceKey("sceneOrder"))
  let _ = del(sliceKey("timeline"))
  let _ = del(sliceKey("metadata"))
}

let decodeManifest = (json: JSON.t): option<sliceManifest> =>
  switch JsonCombinators.Json.decode(
    json,
    JsonCombinators.Json.Decode.object(field => {
      version: field.required("version", JsonCombinators.Json.Decode.int),
      timestamp: field.required("timestamp", JsonCombinators.Json.Decode.float),
      slices: field.required("slices", JsonCombinators.Json.Decode.array(JsonCombinators.Json.Decode.string)),
    }),
  ) {
  | Ok(v) => Some(v)
  | Error(_) => None
  }

let extractFromSlice = (_json: JSON.t, _key: string): option<JSON.t> =>
  %raw(`(function(json, key){
    if (!json || typeof json !== "object") return undefined;
    return Object.prototype.hasOwnProperty.call(json, key) ? json[key] : undefined;
  })(_json, _key)`)

let decodeMetadataSlice = (json: JSON.t): option<metadataSliceDecoded> =>
  switch JsonCombinators.Json.decode(
    json,
    JsonCombinators.Json.Decode.object(field => {
      tourName: field.required("tourName", JsonCombinators.Json.Decode.string),
      lastUsedCategory: field.required("lastUsedCategory", JsonCombinators.Json.Decode.string),
      sessionId: field.optional("sessionId", JsonCombinators.Json.Decode.string),
      nextSceneSequenceId: field.required("nextSceneSequenceId", JsonCombinators.Json.Decode.int),
      logo: field.optional(
        "logo",
        JsonCombinators.Json.Decode.object((sub): logoSlice => {
          kind: sub.required("kind", JsonCombinators.Json.Decode.string),
          url: sub.optional("url", JsonCombinators.Json.Decode.string),
        }),
      ),
    }),
  ) {
  | Ok(v) =>
    Some({
      tourName: v.tourName,
      lastUsedCategory: v.lastUsedCategory,
      sessionId: v.sessionId,
      nextSceneSequenceId: v.nextSceneSequenceId,
      logo: v.logo,
    })
  | Error(_) => None
  }

let checkRecovery = () => {
  Logger.info(~module_="Persistence", ~message="CHECK_RECOVERY_START", ())
  get(manifestKey)->Promise.then(manifestItem => {
    let manifestOpt = manifestItem->Nullable.toOption->Option.flatMap(raw => decodeManifest(asJson(raw)))
    switch manifestOpt {
    | Some(manifest) =>
      let loadSlice = (name: string) =>
        get(sliceKey(name))->Promise.then(sliceItem => Promise.resolve(sliceItem->Nullable.toOption->Option.map(asJson)))

      Promise.all([
        loadSlice("inventory"),
        loadSlice("sceneOrder"),
        loadSlice("timeline"),
        loadSlice("metadata"),
      ])->Promise.then(sliceResults => {
        let inventoryJson = Belt.Array.getExn(sliceResults, 0)->Option.flatMap(json => extractFromSlice(json, "inventory"))
        let sceneOrderJson = Belt.Array.getExn(sliceResults, 1)->Option.flatMap(json => extractFromSlice(json, "sceneOrder"))
        let timelineJson = Belt.Array.getExn(sliceResults, 2)->Option.flatMap(json => extractFromSlice(json, "timeline"))
        let metadata = Belt.Array.getExn(sliceResults, 3)->Option.flatMap(decodeMetadataSlice)

        switch (inventoryJson, sceneOrderJson, timelineJson, metadata) {
        | (Some(inventory), Some(sceneOrder), Some(timeline), Some(meta)) =>
          let projectJson = JsonCombinators.Json.Encode.object([
            ("tourName", JsonCombinators.Json.Encode.string(meta.tourName)),
            ("inventory", inventory),
            ("sceneOrder", sceneOrder),
            (
              "lastUsedCategory",
              JsonCombinators.Json.Encode.string(meta.lastUsedCategory),
            ),
            (
              "exifReport",
              JsonCombinators.Json.Encode.null,
            ),
            (
              "sessionId",
              switch meta.sessionId {
              | Some(v) => JsonCombinators.Json.Encode.string(v)
              | None => JsonCombinators.Json.Encode.null
              },
            ),
            ("timeline", timeline),
            (
              "logo",
              switch meta.logo {
              | Some({kind, url}) when kind == "url" =>
                JsonCombinators.Json.Encode.object([
                  ("kind", JsonCombinators.Json.Encode.string("url")),
                  ("url", JsonCombinators.Json.Encode.string(url->Option.getOr(""))),
                ])
              | _ => JsonCombinators.Json.Encode.null
              },
            ),
            ("nextSceneSequenceId", JsonCombinators.Json.Encode.int(meta.nextSceneSequenceId)),
          ])

          Promise.resolve(Some({
            version: currentSchemaVersion,
            timestamp: manifest.timestamp,
            projectData: projectJson,
          }))
        | _ =>
          Logger.warn(
            ~module_="Persistence",
            ~message="Incremental autosave reconstruction failed, falling back to legacy payload",
            (),
          )
          Promise.resolve(None)
        }
      })
    | None => Promise.resolve(None)
    }
  })->Promise.then(incremental => {
    switch incremental {
    | Some(v) => Promise.resolve(Some(v))
    | None => get(key)->Promise.then(item => {
    Logger.info(~module_="Persistence", ~message="CHECK_RECOVERY_GOT_ITEM", ())
    switch Nullable.toOption(item) {
    | Some(raw) =>
      let json = asJson(raw)
      switch JsonCombinators.Json.decode(json, JsonParsers.Domain.persistedSession) {
      | Ok(savedEnvelope) =>
        if savedEnvelope.version > currentSchemaVersion {
          Logger.warn(
            ~module_="Persistence",
            ~message="Autosave schema is newer than supported",
            ~data={"version": savedEnvelope.version, "supported": currentSchemaVersion},
            (),
          )
          Promise.resolve(None)
        } else {
          switch normalizeProjectData(savedEnvelope.projectData) {
          | Some(normalizedProjectData) =>
            let migrated: serializedSession = {
              version: currentSchemaVersion,
              timestamp: savedEnvelope.timestamp,
              projectData: normalizedProjectData,
            }
            Promise.resolve(Some(migrated))
          | None => Promise.resolve(None)
          }
        }
      | Error(e) => {
          Logger.warn(
            ~module_="Persistence",
            ~message="Corrupt autosave found (decode failed)",
            ~data={"error": e},
            (),
          )
          Promise.resolve(None)
        }
      }
    | None => Promise.resolve(None)
    }
  })
    }
  })
}
