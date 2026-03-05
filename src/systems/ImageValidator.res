/* src/systems/ImageValidator.res */
open ReBindings

// Pure validation rules (size, type, dimensions).
let allowedExtensions = ["jpg", "jpeg", "png", "webp"]
let allowedMimeTypes = ["image/jpeg", "image/png", "image/webp"]

let getExtension = (name: string): string => {
  let parts = String.split(name, ".")
  let len = Array.length(parts)
  if len > 1 {
    switch Belt.Array.get(parts, len - 1) {
    | Some(e) => String.toLowerCase(e)
    | None => ""
    }
  } else {
    ""
  }
}

let isSupportedImageType = (~mime: string, ~ext: string): bool => {
  let normalizedMime = String.toLowerCase(mime)
  if normalizedMime == "" {
    Array.includes(allowedExtensions, ext)
  } else {
    Array.includes(allowedMimeTypes, normalizedMime)
  }
}

let validateFiles = (files: array<File.t>, onInvalid: string => unit) => {
  Belt.Array.keep(files, f => {
    let name = File.name(f)
    let ext = getExtension(name)
    let isImage = isSupportedImageType(~mime=File.type_(f), ~ext)

    if !isImage {
      onInvalid(name)
    }
    isImage
  })
}

let validateFilesAsync = (
  files: array<File.t>,
  onInvalid: string => unit,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
): Promise.t<array<File.t>> => {
  let tasks = files->Belt.Array.map(file =>
    WorkerPool.validateImageWithWorker(file, ~signal?)->Promise.then(workerDecision =>
      switch workerDecision {
      | Some(isImage) => Promise.resolve((file, isImage))
      | None =>
        // Fallback to existing local validation when worker is unavailable/fails.
        let name = File.name(file)
        let ext = getExtension(name)
        let isImage = isSupportedImageType(~mime=File.type_(file), ~ext)
        Promise.resolve((file, isImage))
      }
    )
  )

  Promise.all(tasks)->Promise.then(results => {
    Promise.resolve(
      results->Belt.Array.keepMap(((file, isImage)) => {
        if isImage {
          Some(file)
        } else {
          onInvalid(File.name(file))
          None
        }
      }),
    )
  })
}
