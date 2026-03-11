open ReBindings
open Types

type onProgress = (int, int, string) => unit
type apiError = string

let resolveOperationId = (state: state, ~opId: option<OperationLifecycle.operationId>=?): (
  bool,
  OperationLifecycle.operationId,
) => {
  switch opId {
  | Some(id) => (false, id)
  | None =>
    let id = OperationLifecycle.start(
      ~type_=ProjectSave,
      ~scope=Blocking,
      ~phase="Preparing",
      ~meta=Logger.castToJson({
        "sceneCount": Array.length(
          SceneInventory.getActiveScenes(state.inventory, state.sceneOrder),
        ),
      }),
      (),
    )
    (true, id)
  }
}

let reportProgress = (~opId, ~onProgress: option<onProgress>=?, curr, total, msg): unit => {
  let pct = if total > 0 {
    Float.fromInt(curr) /. Float.fromInt(total) *. 100.0
  } else {
    0.0
  }

  OperationLifecycle.progress(opId, pct, ~message=msg, ())
  switch onProgress {
  | Some(cb) => cb(curr, total, msg)
  | None => ()
  }
}

let appendSceneFiles = (formData, state: state): unit => {
  let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)

  Belt.Array.forEachWithIndex(activeScenes, (_index, scene) => {
    switch scene.file {
    | File(f) => FormData.appendWithFilename(formData, "files", f, scene.name)
    | Blob(b) => FormData.appendWithFilename(formData, "files", b, scene.name)
    | Url(_) => ()
    }
  })

  state.sessionId->Option.forEach(id => FormData.append(formData, "session_id", id))
}

let appendLogoToSavePackage = (formData, state: state): Promise.t<unit> => {
  switch state.logo {
  | Some(File(f)) =>
    FormData.appendWithFilename(formData, "files", f, "logo_upload")
    Promise.resolve()
  | Some(Blob(b)) =>
    FormData.appendWithFilename(formData, "files", b, "logo_upload")
    Promise.resolve()
  | Some(Url(u)) if u != "" =>
    let token = Dom.Storage2.localStorage->Dom.Storage2.getItem("auth_token")
    let authToken = switch token {
    | Some(t) => Some(t)
    | None if Constants.isDebugBuild() => Some("dev-token")
    | None => None
    }

    ExporterUtils.fetchSceneUrlBlob(~url=u, ~authToken)
    ->Promise.then(result => {
      switch result {
      | Ok(blob) =>
        FormData.appendWithFilename(formData, "files", blob, "logo_upload")
        Logger.debug(
          ~module_="ProjectSystem",
          ~message="LOGO_URL_RESOLVED_FOR_SAVE",
          ~data=Some({"url": u}),
          (),
        )
      | Error(msg) =>
        Logger.warn(
          ~module_="ProjectSystem",
          ~message="LOGO_URL_FETCH_FAILED_FOR_SAVE",
          ~data=Some({"url": u, "error": msg}),
          (),
        )
      }
      Promise.resolve()
    })
    ->Promise.catch(_ => {
      Logger.warn(
        ~module_="ProjectSystem",
        ~message="LOGO_URL_FETCH_EXCEPTION_FOR_SAVE",
        ~data=Some({"url": u}),
        (),
      )
      Promise.resolve()
    })
  | _ => Promise.resolve()
  }
}

let finishLifecycle = (~ownsLifecycle, ~opId, result: result<Blob.t, apiError>): Promise.t<
  result<Blob.t, apiError>,
> => {
  switch result {
  | Ok(blob) =>
    if ownsLifecycle {
      OperationLifecycle.complete(opId, ~result="Saved", ())
    }
    Promise.resolve(Ok(blob))
  | Error(msg) =>
    if ownsLifecycle {
      OperationLifecycle.fail(opId, msg)
    }
    Promise.resolve(Error(msg))
  }
}

let createSavePackage = (
  state: state,
  ~encodeProjectFromState: state => JSON.t,
  ~signal=?,
  ~onProgress: option<onProgress>=?,
  ~opId: option<OperationLifecycle.operationId>=?,
): Promise.t<result<Blob.t, apiError>> => {
  let (ownsLifecycle, opId) = resolveOperationId(state, ~opId?)

  reportProgress(~opId, ~onProgress?, 0, 100, "Preparing metadata...")

  let jsonStr = JsonCombinators.Json.stringify(encodeProjectFromState(state))
  let formData = FormData.newFormData()
  FormData.append(formData, "project_data", jsonStr)

  appendSceneFiles(formData, state)

  appendLogoToSavePackage(formData, state)
  ->Promise.then(_ => {
    reportProgress(~opId, ~onProgress?, 10, 100, "Uploading to backend...")
    OperationLifecycle.progress(
      opId,
      10.0,
      ~message="Uploading to backend...",
      ~phase="Uploading",
      (),
    )

    RequestQueue.schedule(() => {
      AuthenticatedClient.requestWithRetry(
        Constants.backendUrl ++ "/api/project/save",
        ~method="POST",
        ~formData,
        ~signal?,
        ~operationId=opId,
        ~dedupeKey="project-save-op:" ++ opId,
        (),
      )->Promise.then(
        retryResult => {
          switch retryResult {
          | Retry.Success(response, _att) =>
            AuthenticatedClient.fetchBlob(response)->Promise.then(blob => Promise.resolve(Ok(blob)))
          | Retry.Exhausted(msg) => Promise.resolve(Error(msg))
          }
        },
      )
    })
  })
  ->Promise.then(blobResult => {
    switch blobResult {
    | Ok(blob) =>
      reportProgress(~opId, ~onProgress?, 100, 100, "Package created!")
      finishLifecycle(~ownsLifecycle, ~opId, Ok(blob))
    | Error(msg) => finishLifecycle(~ownsLifecycle, ~opId, Error(msg))
    }
  })
  ->Promise.catch(err => {
    let (msg, _) = Logger.getErrorDetails(err)
    if ownsLifecycle {
      OperationLifecycle.fail(opId, msg)
    }
    Promise.resolve(Error(msg))
  })
}
