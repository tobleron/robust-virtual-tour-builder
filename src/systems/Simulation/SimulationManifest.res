/* src/systems/Simulation/SimulationManifest.res */

open Types
open SimulationTypes

type stepTransition = {
  targetSceneId: string,
  targetIndex: int,
  hotspotIndex: int,
  targetYaw: float,
  targetPitch: float,
  targetHfov: float,
}

type stepAction =
  | Wait({duration: int})
  | Pan({yaw: float, pitch: float, duration: int})
  | Stop

type step = {
  sceneId: string,
  sceneIndex: int,
  action: stepAction,
  transition: option<stepTransition>,
}

type manifest = {
  version: int,
  steps: array<step>,
}

let calculateWaitDuration = (
  scene: scene,
  isFirstScene: bool,
  skipAutoForward: bool,
): int => {
  if skipAutoForward {
    if scene.isAutoForward {
      if isFirstScene { 3000 } else { 0 }
    } else {
      Constants.Simulation.stepDelay
    }
  } else {
    // Even if not skipping, first scene should have a healthy delay for the pan (min 3s)
    if isFirstScene {
      Js.Math.max_int(Constants.Simulation.stepDelay, 3000)
    } else {
      Constants.Simulation.stepDelay
    }
  }
}

let generate = (initialState: state, skipAutoForward: bool): manifest => {
  // Create initial simulation state
  let initialSimState = {
    ...initialState,
    simulation: {
      ...initialState.simulation,
      status: Running,
      visitedScenes: [],
      skipAutoForwardGlobal: skipAutoForward
    },
    activeIndex: if initialState.activeIndex < 0 && Array.length(initialState.scenes) > 0 { 0 } else { initialState.activeIndex }
  }

  let maxSteps = 100

  let rec loop = (currentState: state, steps: array<step>, count: int) => {
    if count >= maxSteps {
      Console.warn("SimulationManifest generation hit max steps limit")
      steps
    } else {
      switch Belt.Array.get(currentState.scenes, currentState.activeIndex) {
      | Some(currentScene) =>
        let isFirstScene = Array.length(currentState.simulation.visitedScenes) <= 1

        // Update visited scenes
        let currentVisited = currentState.simulation.visitedScenes
        let updatedVisited = if !Array.includes(currentVisited, currentState.activeIndex) {
          Belt.Array.concat(currentVisited, [currentState.activeIndex])
        } else {
          currentVisited
        }

        // Update state with visited for getNextMove
        let stateForMove = {
          ...currentState,
          simulation: {
            ...currentState.simulation,
            visitedScenes: updatedVisited
          }
        }

        let waitDuration = calculateWaitDuration(currentScene, isFirstScene, skipAutoForward)

        let move = SimulationMainLogic.getNextMove(stateForMove)

        switch move {
        | Move({targetIndex, hotspotIndex, yaw, pitch, hfov, triggerActions: _}) =>
          let targetSceneId = switch Belt.Array.get(currentState.scenes, targetIndex) {
          | Some(s) => s.id
          | None => ""
          }

          let step: step = {
            sceneId: currentScene.id,
            sceneIndex: currentState.activeIndex,
            action: Wait({duration: waitDuration}),
            transition: Some({
              targetSceneId: targetSceneId,
              targetIndex: targetIndex,
              hotspotIndex: hotspotIndex,
              targetYaw: yaw,
              targetPitch: pitch,
              targetHfov: hfov,
            })
          }

          let nextVisited = if !Array.includes(updatedVisited, targetIndex) {
             Belt.Array.concat(updatedVisited, [targetIndex])
          } else {
             updatedVisited
          }

          let nextState = {
            ...stateForMove,
            activeIndex: targetIndex,
            simulation: {
              ...stateForMove.simulation,
              visitedScenes: nextVisited
            }
          }

          loop(nextState, Belt.Array.concat(steps, [step]), count + 1)

        | Complete(_) | None =>
          let step: step = {
            sceneId: currentScene.id,
            sceneIndex: currentState.activeIndex,
            action: Wait({duration: waitDuration}),
            transition: None
          }
          Belt.Array.concat(steps, [step])
        }
      | None => steps
      }
    }
  }

  let steps = loop(initialSimState, [], 0)

  {
    version: 1,
    steps: steps,
  }
}
