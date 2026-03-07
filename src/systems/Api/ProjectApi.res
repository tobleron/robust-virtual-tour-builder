/* src/systems/Api/ProjectApi.res */

open ApiHelpers
open ReBindings

include ProjectImportOrchestrator
external castJson: 'a => JSON.t = "%identity"

type dashboardProject = {
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

type dashboardLoadResponse = {
  sessionId: string,
  projectData: JSON.t,
}

let dashboardLoadDecoder = JsonCombinators.Json.Decode.object(field => {
  sessionId: field.required("sessionId", JsonCombinators.Json.Decode.string),
  projectData: field.required("projectData", JsonCombinators.Json.Decode.id),
})

type snapshotSyncResponse = {
  sessionId: string,
  updatedAt: string,
  sceneCount: int,
  hotspotCount: int,
}

let snapshotSyncDecoder = JsonCombinators.Json.Decode.object(field => {
  sessionId: field.required("sessionId", JsonCombinators.Json.Decode.string),
  updatedAt: field.required("updatedAt", JsonCombinators.Json.Decode.string),
  sceneCount: field.required("sceneCount", JsonCombinators.Json.Decode.int),
  hotspotCount: field.required("hotspotCount", JsonCombinators.Json.Decode.int),
})

let decodeDashboardProjects = json =>
  JsonCombinators.Json.decode(json, JsonCombinators.Json.Decode.array(dashboardProjectDecoder))

let decodeDashboardLoadResponse = json => JsonCombinators.Json.decode(json, dashboardLoadDecoder)

let decodeSnapshotSyncResponse = json => JsonCombinators.Json.decode(json, snapshotSyncDecoder)

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

let listDashboardProjects = (): Promise.t<apiResult<array<dashboardProject>>> => {
  RequestQueue.schedule(() => {
    AuthenticatedClient.requestWithRetry(
      Constants.backendUrl ++ "/api/project/dashboard/projects",
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
              decodeDashboardProjects,
              "DASHBOARD_LIST",
              "Dashboard list failed",
            ),
        )
      | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e =>
      handleError(~module_="ProjectApi", e, "Dashboard list failed", "DASHBOARD_LIST_FAILED")
    )
  })
}

let loadDashboardProject = (sessionId: string): Promise.t<apiResult<dashboardLoadResponse>> => {
  RequestQueue.schedule(() => {
    AuthenticatedClient.requestWithRetry(
      Constants.backendUrl ++ "/api/project/dashboard/projects/" ++ encodeURIComponent(sessionId),
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
              decodeDashboardLoadResponse,
              "DASHBOARD_LOAD",
              "Dashboard project load failed",
            ),
        )
      | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(e =>
      handleError(
        ~module_="ProjectApi",
        e,
        "Dashboard project load failed",
        "DASHBOARD_LOAD_FAILED",
      )
    )
  })
}

let syncSnapshot = (~sessionId: option<string>=?, ~projectData: JSON.t): Promise.t<
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
