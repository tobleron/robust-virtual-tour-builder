/* src/systems/Navigation.res */
// @efficiency-role: orchestrator

module FSM = NavigationFSM
module Graph = NavigationGraph
module Renderer = NavigationRenderer
module UI = NavigationUI
module Controller = NavigationController

// Re-export common functions or components if needed
let updateReturnPrompt = UI.updateReturnPrompt
