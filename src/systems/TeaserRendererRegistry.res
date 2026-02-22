open Types

module Styles = TeaserStyleCatalog

let buildManifestForStyle = (
  state: state,
  ~style: Styles.teaserStyle,
  ~skipAutoForward: bool,
  ~includeIntroPan: bool,
): result<motionManifest, string> =>
  switch style {
  | Cinematic => TeaserStyleCinematic.buildManifest(state, ~skipAutoForward, ~includeIntroPan)
  | FastShots => TeaserStyleFastShots.buildManifest(state, ~skipAutoForward, ~includeIntroPan)
  | SimpleCrossfade =>
    TeaserStyleSimpleCrossfade.buildManifest(state, ~skipAutoForward, ~includeIntroPan)
  }
