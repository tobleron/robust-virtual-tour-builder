# Task: 807 - Test: Simulation & Autopilot System Unified Verification (Update)

## Objective
Verify the entire simulation and autopilot logic, including path generators, chain skippers, and navigation logic.

## Merged Tasks
- 700_Test_SimulationChainSkipper_Update.md
- 701_Test_SimulationDriver_Update.md
- 702_Test_SimulationLogic_Update.md
- 703_Test_SimulationNavigation_Update.md
- 704_Test_SimulationPathGenerator_Update.md
- 664_Test_SimulationReducer_Update.md

## Technical Context
The simulation system is highly deterministic but mathematically complex. Grouping these allows for integrated verification of the route calculation pipeline.

## Implementation Plan
1. **Logic/Navigation**: Test waypoint-based movement calculations.
2. **PathGenerator**: Verify Dijkstra/A* pathfinding between scenes.
3. **ChainSkipper**: Test optimization of redundant simulation steps.
4. **Reducer**: Verify that simulation actions update the state correctly.

## Verification Criteria
- [ ] Simulation routes are correctly calculated in tests.
- [ ] Redundant steps are correctly skipped by the optimizer.
- [ ] `SimulationReducer` state transitions match the FSM expectation.
