open RescriptSchema
open Types

// Helper for array insertion
let insertAt = (arr, index, item) => {
  let before = Belt.Array.slice(arr, ~offset=0, ~len=index)
  let after = Belt.Array.slice(arr, ~offset=index, ~len=Belt.Array.length(arr) - index)
  Belt.Array.concatMany([before, [item], after])
}

external castJsonToFile: JSON.t => ReBindings.File.t = "%identity"
external castJsonToBlob: JSON.t => ReBindings.Blob.t = "%identity"
external castStringToBlob: string => ReBindings.Blob.t = "%identity"
external castFileToBlob: ReBindings.File.t => ReBindings.Blob.t = "%identity"

let decodeFile = (json: JSON.t): Types.file => {
  try {
    Url(S.parseOrThrow(json, S.string))
  } catch {
  | _ =>
    // Check if it's a raw File/Blob object from upload via %identity
    let isFile: bool = %raw("json instanceof File")
    if isFile {
      File(castJsonToFile(json))
    } else {
      let isBlob: bool = %raw("json instanceof Blob")
      if isBlob {
        Blob(castJsonToBlob(json))
      } else {
        Url("")
      }
    }
  }
}

let fileToBlob = (f: Types.file): ReBindings.Blob.t => {
  switch f {
  | Url(s) => castStringToBlob(s)
  | Blob(b) => b
  | File(file) => castFileToBlob(file)
  }
}

let fileToFile = (f: Types.file): option<ReBindings.File.t> => {
  switch f {
  | File(file) => Some(file)
  | _ => None
  }
}
