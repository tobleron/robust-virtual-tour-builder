// @efficiency-role: ui-component

open ReBindings
open ViewerState
open Types
open Actions

// Hook 7: Simulation Arrival
let useSimulationArrival = (~activeIndex: int, ~simulationStatus: simulationStatus) => {
  React.useEffect2(() => {
    if activeIndex != -1 && simulationStatus == Running {
      ()
    }
    None
  }, (activeIndex, simulationStatus))
}
