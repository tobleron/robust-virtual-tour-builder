/* src/systems/Api/ProjectApiSnapshots.res */

open ApiHelpers
open ReBindings

type snapshotSyncResponse = {
  sessionId: string,
  updatedAt: string,
  sceneCount: int,
  hotspotCount: int,
}

type snapshotOrigin =
  | Auto
  | Manual

type snapshotHistoryItem = {
  snapshotId: string,
  createdAt: string,
  tourName: string,
  sceneCount: int,
  hotspotCount: int,
  contentHash: string,
  origin: string,
}

type snapshotRestoreResponse = {
  sessionId: string,
  snapshotId: string,
  projectData: JSON.t,
}

type snapshotAssetSyncResponse = {
  sessionId: string,
  storedFiles: int,
}

let snapshotSyncDecoder = JsonCombinators.Json.Decode.object(field => {
  sessionId: field.required("sessionId", JsonCombinators.Json.Decode.string),
  updatedAt: field.required("updatedAt", JsonCombinators.Json.Decode.string),
  sceneCount: field.required("sceneCount", JsonCombinators.Json.Decode.int),
  hotspotCount: field.required("hotspotCount", JsonCombinators.Json.Decode.int),
})

let snapshotHistoryItemDecoder = JsonCombinators.Json.Decode.object(field => {
  snapshotId: field.required("snapshotId", JsonCombinators.Json.Decode.string),
  createdAt: field.required("createdAt", JsonCombinators.Json.Decode.string),
  tourName: field.required("tourName", JsonCombinators.Json.Decode.string),
  sceneCount: field.required("sceneCount", JsonCombinators.Json.Decode.int),
  hotspotCount: field.required("hotspotCount", JsonCombinators.Json.Decode.int),
  contentHash: field.required("contentHash", JsonCombinators.Json.Decode.string),
  origin: field.required("origin", JsonCombinators.Json.Decode.string),
})

let snapshotRestoreDecoder = JsonCombinators.Json.Decode.object(field => {
  sessionId: field.required("sessionId", JsonCombinators.Json.Decode.string),
  snapshotId: field.required("snapshotId", JsonCombinators.Json.Decode.string),
  projectData: field.required("projectData", JsonCombinators.Json.Decode.id),
})

let snapshotAssetSyncDecoder = JsonCombinators.Json.Decode.object(field => {
  sessionId: field.required("sessionId", JsonCombinators.Json.Decode.string),
  storedFiles: field.required("storedFiles", JsonCombinators.Json.Decode.int),
})

let decodeSnapshotSyncResponse = json => JsonCombinators.Json.decode(json, snapshotSyncDecoder)
let decodeSnapshotHistory = json =>
  JsonCombinators.Json.decode(json, JsonCombinators.Json.Decode.array(snapshotHistoryItemDecoder))
let decodeSnapshotRestoreResponse = json => JsonCombinators.Json.decode(json, snapshotRestoreDecoder)
let decodeSnapshotAssetSyncResponse = json =>
  JsonCombinators.Json.decode(json, snapshotAssetSyncDecoder)

let syncSnapshot = (~sessionId: option<string>=?, ~projectData: JSON.t, ~origin: snapshotOrigin=Auto): Promise.t<
  apiResult<snapshotSyncResponse>,
> => {
  RequestQueue.schedule(() => {
    let body = JsonCombinators.Json.Encode.object([
      (
        "sessionId",
        switch sessionId {
        | Some(id) => JsonCombinators.Json.Encode.string(id)
        | None => JsonCombinators.Json.Encode.null
        },
      ),
      ("projectData", projectData),
      (
        "saveOrigin",
        JsonCombinators.Json.Encode.string(
          switch origin {
          | Auto => "auto"
          | Manual => "manual"
          },
        ),
      ),
    ])

    AuthenticatedClient.requestWithRetry(
      Constants.backendUrl ++ "/api/project/snapshot/sync",
      ~method="POST",
      ~body=AuthenticatedClient.castBody(body),
      (),
    )
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Retry.Success(response, _) =>
        response.json()->Promise.then(
          json =>
            handleJsonDecode(
              ~module_="ProjectApi",
              json,
              decodeSnapshotSyncResponse,
              "SNAPSHOT_SYNC",
              "Snapshot sync failed",
            ),
        )
      | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e =>
      handleError(~module_="ProjectApi", e, "Snapshot sync failed", "SNAPSHOT_SYNC_FAILED")
    )
  })
}

