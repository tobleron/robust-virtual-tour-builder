open Types

// Helper for array insertion
let insertAt = (arr, index, item) => {
  let before = Belt.Array.slice(arr, ~offset=0, ~len=index)
  let after = Belt.Array.slice(arr, ~offset=index, ~len=Belt.Array.length(arr) - index)
  Belt.Array.concatMany([before, [item], after])
}

let castJsonToFile = (json: JSON.t): ReBindings.File.t => Obj.magic(json)
let castJsonToBlob = (json: JSON.t): ReBindings.Blob.t => Obj.magic(json)
let castStringToBlob = (str: string): ReBindings.Blob.t => Obj.magic(str)
let castFileToBlob = (file: ReBindings.File.t): ReBindings.Blob.t => Obj.magic(file)

let decodeFile = (json: JSON.t): Types.file => {
  switch JSON.Decode.string(json) {
  | Some(s) => Url(s)
  | None =>
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
