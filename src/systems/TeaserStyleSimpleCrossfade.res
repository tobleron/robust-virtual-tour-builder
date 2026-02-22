open Types

let buildManifest = (_state: state, ~skipAutoForward: bool, ~includeIntroPan: bool): result<
  motionManifest,
  string,
> => {
  ignore(skipAutoForward)
  ignore(includeIntroPan)
  Error("Simple Crossfade teaser style is not implemented yet")
}
