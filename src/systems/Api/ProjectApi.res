/* src/systems/Api/ProjectApi.res */

open ApiHelpers
open ReBindings

include ProjectImportOrchestrator
external castJson: 'a => JSON.t = "%identity"

type dashboardProject = ProjectApiDashboard.dashboardProject = {
  sessionId: string,
  tourName: string,
  updatedAt: string,
  sceneCount: int,
  hotspotCount: int,
}

let dashboardProjectDecoder = JsonCombinators.Json.Decode.object(field => {
  sessionId: field.required("sessionId", JsonCombinators.Json.Decode.string),
  tourName: field.required("tourName", JsonCombinators.Json.Decode.string),
  updatedAt: field.required("updatedAt", JsonCombinators.Json.Decode.string),
  sceneCount: field.required("sceneCount", JsonCombinators.Json.Decode.int),
  hotspotCount: field.required("hotspotCount", JsonCombinators.Json.Decode.int),
})

type dashboardLoadResponse = ProjectApiDashboard.dashboardLoadResponse = {
  sessionId: string,
  projectData: JSON.t,
}

let dashboardLoadDecoder = JsonCombinators.Json.Decode.object(field => {
  sessionId: field.required("sessionId", JsonCombinators.Json.Decode.string),
  projectData: field.required("projectData", JsonCombinators.Json.Decode.id),
})

type snapshotSyncResponse = ProjectApiSnapshots.snapshotSyncResponse = {
  sessionId: string,
  updatedAt: string,
  sceneCount: int,
  hotspotCount: int,
}

type snapshotOrigin = ProjectApiSnapshots.snapshotOrigin =
  | Auto
  | Manual

type snapshotHistoryItem = ProjectApiSnapshots.snapshotHistoryItem = {
  snapshotId: string,
  createdAt: string,
  tourName: string,
  sceneCount: int,
  hotspotCount: int,
  contentHash: string,
  origin: string,
}

type snapshotRestoreResponse = ProjectApiSnapshots.snapshotRestoreResponse = {
  sessionId: string,
  snapshotId: string,
  projectData: JSON.t,
}

type snapshotAssetSyncResponse = ProjectApiSnapshots.snapshotAssetSyncResponse = {
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

let decodeDashboardProjects = json =>
  JsonCombinators.Json.decode(json, JsonCombinators.Json.Decode.array(dashboardProjectDecoder))
let decodeDashboardLoadResponse = json => JsonCombinators.Json.decode(json, dashboardLoadDecoder)
let decodeSnapshotSyncResponse = json => JsonCombinators.Json.decode(json, snapshotSyncDecoder)
let decodeSnapshotHistory = json => ProjectApiSnapshots.decodeSnapshotHistory(json)
let decodeSnapshotRestoreResponse = json =>
  JsonCombinators.Json.decode(json, snapshotRestoreDecoder)
let decodeSnapshotAssetSyncResponse = json =>
  ProjectApiSnapshots.decodeSnapshotAssetSyncResponse(json)

let saveProject = (sessionId: string, projectData: JSON.t): Promise.t<apiResult<unit>> => {
  let formData = FormData.newFormData()
  FormData.append(formData, "project_data", JsonCombinators.Json.stringify(projectData))
  FormData.append(formData, "session_id", sessionId)

  RequestQueue.schedule(() => {
    AuthenticatedClient.requestWithRetry(
      Constants.backendUrl ++ "/api/project/save",
      ~method="POST",
      ~formData,
      ~dedupeKey="project-save:" ++ sessionId,
      (),
    )
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Retry.Success(_, _) => Promise.resolve(Ok())
      | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e => handleError(~module_="ProjectApi", e, "Project save failed", "SAVE_ERROR"))
  })
}

let calculatePath = (~signal: option<ReBindings.AbortSignal.t>=?, payload: pathRequest): Promise.t<
  apiResult<array<step>>,
