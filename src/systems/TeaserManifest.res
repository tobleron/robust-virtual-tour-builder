/* src/systems/TeaserManifest.res */
open Types

let moduleName = "TeaserManifest"

let simulationCrossfadeMs = 1000
let simulationIntroPanMs = 2000

let pickWaypointHotspot = (scene: scene): option<hotspot> => {
  let waypointCandidates = scene.hotspots->Belt.Array.keep(h =>
    switch h.waypoints {
    | Some(w) => Belt.Array.length(w) > 0
    | None => false
    }
  )

  waypointCandidates
  ->Belt.Array.getBy(h => h.isReturnLink != Some(true))
  ->Option.orElse(waypointCandidates->Belt.Array.get(0))
  ->Option.orElse(
    scene.hotspots
    ->Belt.Array.getBy(h => h.isReturnLink != Some(true))
    ->Option.orElse(scene.hotspots->Belt.Array.get(0)),
  )
}

let getSceneWaypointPose = (scene: scene): viewFrame => {
  let fallback = {
    yaw: 0.0,
    pitch: 0.0,
    hfov: ViewerSystem.getCorrectHfov(),
  }

  pickWaypointHotspot(scene)
  ->Option.map(h => {
    yaw: h.startYaw->Option.getOr(h.yaw),
    pitch: h.startPitch->Option.getOr(h.pitch),
    hfov: h.startHfov->Option.getOr(h.targetHfov->Option.getOr(ViewerSystem.getCorrectHfov())),
  })
  ->Option.getOr(fallback)
}

let getInitialPose = (state: state, activeIndex: int, includeIntroPan: bool): viewFrame => {
  if includeIntroPan {
    {
      yaw: state.activeYaw,
      pitch: state.activePitch,
      hfov: ViewerSystem.getCorrectHfov(),
    }
  } else {
    switch Belt.Array.get(state.scenes, activeIndex) {
    | Some(scene) => getSceneWaypointPose(scene)
    | None => {
        yaw: state.activeYaw,
        pitch: state.activePitch,
        hfov: ViewerSystem.getCorrectHfov(),
      }
    }
  }
}

let addVisited = (visited: array<int>, idx: int): array<int> => {
  if Array.includes(visited, idx) {
    visited
  } else {
    Belt.Array.concat(visited, [idx])
  }
}

let applyVisitedActions = (visited: array<int>, actions: array<Actions.action>): array<int> => {
  actions->Belt.Array.reduce(visited, (acc, a) =>
    switch a {
    | AddVisitedScene(idx) => addVisited(acc, idx)
    | _ => acc
    }
  )
}

let calculateSimulationWaitDuration = (
  scene: scene,
  isFirstScene: bool,
  skipAutoForward: bool,
  includeIntroPan: bool,
): int => {
  let baseWait = if skipAutoForward {
    if scene.isAutoForward {
      if isFirstScene {
        3000
      } else {
        0
      }
    } else {
      Constants.Simulation.stepDelay
    }
  } else {
    Math.Int.max(Constants.Simulation.stepDelay, 3000)
  }

  if isFirstScene && !includeIntroPan {
    if baseWait > simulationIntroPanMs {
      baseWait - simulationIntroPanMs
    } else {
      0
    }
  } else {
    baseWait
  }
}

