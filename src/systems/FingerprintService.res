/* src/systems/FingerprintService.res */
open ReBindings
open UploadTypes

// Hashing and duplication detection.
let fingerprintFiles = (validFiles: array<File.t>) => {
  let fingerprintPromises = Belt.Array.map(validFiles, f => {
    Resizer.getChecksum(f)
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
  ~existingScenes: array<Types.scene>,
  ~deletedIds: array<string>,
  ~onDuplicate: int => unit,
  ~onRestore: string => unit,
) => {
  let existingIdsSet = Belt.Set.String.fromArray(Belt.Array.map(existingScenes, s => s.id))
  let deletedIdsSet = Belt.Set.String.fromArray(deletedIds)

  let uniqueItems = []
  let skippedCount = ref(0)

  Belt.Array.forEach(results, item => {
    switch Nullable.toOption(item.id) {
    | Some(id) =>
      if Belt.Set.String.has(existingIdsSet, id) {
        skippedCount := skippedCount.contents + 1
      } else {
        if Belt.Set.String.has(deletedIdsSet, id) {
          onRestore(id)
        }
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
