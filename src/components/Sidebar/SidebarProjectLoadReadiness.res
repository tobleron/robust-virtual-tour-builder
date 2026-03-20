let getActiveSceneId = (state: Types.state): option<string> => {
  let scenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
  Belt.Array.get(scenes, state.activeIndex)->Option.map(scene => scene.id)
}

let isProjectViewerReady = (~getState: unit => Types.state): bool => {
  let state = getState()
  switch getActiveSceneId(state) {
  | None => true
  | Some(sceneId) =>
    let fsmIdle = switch state.navigationState.navigationFsm {
    | IdleFsm => true
      | _ => false
      }
    let supervisorIdle = NavigationSupervisor.isIdle()
    let viewerReady = ViewerSystem.getActiveViewerReadyForScene(sceneId)->Option.isSome
    fsmIdle && supervisorIdle && viewerReady
  }
}

let delayMs = (ms: int): Promise.t<unit> =>
  Promise.make((resolve, _reject) => {
    ignore(ReBindings.Window.setTimeout(() => resolve(), ms))
  })

let readinessStableWindowMs = 3000
let longTaskQuietWindowMs = 1200.0
let maxFrameGapMs = 60.0
let minStableFrames = 60

let waitForStableInteractivity = (
  ~getState: unit => Types.state,
  ~opId: OperationLifecycle.operationId,
  ~startedAt: float,
  ~maxWaitMs: int,
): Promise.t<result<unit, string>> =>
  Promise.make((resolve, _reject) => {
    let rafIdRef: ref<option<int>> = ref(None)
    let lastFrameAtRef: ref<option<float>> = ref(None)
    let stableStartedAtRef: ref<option<float>> = ref(None)
    let stableFrameCountRef = ref(0)
    let lastLongTaskAtRef: ref<option<float>> = ref(None)
    let lastBlockReasonRef = ref("awaiting_stable_frames")
    let finishedRef = ref(false)

    let onLongTask = (_event: ReBindings.Dom.event) => {
      lastLongTaskAtRef := Some(Date.now())
      lastBlockReasonRef := "recent_long_task"
    }

    let cleanup = () => {
      rafIdRef.contents->Option.forEach(ReBindings.Window.cancelAnimationFrame)
      ReBindings.Window.removeEventListener("vtb-long-task", onLongTask)
    }

    let finish = (result: result<unit, string>) => {
      if !finishedRef.contents {
        finishedRef := true
        cleanup()
        resolve(result)
      }
    }

    let rec frame = () => {
      if !finishedRef.contents {
        let now = Date.now()
        let elapsed = now -. startedAt

        if elapsed >= maxWaitMs->Int.toFloat {
          finish(
            Error(
              "Viewer stabilization timed out after " ++
              Belt.Int.toString(maxWaitMs / 1000) ++
              "s (" ++
              lastBlockReasonRef.contents ++
              ").",
            ),
          )
        } else {
          let viewerReady = isProjectViewerReady(~getState)
          let frameGapOk = switch lastFrameAtRef.contents {
          | Some(lastFrameAt) => now -. lastFrameAt <= maxFrameGapMs
          | None => true
          }
          let quietSinceLongTask = switch lastLongTaskAtRef.contents {
          | Some(lastLongTaskAt) => now -. lastLongTaskAt >= longTaskQuietWindowMs
          | None => true
          }
          let isStableFrame = viewerReady && frameGapOk && quietSinceLongTask

          if isStableFrame {
            if stableStartedAtRef.contents == None {
              stableStartedAtRef := Some(now)
              stableFrameCountRef := 0
            }

            stableFrameCountRef := stableFrameCountRef.contents + 1
            let stableElapsed = switch stableStartedAtRef.contents {
            | Some(stableStartedAt) => now -. stableStartedAt
            | None => 0.0
            }

            if OperationLifecycle.isActive(opId) {
              OperationLifecycle.progress(
                opId,
                99.0,
                ~message="Stabilizing interface...",
                ~phase="Project Load",
                (),
              )
            }

            if (
              stableElapsed >= readinessStableWindowMs->Int.toFloat &&
                stableFrameCountRef.contents >= minStableFrames
            ) {
              finish(Ok())
            } else {
              lastFrameAtRef := Some(now)
              rafIdRef := Some(ReBindings.Window.requestAnimationFrame(frame))
            }
          } else {
            stableStartedAtRef := None
            stableFrameCountRef := 0
            lastBlockReasonRef := if !viewerReady {
              "viewer_not_ready"
            } else if !quietSinceLongTask {
              "recent_long_task"
            } else {
              "slow_frame_gap"
            }

            if OperationLifecycle.isActive(opId) {
              OperationLifecycle.progress(
                opId,
                98.0,
                ~message="Waiting for interface to settle...",
                ~phase="Project Load",
                (),
              )
            }

            lastFrameAtRef := Some(now)
            rafIdRef := Some(ReBindings.Window.requestAnimationFrame(frame))
          }
        }
      }
    }

    ReBindings.Window.addEventListener("vtb-long-task", onLongTask)
    rafIdRef := Some(ReBindings.Window.requestAnimationFrame(frame))
  })

let waitForProjectReady = (
  ~getState: unit => Types.state,
  ~opId: OperationLifecycle.operationId,
  ~maxWaitMs=60000,
  ~pollIntervalMs=80,
): Promise.t<result<unit, string>> => {
  let startedAt = Date.now()

  let rec poll = (): Promise.t<result<unit, string>> => {
    if isProjectViewerReady(~getState) {
      waitForStableInteractivity(~getState, ~opId, ~startedAt, ~maxWaitMs)
    } else {
      let elapsed = Date.now() -. startedAt
      if elapsed >= maxWaitMs->Int.toFloat {
        Promise.resolve(Error("Viewer readiness timed out; continuing with current state."))
      } else {
        if OperationLifecycle.isActive(opId) {
          let pct = 90.0 +. Math.min(9.0, elapsed /. maxWaitMs->Int.toFloat *. 9.0)
          OperationLifecycle.progress(
            opId,
            pct,
            ~message="Preparing viewer...",
            ~phase="Project Load",
            (),
          )
        }
        delayMs(pollIntervalMs)->Promise.then(_ => poll())
      }
    }
  }

  poll()
}
