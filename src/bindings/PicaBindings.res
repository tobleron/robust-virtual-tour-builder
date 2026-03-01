/* src/bindings/PicaBindings.res */

module Pica = {
  type t

  type options = {
    features: option<array<string>>,
    idle: option<bool>,
    concurrency: option<int>,
  }

  type resizeOptions = {
    quality: int,
    alpha: bool,
    unsharpAmount: int,
    unsharpThreshold: int,
    cancelable: bool,
  }

  @module("pica") @new external make: unit => t = "default"
  @module("pica") @new external makeWithOptions: options => t = "default"

  @send
  external resize: (t, Dom.element, Dom.element, resizeOptions) => Promise.t<Dom.element> = "resize"

  @send
  external toBlob: (t, Dom.element, string, float) => Promise.t<ReBindings.Blob.t> = "toBlob"
}
