/* src/systems/Navigation/NavigationFSM.res */
// @efficiency-role: domain-logic

/**
 * Navigation Finite State Machine (FSM)
 * Controls the decoupled transition between scenes, handling preloading, 
 * fading, and stabilization.
 */
type preloadTarget = {
  targetSceneId: string,
  attempt: int,
  isAnticipatory: bool,
}

type transitioningState = {
  fromSceneId: option<string>,
  toSceneId: string,
  progress: float,
}

type errorInfo = {
  code: string,
  recoveryTarget: option<string>,
}

type distinctState =
  | Idle
  | Preloading(preloadTarget)
  | Transitioning(transitioningState)
  | Stabilizing({targetSceneId: string})
  | Error(errorInfo)

type event =
  | UserClickedScene({targetSceneId: string})
  | PreloadStarted({targetSceneId: string})
  | StartAnticipatoryLoad({targetSceneId: string})
  | TextureLoaded({targetSceneId: string})
  | AnimationProgress(float)
  | TransitionComplete
  | StabilizeComplete
  | LoadTimeout
  | RecoveryTriggered({targetSceneId: string})
  | Reset

let reducer = (state: distinctState, action: event): distinctState => {
  switch (state, action) {
  | (Idle, UserClickedScene({targetSceneId})) =>
    Preloading({targetSceneId, attempt: 1, isAnticipatory: false})
  | (Idle, PreloadStarted({targetSceneId})) =>
    Preloading({targetSceneId, attempt: 1, isAnticipatory: false})
  | (Idle, StartAnticipatoryLoad({targetSceneId})) =>
    Preloading({targetSceneId, attempt: 1, isAnticipatory: true})

  | (Preloading(_), UserClickedScene({targetSceneId})) =>
    Preloading({targetSceneId, attempt: 1, isAnticipatory: false})
  | (Preloading(t), TextureLoaded({targetSceneId})) if t.targetSceneId == targetSceneId =>
    if t.isAnticipatory {
      Idle
    } else {
      Transitioning({fromSceneId: None, toSceneId: targetSceneId, progress: 0.0})
    }

  | (Transitioning(s), AnimationProgress(p)) =>
    if p >= 1.0 {
      Stabilizing({targetSceneId: s.toSceneId})
    } else {
      Transitioning({...s, progress: p})
    }
  | (Transitioning(s), TransitionComplete) => Stabilizing({targetSceneId: s.toSceneId})
  | (Transitioning(_), UserClickedScene({targetSceneId})) =>
    Preloading({targetSceneId, attempt: 1, isAnticipatory: false})

  | (Stabilizing(_), TransitionComplete) => Idle
  | (Stabilizing(_), StabilizeComplete) => Idle

  | (Preloading(t), LoadTimeout) => Error({code: "TIMEOUT", recoveryTarget: Some(t.targetSceneId)})

  | (Error(e), RecoveryTriggered({targetSceneId})) =>
    let attempt = switch e.recoveryTarget {
    | Some(id) if id == targetSceneId => 2
    | _ => 1
    }
    Preloading({targetSceneId, attempt, isAnticipatory: false})

  | (_, Reset) => Idle
  | (s, _) => s
  }
}

let toString = (state: distinctState) => {
  switch state {
  | Idle => "Idle"
  | Preloading(_) => "Preloading"
  | Transitioning(_) => "Transitioning"
  | Stabilizing(_) => "Stabilizing"
  | Error(_) => "Error"
  }
}