let generateSimulationParityManifest = (
  initialState: state,
  ~skipAutoForward: bool=false,
  ~includeIntroPan: bool=false,
): motionManifest => {
  let sceneCount = Belt.Array.length(initialState.scenes)
  let startIndex = if sceneCount == 0 {
    -1
  } else if initialState.activeIndex >= 0 && initialState.activeIndex < sceneCount {
    initialState.activeIndex
  } else {
    0
  }

  if startIndex == -1 {
    {
      version: "motion-spec-v1",
      fps: Constants.Teaser.frameRate,
      canvasWidth: Constants.Teaser.canvasWidth,
      canvasHeight: Constants.Teaser.canvasHeight,
      includeIntroPan,
      shots: [],
    }
  } else {
    let initialPose = getInitialPose(initialState, startIndex, includeIntroPan)
    let initialSimState: state = {
      ...initialState,
      activeIndex: startIndex,
      simulation: {
        ...initialState.simulation,
        status: Running,
        visitedScenes: [],
        skipAutoForwardGlobal: skipAutoForward,
      },
    }

    let maxSteps = 1000

    let rec buildShots = (
      currentState: state,
      currentPose: viewFrame,
      acc: array<motionShot>,
      count: int,
    ): array<motionShot> => {
      if count >= maxSteps {
        Logger.warn(
          ~module_=moduleName,
          ~message="SIM_PARITY_MANIFEST_MAX_STEPS_REACHED",
          ~data=Some(Logger.castToJson({"maxSteps": maxSteps})),
          (),
        )
        acc
      } else {
        switch Belt.Array.get(currentState.scenes, currentState.activeIndex) {
        | None => acc
        | Some(currentScene) =>
          let visitedWithCurrent = addVisited(
            currentState.simulation.visitedScenes,
            currentState.activeIndex,
          )
          let stateWithCurrent = {
            ...currentState,
            simulation: {
              ...currentState.simulation,
              visitedScenes: visitedWithCurrent,
            },
          }
          let isFirstScene = Belt.Array.length(visitedWithCurrent) <= 1
          let waitBeforePanMs = calculateSimulationWaitDuration(
            currentScene,
            isFirstScene,
            skipAutoForward,
            includeIntroPan,
          )

          switch SimulationMainLogic.getNextMove(stateWithCurrent) {
          | Move({targetIndex, hotspotIndex, yaw, pitch, hfov, triggerActions}) =>
            let pathData = NavigationGraph.calculatePathData(
              stateWithCurrent,
              stateWithCurrent.activeIndex,
              hotspotIndex,
              targetIndex,
              yaw,
              pitch,
              hfov,
              (currentPose.yaw, currentPose.pitch, currentPose.hfov),
            )

            let shot: motionShot = {
              sceneId: currentScene.id,
              arrivalPose: currentPose,
              animationSegments: [],
              transitionOut: Some({type_: "crossfade", durationMs: simulationCrossfadeMs}),
              pathData,
              waitBeforePanMs,
              blinkAfterPanMs: Constants.blinkDurationSimulation,
            }

            let visitedAfterMove = applyVisitedActions(visitedWithCurrent, triggerActions)
            let nextState = {
              ...stateWithCurrent,
              activeIndex: targetIndex,
              simulation: {
                ...stateWithCurrent.simulation,
                visitedScenes: visitedAfterMove,
              },
            }
            let nextPose = {yaw, pitch, hfov}

            buildShots(nextState, nextPose, Belt.Array.concat(acc, [shot]), count + 1)

          | Complete(_) | None =>
            let finalShot: motionShot = {
              sceneId: currentScene.id,
              arrivalPose: currentPose,
              animationSegments: [],
              transitionOut: None,
              pathData: None,
              waitBeforePanMs,
              blinkAfterPanMs: 0,
            }
            Belt.Array.concat(acc, [finalShot])
          }
        }
      }
    }

    let shots = buildShots(initialSimState, initialPose, [], 0)

    Logger.info(
      ~module_=moduleName,
      ~message="SIM_PARITY_MANIFEST_GENERATED",
      ~data=Some(
        Logger.castToJson({
          "shots": Belt.Array.length(shots),
          "skipAutoForward": skipAutoForward,
          "includeIntroPan": includeIntroPan,
        }),
      ),
      (),
    )

    {
      version: "motion-spec-v1",
      fps: Constants.Teaser.frameRate,
      canvasWidth: Constants.Teaser.canvasWidth,
      canvasHeight: Constants.Teaser.canvasHeight,
      includeIntroPan,
      shots,
    }
  }
}

