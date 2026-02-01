/* src/core/UiHelpers.res */

open Types

external fileToBlobCast: ReBindings.File.t => ReBindings.Blob.t = "%identity"

let insertAt = (arr: array<'a>, index: int, item: 'a): array<'a> => {
  let len = Belt.Array.length(arr)
  if index >= len {
    Belt.Array.concat(arr, [item])
  } else if index <= 0 {
    Belt.Array.concat([item], arr)
  } else {
    let before = Belt.Array.slice(arr, ~offset=0, ~len=index)
    let after = Belt.Array.slice(arr, ~offset=index, ~len=len - index)
    Belt.Array.concat(Belt.Array.concat(before, [item]), after)
  }
}

let fileToBlob = (file: file): ReBindings.Blob.t => {
  switch file {
  | Blob(b) => b
  | File(f) => fileToBlobCast(f)
  | Url(_) => ReBindings.Blob.newBlob([], {"type": "text/plain"})
  }
}
