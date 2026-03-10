/* src/systems/Api/ProjectApiDashboard.res */

open ApiHelpers

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

let decodeDashboardProjects = json =>
  JsonCombinators.Json.decode(json, JsonCombinators.Json.Decode.array(dashboardProjectDecoder))

let decodeDashboardLoadResponse = json => JsonCombinators.Json.decode(json, dashboardLoadDecoder)

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