/* Legacy style-based generator retained for compatibility with existing tests and tooling. */
let generateManifest = (
  scenes: array<scene>,
  steps: array<step>,
  style: string,
  config: TeaserStyleConfig.teaserConfig,
): motionManifest => {
  Logger.debug(
    ~module_=moduleName,
    ~message="GENERATING_LEGACY_STYLE_MANIFEST",
    ~data=Some(
      Logger.castToJson({
        "steps": Belt.Array.length(steps),
        "style": style,
      }),
    ),
    (),
  )

  let shots = steps->Belt.Array.map(step => {
    let scene = scenes->Belt.Array.get(step.idx)->Option.getOrThrow

    let (iy, ip) = if style == "punchy" || style == "cinematic" {
      (step.arrivalView.yaw, step.arrivalView.pitch)
    } else {
      step.transitionTarget
      ->Option.map(t => (t.yaw -. config.cameraPanOffset, t.pitch))
      ->Option.getOr((step.arrivalView.yaw, step.arrivalView.pitch))
    }

    let startPose = {yaw: iy, pitch: ip, hfov: Constants.globalHfov}

    let animationSegments = if style == "punchy" || style == "cinematic" {
      [
        {
          startYaw: iy,
          endYaw: iy,
          startPitch: ip,
          endPitch: ip,
          startHfov: Constants.globalHfov,
          endHfov: Constants.globalHfov,
          easing: "linear",
          durationMs: Belt.Float.toInt(config.clipDuration),
        },
      ]
    } else {
      switch step.transitionTarget {
      | Some(t) => [
          {
            startYaw: iy,
            endYaw: t.yaw,
            startPitch: ip,
            endPitch: t.pitch,
            startHfov: Constants.globalHfov,
            endHfov: Constants.globalHfov,
            easing: "linear",
            durationMs: Belt.Float.toInt(config.clipDuration),
          },
        ]
      | None => [
          {
            startYaw: iy,
            endYaw: iy,
            startPitch: ip,
            endPitch: ip,
            startHfov: Constants.globalHfov,
            endHfov: Constants.globalHfov,
            easing: "linear",
            durationMs: Belt.Float.toInt(config.clipDuration),
          },
        ]
      }
    }

    {
      sceneId: scene.id,
      arrivalPose: startPose,
      animationSegments,
      transitionOut: Some({
        type_: "crossfade",
        durationMs: Belt.Float.toInt(config.transitionDuration),
      }),
      pathData: None,
      waitBeforePanMs: 0,
      blinkAfterPanMs: 0,
    }
  })

  {
    version: "motion-spec-v1",
    fps: Constants.Teaser.frameRate,
    canvasWidth: Constants.Teaser.canvasWidth,
    canvasHeight: Constants.Teaser.canvasHeight,
    includeIntroPan: false,
    shots,
  }
}

let calculateShotDuration = (shot: motionShot): float => {
  let waitDuration = Belt.Int.toFloat(shot.waitBeforePanMs)
  let blinkDuration = Belt.Int.toFloat(shot.blinkAfterPanMs)
  let transitionDuration =
    shot.transitionOut->Option.map(t => Belt.Int.toFloat(t.durationMs))->Option.getOr(0.0)

  let motionDuration = switch shot.pathData {
  | Some(pd) => pd.panDuration
  | None =>
    shot.animationSegments->Belt.Array.reduce(0.0, (acc, seg) =>
      acc +. Belt.Int.toFloat(seg.durationMs)
    )
  }

  waitDuration +. motionDuration +. blinkDuration +. transitionDuration
}

let calculateTotalManifestDuration = (manifest: motionManifest): float => {
  manifest.shots->Belt.Array.reduce(0.0, (acc, shot) => acc +. calculateShotDuration(shot))
}

let init = () => {
  Logger.initialized(~module_=moduleName)
}
