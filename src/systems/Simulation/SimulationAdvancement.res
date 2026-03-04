/* src/systems/Simulation/SimulationAdvancement.res */

type decision =
  | Advance
  | Retry({count: int, max: int, backoffMs: int})
  | Wait({reason: string})
  | Stop({reason: string})

type context = {
  isFirstScene: bool,
  currentSceneId: option<string>,
  completedSceneId: option<string>,
  navigationStateIsIdle: bool,
  operationLifecycleIsBusy: bool,
  retryCount: int,
  maxRetries: int,
}

let evaluate = (ctx: context): decision => {
  // 1. Check if system is stable/idle enough to consider advancing
  if !ctx.navigationStateIsIdle {
    Wait({reason: "navigation_not_idle"})
  } else if ctx.operationLifecycleIsBusy {
    Wait({reason: "operation_lifecycle_busy"})
  } else {
    // 2. Check scene continuity / completion signal
    let hasSceneCompletionSignal = switch (ctx.currentSceneId, ctx.completedSceneId) {
    | (Some(current), Some(completed)) => current == completed
    | _ => false
    }

    let shouldAdvance = ctx.isFirstScene || hasSceneCompletionSignal

    if shouldAdvance {
      Advance
    } // 3. Not ready - determine retry strategy
    else if ctx.retryCount <= ctx.maxRetries {
      let backoffMs = 100 * ctx.retryCount
      Retry({
        count: ctx.retryCount + 1,
        max: ctx.maxRetries,
        backoffMs,
      })
    } else {
      Stop({reason: "max_retries_exceeded_waiting_for_signal"})
    }
  }
}
