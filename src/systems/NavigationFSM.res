/* src/systems/NavigationFSM.res */

/**
 * Navigation Finite State Machine (FSM)
 * Centralizes the complex micro-states of the scene navigation lifecycle.
 */
type distinctState =
  | Idle
  | Cooldown({targetSceneId: string, remaining: float}) // Waiting for animation/fade to finish
  | Preloading({targetSceneId: string, attempt: int, isAnticipatory: bool})
  | Transitioning({fromSceneId: option<string>, toSceneId: string, progress: float})
  | Stabilizing({targetSceneId: string}) // Loaded, waiting for texture execution
  | Error({code: string, recoveryTarget: option<string>})

type event =
  | UserClickedScene({targetSceneId: string})
  | StartAnticipatoryLoad({targetSceneId: string})
  | PreloadStarted({targetSceneId: string})
  | TextureLoaded({targetSceneId: string})
  | AnimationProgress(float)
  | TransitionComplete
  | StabilizeComplete
  | LoadTimeout
  | RecoveryTriggered({targetSceneId: string})
  | Reset

/**
 * Pure reducer for navigation state transitions.
 * Enforces legal transitions and eliminates race conditions.
 */
let reducer = (state: distinctState, event: event): distinctState => {
  switch (state, event) {
  | (_, Reset) => Idle

  | (Idle, UserClickedScene({targetSceneId})) =>
    Preloading({targetSceneId, attempt: 1, isAnticipatory: false})

  | (Idle, StartAnticipatoryLoad({targetSceneId})) =>
    Preloading({targetSceneId, attempt: 1, isAnticipatory: true})

  | (Preloading({targetSceneId, isAnticipatory}), TextureLoaded({targetSceneId: loadedId}))
    if targetSceneId == loadedId =>
    if isAnticipatory {
      Idle
    } else {
      Transitioning({fromSceneId: None, toSceneId: targetSceneId, progress: 0.0})
    }

  | (Preloading({targetSceneId}), LoadTimeout) =>
    Error({code: "TIMEOUT", recoveryTarget: Some(targetSceneId)})

  | (Transitioning({fromSceneId, toSceneId, progress: _}), AnimationProgress(progress)) =>
    if progress >= 1.0 {
      Stabilizing({targetSceneId: toSceneId})
    } else {
      Transitioning({fromSceneId, toSceneId, progress})
    }

  | (Transitioning({toSceneId, _}), TransitionComplete) => Stabilizing({targetSceneId: toSceneId})

  | (Stabilizing({targetSceneId: _targetSceneId}), StabilizeComplete) => Idle

  | (Error({recoveryTarget: Some(target)}), RecoveryTriggered({targetSceneId}))
    if target == targetSceneId =>
    Preloading({targetSceneId, attempt: 2, isAnticipatory: false})

  /* Interruptions: v4.7.12 standard - allows rapid navigation to override current transition */
  | (Preloading({targetSceneId: oldId}), UserClickedScene({targetSceneId: newId}))
    if oldId != newId =>
    Preloading({targetSceneId: newId, attempt: 1, isAnticipatory: false})

  | (Transitioning({toSceneId, _}), UserClickedScene({targetSceneId}))
    if targetSceneId != toSceneId =>
    Preloading({targetSceneId, attempt: 1, isAnticipatory: false})

  | (Stabilizing({targetSceneId: oldId}), UserClickedScene({targetSceneId: newId}))
    if oldId != newId =>
    Preloading({targetSceneId: newId, attempt: 1, isAnticipatory: false})

  | _ => state
  }
}

let toString = (state: distinctState): string => {
  switch state {
  | Idle => "Idle"
  | Cooldown({targetSceneId}) => "Cooldown(" ++ targetSceneId ++ ")"
  | Preloading({targetSceneId, isAnticipatory}) =>
    "Preloading(" ++ targetSceneId ++ ", ant=" ++ (isAnticipatory ? "true" : "false") ++ ")"
  | Transitioning({toSceneId, progress}) =>
    "Transitioning(" ++ toSceneId ++ ", p=" ++ Float.toString(progress) ++ ")"
  | Stabilizing({targetSceneId}) => "Stabilizing(" ++ targetSceneId ++ ")"
  | Error({code}) => "Error(" ++ code ++ ")"
  }
}
