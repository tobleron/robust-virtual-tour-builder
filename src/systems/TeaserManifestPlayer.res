/* src/systems/TeaserManifestPlayer.res */
open ReBindings
open Types
open Actions
open SimulationManifest

// Internal bindings
@val external setTimeout: (unit => unit, int) => int = "setTimeout"

let wait = (ms: int) =>
  Promise.make((resolve, _) => {
    let _ = setTimeout(() => resolve(), ms)
  })

let waitForNavigationComplete = () => {
  Promise.make((resolve, _reject) => {
    let unsubscribe = ref(None)

    let cleanup = () => {
      unsubscribe.contents->Option.forEach(u => u())
    }

    let handler = event => {
      switch event {
      | NavCompleted(_) =>
        cleanup()
        resolve()
      | NavCancelled =>
        cleanup()
        resolve()
      | _ => ()
      }
    }

    unsubscribe := Some(EventBus.subscribe(handler))
  })
}

let throwIfAborted = (signal: option<BrowserBindings.AbortSignal.t>) => {
  signal->Option.forEach(s => {
    if BrowserBindings.AbortSignal.aborted(s) {
      Js.Exn.raiseError(Js.Exn.makeError("AbortError"))
    }
  })
}

let play = async (
  manifest: manifest,
  ~getState: unit => state,
  ~dispatch: action => unit,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
) => {
  let steps = manifest.steps
  let count = Array.length(steps)

  if count > 0 {
    let currentIdx = getState().activeIndex
    let firstStep = steps[0]->Option.getOrThrow

    if currentIdx != firstStep.sceneIndex {
       Console.warn("TeaserManifestPlayer: Starting scene index mismatch")
    }
  }

  for i in 0 to count - 1 {
    throwIfAborted(signal)

    let step = steps[i]->Option.getOrThrow

    // 1. Action Phase (Wait/Pan)
    switch step.action {
    | Wait({duration}) =>
      await wait(duration)
    | Pan({yaw: _, pitch: _, duration}) =>
      // Explicit pan not fully implemented in current simulation
      await wait(duration)
    | Stop => ()
    }

    throwIfAborted(signal)

    // 2. Transition Phase
    switch step.transition {
    | Some(t) =>
      let state = getState()
      // Execute transition
      Scene.Switcher.navigateToScene(
        dispatch,
        state,
        t.targetIndex,
        step.sceneIndex, // source index
        t.hotspotIndex,
        ~targetYaw=t.targetYaw,
        ~targetPitch=t.targetPitch,
        ~targetHfov=t.targetHfov,
        ()
      )

      await waitForNavigationComplete()
    | None => ()
    }
  }
}
