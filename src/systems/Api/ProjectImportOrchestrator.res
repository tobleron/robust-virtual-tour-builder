/* src/systems/Api/ProjectImportOrchestrator.res */

open ApiHelpers
open ReBindings
include ProjectImportApi

let rec uploadMissingChunks = async (
  file: File.t,
  ~uploadId: string,
  ~chunkSizeBytes: int,
  ~totalChunks: int,
  ~receivedChunks: array<int>,
  ~currentIndex: int,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~operationId: option<string>=?,
): apiResult<unit> => {
  if currentIndex >= totalChunks {
    Ok()
  } else if receivedChunks->Belt.Array.some(idx => idx == currentIndex) {
    await uploadMissingChunks(
      file,
      ~uploadId,
      ~chunkSizeBytes,
      ~totalChunks,
      ~receivedChunks,
      ~currentIndex=currentIndex + 1,
      ~signal?,
      ~operationId?,
    )
  } else {
    let chunkResult = await requestImportChunk(
      file,
      ~uploadId,
      ~chunkIndex=currentIndex,
      ~chunkSizeBytes,
      ~signal?,
      ~operationId?,
    )
    switch chunkResult {
    | Ok(_) =>
      await uploadMissingChunks(
        file,
        ~uploadId,
        ~chunkSizeBytes,
        ~totalChunks,
        ~receivedChunks,
        ~currentIndex=currentIndex + 1,
        ~signal?,
        ~operationId?,
      )
    | Error(msg) => Error(msg)
    }
  }
}

let importProject = (
  file: File.t,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~operationId: option<string>=?,
): Promise.t<apiResult<importResponse>> => {
  RequestQueue.schedule(() => {
    let chunkedFlow = async () => {
      let initResult = await requestImportInit(file, ~signal?, ~operationId?)
      switch initResult {
      | Error(msg) => Error(msg)
      | Ok(initData) =>
        let statusResult = await requestImportStatus(initData.uploadId, ~signal?, ~operationId?)
        let receivedChunks = switch statusResult {
        | Ok(status) => status.receivedChunks
        | Error(msg) =>
          Logger.warn(
            ~module_="ProjectImportOrchestrator",
            ~message="CHUNK_IMPORT_STATUS_FALLBACK_EMPTY",
            ~data=Logger.castToJson({"reason": msg, "uploadId": initData.uploadId}),
            (),
          )
          []
        }

        let uploadResult = await uploadMissingChunks(
          file,
          ~uploadId=initData.uploadId,
          ~chunkSizeBytes=initData.chunkSizeBytes,
          ~totalChunks=initData.totalChunks,
          ~receivedChunks,
          ~currentIndex=0,
          ~signal?,
          ~operationId?,
        )

        switch uploadResult {
        | Error(msg) =>
          Logger.error(
            ~module_="ProjectImportOrchestrator",
            ~message="IMPORT_ABORT_START",
            ~data=Logger.castToJson({"uploadId": initData.uploadId, "reason": msg}),
            (),
          )
          let _ = await requestImportAbort(initData.uploadId, ~signal?, ~operationId?)
          Error(msg)
        | Ok(_) =>
          await requestImportComplete(
            file,
            ~uploadId=initData.uploadId,
            ~totalChunks=initData.totalChunks,
            ~signal?,
            ~operationId?,
          )
        }
      }
    }

    chunkedFlow()->Promise.catch(e =>
      ApiHelpers.handleError(
        ~module_="ProjectImportOrchestrator",
        e,
        "Project import failed",
        "IMPORT_ERROR",
      )
    )
  })
}
