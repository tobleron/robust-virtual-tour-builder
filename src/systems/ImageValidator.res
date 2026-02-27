/* src/systems/ImageValidator.res */
open ReBindings

// Pure validation rules (size, type, dimensions).
let allowedExtensions = ["jpg", "jpeg", "png", "webp", "heic", "heif"]

let validateFiles = (files: array<File.t>, onInvalid: string => unit) => {
  Belt.Array.keep(files, f => {
    let name = File.name(f)
    let parts = String.split(name, ".")
    let len = Array.length(parts)
    let ext = if len > 1 {
      switch Belt.Array.get(parts, len - 1) {
      | Some(e) => String.toLowerCase(e)
      | None => ""
      }
    } else {
      ""
    }

    let type_ = String.toLowerCase(File.type_(f))
    let isImage = String.startsWith(type_, "image/") || Array.includes(allowedExtensions, ext)

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
    WorkerPool.validateImageWithWorker(file, ~signal?)
    ->Promise.then(workerDecision =>
      switch workerDecision {
      | Some(isImage) => Promise.resolve((file, isImage))
      | None =>
        // Fallback to existing local validation when worker is unavailable/fails.
        let name = File.name(file)
        let parts = String.split(name, ".")
        let len = Array.length(parts)
        let ext = if len > 1 {
          switch Belt.Array.get(parts, len - 1) {
          | Some(e) => String.toLowerCase(e)
          | None => ""
          }
        } else {
          ""
        }
        let type_ = String.toLowerCase(File.type_(file))
        let isImage = String.startsWith(type_, "image/") || Array.includes(allowedExtensions, ext)
        Promise.resolve((file, isImage))
      }
    )
  )

  Promise.all(tasks)->Promise.then(results => {
    Promise.resolve(results->Belt.Array.keepMap(((file, isImage)) => {
      if isImage {
        Some(file)
      } else {
        onInvalid(File.name(file))
        None
      }
    }))
  })
}
