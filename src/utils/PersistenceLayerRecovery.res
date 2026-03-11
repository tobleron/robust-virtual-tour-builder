/* src/utils/PersistenceLayerRecovery.res */

open IdbBindings

type serializedSession = PersistenceLayerPayload.serializedSession = {
  version: int,
  timestamp: float,
  projectData: JSON.t,
}

external asJson: unknown => JSON.t = "%identity"

let clearSession = (~legacyKey: string, ~manifestKey: string, ~sliceKey: string => string) => {
  let _ = del(legacyKey)
  let _ = del(manifestKey)
  let _ = del(sliceKey("inventory"))
  let _ = del(sliceKey("sceneOrder"))
  let _ = del(sliceKey("timeline"))
  let _ = del(sliceKey("metadata"))
}

let checkIncrementalRecovery = (
  ~manifestKey: string,
  ~sliceKey: string => string,
  ~currentSchemaVersion: int,
): Promise.t<option<serializedSession>> =>
  get(manifestKey)->Promise.then(manifestItem => {
    let manifestOpt =
      manifestItem
      ->Nullable.toOption
      ->Option.flatMap(raw => PersistenceLayerPayload.decodeManifest(asJson(raw)))
    switch manifestOpt {
    | Some(manifest) =>
      let loadSlice = (name: string) =>
        get(sliceKey(name))->Promise.then(sliceItem =>
          Promise.resolve(sliceItem->Nullable.toOption->Option.map(asJson))
        )

      Promise.all([
        loadSlice("inventory"),
        loadSlice("sceneOrder"),
        loadSlice("timeline"),
        loadSlice("metadata"),
      ])->Promise.then(sliceResults => {
        let inventoryJson =
          Belt.Array.getExn(sliceResults, 0)->Option.flatMap(
            json => PersistenceLayerPayload.extractFromSlice(json, "inventory"),
          )
        let sceneOrderJson =
          Belt.Array.getExn(sliceResults, 1)->Option.flatMap(
            json => PersistenceLayerPayload.extractFromSlice(json, "sceneOrder"),
          )
        let timelineJson =
          Belt.Array.getExn(sliceResults, 2)->Option.flatMap(
            json => PersistenceLayerPayload.extractFromSlice(json, "timeline"),
          )
        let metadata =
          Belt.Array.getExn(sliceResults, 3)->Option.flatMap(
            PersistenceLayerPayload.decodeMetadataSlice,
          )

        switch (inventoryJson, sceneOrderJson, timelineJson, metadata) {
        | (Some(inventory), Some(sceneOrder), Some(timeline), Some(meta)) =>
          Promise.resolve(
            Some({
              version: currentSchemaVersion,
              timestamp: manifest.timestamp,
              projectData: PersistenceLayerPayload.reconstructProjectJson(
                ~inventory,
                ~sceneOrder,
                ~timeline,
                ~metadata=meta,
              ),
            }),
          )
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
  })

let checkLegacyRecovery = (~legacyKey: string, ~currentSchemaVersion: int): Promise.t<
  option<serializedSession>,
> =>
  get(legacyKey)->Promise.then(item => {
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
          switch PersistenceLayerPayload.normalizeProjectData(savedEnvelope.projectData) {
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
      | Error(e) =>
        Logger.warnWithAppError(
          ~module_="Persistence",
          ~message="Corrupt autosave found (decode failed)",
          ~appError=SharedTypes.ValidationError({
            message: e,
            field: Some("autosave_payload"),
          }),
          ~operationContext="persistence_recovery",
          (),
        )
        Promise.resolve(None)
      }
    | None => Promise.resolve(None)
    }
  })

let checkRecovery = (
  ~manifestKey: string,
  ~legacyKey: string,
  ~sliceKey: string => string,
  ~currentSchemaVersion: int,
) => {
  Logger.info(~module_="Persistence", ~message="CHECK_RECOVERY_START", ())
  checkIncrementalRecovery(
    ~manifestKey,
    ~sliceKey,
    ~currentSchemaVersion,
  )->Promise.then(incremental => {
    switch incremental {
    | Some(v) => Promise.resolve(Some(v))
    | None => checkLegacyRecovery(~legacyKey, ~currentSchemaVersion)
    }
  })
}
