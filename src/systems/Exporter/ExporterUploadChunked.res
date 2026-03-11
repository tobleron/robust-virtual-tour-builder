open ReBindings

let uploadChunkedWithResume = async (
  payloadBlob: Blob.t,
  ~filename: string,
  onProgress: (float, float, string) => unit,
  ~signal: BrowserBindings.AbortSignal.t,
  ~operationId: option<string>=?,
): ExporterUploadRequests.apiResult<ExporterUploadRequests.exportCompleteResponse> => {
  if ExporterUploadRequests.isAborted(signal) {
    Error("AbortError: Export cancelled by user")
  } else {
    switch await ExporterUploadRequests.requestExportInit(
      payloadBlob,
      ~filename,
      ~signal,
      ~operationId?,
    ) {
    | Error(msg) => Error(msg)
    | Ok(init) =>
      switch await ExporterUploadRequests.requestExportStatus(
        init.uploadId,
        ~signal,
        ~operationId?,
      ) {
      | Error(msg) =>
        ignore(
          await ExporterUploadRequests.requestExportAbort(init.uploadId, ~signal, ~operationId?),
        )
        Error(msg)
      | Ok(status) =>
        let totalChunks = if init.totalChunks > 0 {
          init.totalChunks
        } else {
          status.totalChunks
        }
        let uploadedCount = ref(Belt.Array.length(status.receivedChunks))
        let rec uploadLoop = async chunkIndex => {
          if chunkIndex >= totalChunks {
            Ok()
          } else if ExporterUploadRequests.isAborted(signal) {
            ignore(
              await ExporterUploadRequests.requestExportAbort(
                init.uploadId,
                ~signal,
                ~operationId?,
              ),
            )
            Error("AbortError: Export cancelled by user")
          } else if Belt.Array.some(status.receivedChunks, idx => idx == chunkIndex) {
            await uploadLoop(chunkIndex + 1)
          } else {
            switch await ExporterUploadRequests.requestExportChunk(
              payloadBlob,
              ~filename,
              ~uploadId=init.uploadId,
              ~chunkIndex,
              ~chunkSizeBytes=init.chunkSizeBytes,
              ~signal,
              ~operationId?,
            ) {
            | Error(msg) => Error(msg)
            | Ok(_) =>
              uploadedCount := uploadedCount.contents + 1
              let pct =
                40.0 +. 35.0 *. Int.toFloat(uploadedCount.contents) /. Int.toFloat(totalChunks)
              onProgress(
                pct,
                100.0,
                "Uploading chunks: " ++
                Belt.Int.toString(uploadedCount.contents) ++
                "/" ++
                Belt.Int.toString(totalChunks),
              )
              await uploadLoop(chunkIndex + 1)
            }
          }
        }
        switch await uploadLoop(0) {
        | Error(msg) =>
          ignore(
            await ExporterUploadRequests.requestExportAbort(init.uploadId, ~signal, ~operationId?),
          )
          Error(msg)
        | Ok() =>
          if ExporterUploadRequests.isAborted(signal) {
            ignore(
              await ExporterUploadRequests.requestExportAbort(
                init.uploadId,
                ~signal,
                ~operationId?,
              ),
            )
            Error("AbortError: Export cancelled by user")
          } else {
            await ExporterUploadRequests.requestExportComplete(
              payloadBlob,
              ~filename,
              ~uploadId=init.uploadId,
              ~totalChunks,
              ~signal,
              ~operationId?,
            )
          }
        }
      }
    }
  }
}
