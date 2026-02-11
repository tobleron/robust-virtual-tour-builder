/* src/bindings/BrowserBindings.res */

module Blob = {
  type t
  @new external newBlob: (array<'a>, {..}) => t = "Blob"
  @get external size: t => float = "size"
  @get external type_: t => string = "type"
}

module JsHelpers = {
  @scope("Array") @val external from: 'a => array<'b> = "from"
}

module JSWeakMap = {
  type t<'k, 'v>
  @new external make: unit => t<'k, 'v> = "WeakMap"
  @send external get: (t<'k, 'v>, 'k) => Nullable.t<'v> = "get"
  @send external set: (t<'k, 'v>, 'k, 'v) => unit = "set"
}

module BrowserArrayBuffer = {
  type t = Js.Typed_array.ArrayBuffer.t
}

module File = {
  type t
  @new external newFile: (array<'a>, string, {..}) => t = "File"
  @get external name: t => string = "name"
  @get external size: t => float = "size"
  @get external type_: t => string = "type"
}

module FileList = {
  type t
  @get external length: t => int = "length"
  @send @return(nullable) external item: (t, int) => option<File.t> = "item"
  @get_index @return(nullable) external item_get: (t, int) => option<File.t> = ""
}

module JSZip = {
  type t
  type zipObject

  @new external create: unit => t = "JSZip"
  @val @scope("JSZip") external loadAsync: Blob.t => Promise.t<t> = "loadAsync"

  @send external file: (t, string) => Nullable.t<zipObject> = "file"
  @send external async: (zipObject, string) => Promise.t<'a> = "async"
  @send external generateAsync: (t, {..}) => Promise.t<Blob.t> = "generateAsync"
}

module AbortSignal = {
  type t

  @get external aborted: t => bool = "aborted"
  @send external addEventListener: (t, string, unit => unit) => unit = "addEventListener"
  @send external removeEventListener: (t, string, unit => unit) => unit = "removeEventListener"
}

module AbortController = {
  type t

  @new external make: unit => t = "AbortController"
  @get external signal: t => AbortSignal.t = "signal"
  @send external abort: t => unit = "abort"
}
