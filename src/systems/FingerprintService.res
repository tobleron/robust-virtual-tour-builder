/* src/systems/FingerprintService.res */
open ReBindings
open UploadTypes

// Hashing and duplication detection.
let fingerprintFiles = (
  validFiles: array<File.t>,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
) => {
  let fingerprintPromises = Belt.Array.map(validFiles, f => {
    WorkerPool.fingerprintWithWorker(f, ~signal?)
    ->Promise.then(workerResult =>
      switch workerResult {
      | Some(id) => Promise.resolve(id)
      | None => Resizer.getChecksum(f)
      }
    )
    ->Promise.then(id =>
      Promise.resolve(
        (
          {
            id: Nullable.make(id),
            original: f,
            error: None,
            preview: None,
            tiny: None,
            quality: None,
            metadata: None,
            colorGroup: None,
          }: uploadItem
        ),
      )
    )
    ->Promise.catch(_err => {
      Logger.error(
        ~module_="Upload",
        ~message="FINGERPRINT_FAILED",
        ~data=Some({"filename": File.name(f)}),
        (),
      )
      Promise.resolve(
        (
          {
            id: Nullable.null,
            original: f,
            error: Some("Fingerprint failed"),
            preview: None,
            tiny: None,
            quality: None,
            metadata: None,
            colorGroup: None,
          }: uploadItem
        ),
      )
    })
  })
  Promise.all(fingerprintPromises)
}

let filterDuplicates = (
  results: array<uploadItem>,
  ~inventory: Belt.Map.String.t<Types.sceneEntry>,
  ~onDuplicate: int => unit,
  ~onRestore: string => unit,
) => {
  let uniqueItems = []
  let skippedCount = ref(0)

  Belt.Array.forEach(results, item => {
    switch Nullable.toOption(item.id) {
    | Some(id) =>
      switch inventory->Belt.Map.String.get(id) {
      | Some({status: Deleted(_)}) =>
        onRestore(id)
        let _ = Array.push(uniqueItems, item)
      | Some({status: Active}) => skippedCount := skippedCount.contents + 1
      | None =>
        let _ = Array.push(uniqueItems, item)
      }
    | None => () /* Failed item */
    }
  })

  if skippedCount.contents > 0 {
    onDuplicate(skippedCount.contents)
  }
  uniqueItems
}
