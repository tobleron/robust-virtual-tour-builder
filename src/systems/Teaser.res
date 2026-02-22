/* src/systems/Teaser.res - Consolidated Teaser System */

include TeaserLogic

// --- FACADE (TOP LEVEL) ---

let startAutoTeaser = (
  format: string,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~onCancel: option<unit => unit>=?,
) => Manager.startAutoTeaser(format, ~getState, ~dispatch, ~signal?, ~onCancel?)
let startCinematicTeaser = Manager.startCinematicTeaser
let startHeadlessTeaser = (
  format: string,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~onCancel: option<unit => unit>=?,
) => Manager.startHeadlessTeaser(format, ~getState, ~dispatch, ~signal?, ~onCancel?)
let startHeadlessTeaserWithStyle = (
  format: string,
  ~styleId: option<string>,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~onCancel: option<unit => unit>=?,
) =>
  Manager.startHeadlessTeaserWithStyle(format, ~styleId, ~getState, ~dispatch, ~signal?, ~onCancel?)

// --- COMPATIBILITY ALIASES ---
module TeaserRecorder = Recorder
module TeaserManager = Manager
module TeaserState = State
module TeaserPlayback = Playback
module TeaserPathfinder = Pathfinder