let listProjectSnapshots = (sessionId: string): Promise.t<apiResult<array<snapshotHistoryItem>>> => {
  RequestQueue.schedule(() => {
    AuthenticatedClient.requestWithRetry(
      Constants.backendUrl ++
      "/api/project/dashboard/projects/" ++
      encodeURIComponent(sessionId) ++
      "/snapshots",
      ~method="GET",
      (),
    )
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Retry.Success(response, _) =>
        response.json()->Promise.then(
          json =>
            handleJsonDecode(
              ~module_="ProjectApi",
              json,
              decodeSnapshotHistory,
              "SNAPSHOT_HISTORY",
              "Snapshot history failed",
            ),
        )
      | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e =>
      handleError(~module_="ProjectApi", e, "Snapshot history failed", "SNAPSHOT_HISTORY_FAILED")
    )
  })
}

let restoreProjectSnapshot = (
  ~sessionId: string,
  ~snapshotId: string,
): Promise.t<apiResult<snapshotRestoreResponse>> => {
  RequestQueue.schedule(() => {
    AuthenticatedClient.requestWithRetry(
      Constants.backendUrl ++
      "/api/project/dashboard/projects/" ++
      encodeURIComponent(sessionId) ++
      "/snapshots/" ++
      encodeURIComponent(snapshotId) ++
      "/restore",
      ~method="POST",
      (),
    )
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Retry.Success(response, _) =>
        response.json()->Promise.then(
          json =>
            handleJsonDecode(
              ~module_="ProjectApi",
              json,
              decodeSnapshotRestoreResponse,
              "SNAPSHOT_RESTORE",
              "Snapshot restore failed",
            ),
        )
      | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e =>
      handleError(~module_="ProjectApi", e, "Snapshot restore failed", "SNAPSHOT_RESTORE_FAILED")
    )
  })
}

let syncSnapshotAssets = (~sessionId: string, ~state: Types.state): Promise.t<
  apiResult<snapshotAssetSyncResponse>,
> => {
  let formData = FormData.newFormData()
  FormData.append(formData, "session_id", sessionId)

  let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
  Belt.Array.forEach(activeScenes, scene => {
    switch scene.file {
    | File(f) => FormData.appendWithFilename(formData, "files", f, scene.name)
    | Blob(b) => FormData.appendWithFilename(formData, "files", b, scene.name)
    | Url(_) => ()
    }
  })

  switch state.logo {
  | Some(File(f)) => FormData.appendWithFilename(formData, "files", f, "logo_upload")
  | Some(Blob(b)) => FormData.appendWithFilename(formData, "files", b, "logo_upload")
  | _ => ()
  }

  RequestQueue.schedule(() => {
    AuthenticatedClient.requestWithRetry(
      Constants.backendUrl ++ "/api/project/snapshot/assets",
      ~method="POST",
      ~formData,
      ~dedupeKey="snapshot-assets:" ++ sessionId,
      (),
    )
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Retry.Success(response, _) =>
        response.json()->Promise.then(
          json =>
            handleJsonDecode(
              ~module_="ProjectApi",
              json,
              decodeSnapshotAssetSyncResponse,
              "SNAPSHOT_ASSET_SYNC",
              "Snapshot asset sync failed",
            ),
        )
      | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e =>
      handleError(
        ~module_="ProjectApi",
        e,
        "Snapshot asset sync failed",
        "SNAPSHOT_ASSET_SYNC_FAILED",
      )
    )
  })
}