> => {
  RequestQueue.schedule(() => {
    let body = AuthenticatedClient.castBody(JsonParsers.Encoders.pathRequest(payload))

    AuthenticatedClient.requestWithRetry(
      Constants.backendUrl ++ "/api/project/calculate-path",
      ~method="POST",
      ~body,
      ~signal?,
      (),
    )
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Retry.Success(response, _) =>
        response.json()
        ->Promise.then(
          json =>
            handleJsonDecode(
              ~module_="ProjectApi",
              json,
              decodeSteps,
              "CALCULATE_PATH",
              "Path calculation failed",
            ),
        )
        ->Promise.catch(
          e =>
            handleError(
              ~module_="ProjectApi",
              e,
              "Path calculation failed: JSON parsing error",
              "CALCULATE_PATH_ERROR_JSON_DECODE",
            ),
        )
      | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e =>
      handleError(~module_="ProjectApi", e, "Path calculation failed", "CALCULATE_PATH_ERROR")
    )
  })
}

let reverseGeocode = (lat: float, lon: float): Promise.t<apiResult<geocodeResponse>> => {
  RequestQueue.schedule(() => {
    let body = JsonCombinators.Json.Encode.object([
      ("lat", JsonCombinators.Json.Encode.float(lat)),
      ("lon", JsonCombinators.Json.Encode.float(lon)),
    ])

    AuthenticatedClient.requestWithRetry(
      Constants.backendUrl ++ "/api/geocoding/reverse",
      ~method="POST",
      ~body=AuthenticatedClient.castBody(body),
      (),
    )
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Retry.Success(response, _) =>
        response.json()
        ->Promise.then(
          json =>
            handleJsonDecode(
              ~module_="ProjectApi",
              json,
              decodeGeocodeResponse,
              "GEOCODE",
              "Geocoding failed",
            ),
        )
        ->Promise.catch(
          e => {
            let (msg, _) = Logger.getErrorDetails(e)
            Promise.resolve(Error("Decoding geocode response failed: " ++ msg))
          },
        )
      | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e =>
      handleError(~module_="ProjectApi", e, "Geocoding failed", "GEOCODE_FAILED")
    )
  })
}

let listDashboardProjects = (): Promise.t<apiResult<array<dashboardProject>>> =>
  ProjectApiDashboard.listDashboardProjects()

let loadDashboardProject = (sessionId: string): Promise.t<apiResult<dashboardLoadResponse>> =>
  ProjectApiDashboard.loadDashboardProject(sessionId)

let syncSnapshot = (
  ~sessionId: option<string>=?,
  ~projectData: JSON.t,
  ~origin: snapshotOrigin=Auto,
): Promise.t<apiResult<snapshotSyncResponse>> =>
  ProjectApiSnapshots.syncSnapshot(~sessionId?, ~projectData, ~origin)

let cleanupBackendCache = (): Promise.t<apiResult<JSON.t>> => {
  RequestQueue.schedule(() => {
    AuthenticatedClient.requestWithRetry(
      Constants.backendUrl ++ "/api/project/cache/cleanup",
      ~method="POST",
      (),
    )
    ->Promise.then(resultResponse => {
      switch resultResponse {
      | Retry.Success(response, _) =>
        response.json()->Promise.then(json => Promise.resolve(Ok(castJson(json))))
      | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e =>
      handleError(~module_="ProjectApi", e, "Cache cleanup failed", "CACHE_CLEANUP_FAILED")
    )
  })
}

let listProjectSnapshots = (sessionId: string): Promise.t<apiResult<array<snapshotHistoryItem>>> =>
  ProjectApiSnapshots.listProjectSnapshots(sessionId)

let restoreProjectSnapshot = (~sessionId: string, ~snapshotId: string): Promise.t<
  apiResult<snapshotRestoreResponse>,
> => ProjectApiSnapshots.restoreProjectSnapshot(~sessionId, ~snapshotId)

let syncSnapshotAssets = (~sessionId: string, ~state: Types.state): Promise.t<
  apiResult<snapshotAssetSyncResponse>,
> => ProjectApiSnapshots.syncSnapshotAssets(~sessionId, ~state)
