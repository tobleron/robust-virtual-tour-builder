/* src/bindings/StorageBindings.res */

module StorageEstimate = {
  type t = {
    usage: float, // bytes used
    quota: float, // bytes available
  }
}

module StorageManager = {
  @val @scope(("navigator", "storage"))
  external estimate: unit => Promise.t<StorageEstimate.t> = "estimate"
}
