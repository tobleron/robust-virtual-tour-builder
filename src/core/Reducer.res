/* src/core/Reducer.res - Consolidated Reducers */

open Types
open Actions

// Delegate to sub-modules
module Helpers = ReducerModules.Helpers
module Scene = ReducerModules.Scene
module Hotspot = ReducerModules.Hotspot
module Ui = ReducerModules.Ui
module AppFsm = ReducerModules.AppFsm
module Navigation = ReducerModules.Navigation
module Simulation = ReducerModules.Simulation
module Timeline = ReducerModules.Timeline
module Project = ReducerModules.Project

let apply = (state: state, action: action, reducerFn: (state, action) => option<state>): state => {
  switch reducerFn(state, action) {
  | Some(newState) => newState
  | None => state
  }
}

// --- COMPATIBILITY ALIASES ---
module Mod = {
  module Scene = Scene
  module Hotspot = Hotspot
  module Ui = Ui
  module Navigation = Navigation
  module Simulation = Simulation
  module Timeline = Timeline
  module Project = Project
}

let rec reducer = (state: state, action: action): state => {
  switch action {
  | RestoreState(nextState) => nextState
  | Batch(actions) => Belt.Array.reduce(actions, state, (s, a) => reducer(s, a))
  | _ =>
    state
    ->apply(action, AppFsm.reduce)
    ->apply(action, Scene.reduce)
    ->apply(action, Hotspot.reduce)
    ->apply(action, Ui.reduce)
    ->apply(action, Navigation.reduce)
    ->apply(action, Simulation.reduce)
    ->apply(action, Timeline.reduce)
    ->apply(action, Project.reduce)
  }
}
