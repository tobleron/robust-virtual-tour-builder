open ReBindings

let resolveOpId = (
  ~opId: option<OperationLifecycle.operationId>,
  ~sceneCount: int,
  ~tourName: string,
): OperationLifecycle.operationId =>
  switch opId {
  | Some(id) => id
  | None =>
    OperationLifecycle.start(
      ~type_=Export,
      ~scope=Blocking,
      ~phase="Preparing",
      ~meta=Logger.castToJson({
        "sceneCount": sceneCount,
        "tourName": tourName,
      }),
      (),
    )
  }

let reportProgress = (
  ~opId: OperationLifecycle.operationId,
  ~currentPhase: ref<string>,
  ~onProgress: option<(float, float, string) => unit>,
  p: float,
  t: float,
  m: string,
) => {
  let pct = if t > 0.0 {
    p /. t *. 100.0
  } else {
    0.0
  }
  OperationLifecycle.progress(opId, pct, ~message=m, ~phase=currentPhase.contents, ())
  switch onProgress {
  | Some(cb) => cb(p, t, m)
  | None => ()
  }
}

let normalizeTourName = (tourName: string): string =>
  if tourName == "" {
    "Virtual_Tour"
  } else {
    tourName
  }

let rec uploadWithRetry = async (
  ~formData: FormData.t,
  ~progress: (float, float, string) => unit,
  ~backendUrl: string,
  ~totalScenes: int,
  ~signal: BrowserBindings.AbortSignal.t,
  ~opId: OperationLifecycle.operationId,
  ~token: option<string>,
  ~retryCount: int,
) => {
  try {
    let result = await (
      if totalScenes < 10 {
        ExporterUpload.uploadAndProcessRaw(
          formData,
          progress,
          backendUrl,
          Constants.Exporter.uploadTimeoutMs,
          ~signal,
          ~token,
          ~operationId=Some(opId),
        )
      } else {
        ExporterUpload.uploadChunkedThenLegacy(
          formData,
          progress,
          backendUrl,
          Constants.Exporter.uploadTimeoutMs,
          ~signal,
          ~token,
          ~operationId=Some(opId),
        )
      }
    )
    CircuitBreaker.recordSuccess(AuthenticatedClient.circuitBreaker)
    result
  } catch {
  | exn =>
    let msg = ExporterUtils.normalizeThrowableMessage(exn)
    let isLegacyNetworkOffline = String.includes(msg, "NetworkOffline")
    let isAbort = String.includes(msg, "AbortError")
    let isUnauthorized = ExporterUtils.isUnauthorizedHttpError(msg)
    let isTimeout = String.includes(msg, "TimeoutError")
    let isTransportNetworkError = String.includes(msg, "NetworkError") || isLegacyNetworkOffline
    let backendStillReachable = if isTransportNetworkError {
      await Resizer.checkBackendHealth()
    } else {
      true
    }

    let usingDevToken = switch token {
    | Some(t) => t == "dev-token"
    | None => false
    }
    let shouldRetryWithDevToken = Constants.isDebugBuild() && !usingDevToken && isUnauthorized

    if shouldRetryWithDevToken {
      Logger.warn(
        ~module_="Exporter",
        ~message="EXPORT_RETRY_WITH_DEV_TOKEN",
        ~data=Some({"reason": "401 Unauthorized", "hadAuthToken": token != None}),
        (),
      )
      await uploadWithRetry(
        ~formData,
        ~progress,
        ~backendUrl,
        ~totalScenes,
        ~signal,
        ~opId,
        ~token=Some("dev-token"),
        ~retryCount=0,
      )
    } else if isTransportNetworkError && !backendStillReachable {
      let message = ExporterUtils.backendOfflineExportMessage()
      Logger.warn(
        ~module_="Exporter",
        ~message="EXPORT_BACKEND_UNREACHABLE_DURING_UPLOAD",
        ~data=Some({"backendUrl": Constants.backendUrl, "error": msg}),
        (),
      )
      CircuitBreaker.recordFailure(AuthenticatedClient.circuitBreaker)
      JsError.throwWithMessage(message)
    } else if retryCount < 2 && !isAbort && !isUnauthorized && !isTimeout {
      Logger.warn(
        ~module_="Exporter",
        ~message="EXPORT_RETRY",
        ~data=Some(Logger.castToJson({"attempt": retryCount + 1, "error": msg})),
        (),
      )
      progress(40.0, 100.0, "Retrying upload...")
      let _ = await Promise.make((resolve, _) => {
        let _ = ReBindings.Window.setTimeout(() => resolve(), Constants.Exporter.retryDelayMs)
      })
      await uploadWithRetry(
        ~formData,
        ~progress,
        ~backendUrl,
        ~totalScenes,
        ~signal,
        ~opId,
        ~token,
        ~retryCount=retryCount + 1,
      )
    } else if isTimeout {
      Logger.warn(
        ~module_="Exporter",
        ~message="EXPORT_TIMEOUT_NO_RETRY",
        ~data=Some({"timeoutMs": Constants.Exporter.uploadTimeoutMs, "error": msg}),
        (),
      )
      JsError.throwWithMessage(msg)
    } else {
      CircuitBreaker.recordFailure(AuthenticatedClient.circuitBreaker)
      if isLegacyNetworkOffline {
        JsError.throwWithMessage(
          "NetworkError: Export upload was interrupted. Please retry export.",
        )
      } else {
        JsError.throwWithMessage(msg)
      }
    }
  }
}
