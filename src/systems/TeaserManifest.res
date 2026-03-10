/* src/systems/TeaserManifest.res */
open Types

let moduleName = "TeaserManifest"

let simulationCrossfadeMs = 1000
let simulationIntroPanMs = 2000

let pickWaypointHotspot = (scene: scene): option<hotspot> => {
  TeaserManifestSupport.pickWaypointHotspot(scene)
}

let getSceneWaypointPose = (scene: scene): viewFrame => {
  TeaserManifestSupport.getSceneWaypointPose(scene)
}

let getInitialPose = (state: state, activeIndex: int, includeIntroPan: bool): viewFrame => {
  TeaserManifestSupport.getInitialPose(state, activeIndex, includeIntroPan)
}

let addVisited = (visited: array<string>, linkId: string): array<string> => {
  TeaserManifestSupport.addVisited(visited, linkId)
}

let applyVisitedActions = (visited: array<string>, actions: array<Actions.action>): array<
  string,
> => {
  TeaserManifestSupport.applyVisitedActions(visited, actions)
}

let calculateSimulationWaitDuration = (
  scene: scene,
  isFirstScene: bool,
  skipAutoForward: bool,
  includeIntroPan: bool,
): int => {
  TeaserManifestSupport.calculateSimulationWaitDuration(
    scene,
    isFirstScene,
    skipAutoForward,
    includeIntroPan,
    ~simulationIntroPanMs,
  )
}

let generateSimulationParityManifest = (
  initialState: state,
  ~skipAutoForward: bool=false,
  ~includeIntroPan: bool=false,
): motionManifest => {
  let activeScenes = SceneInventory.getActiveScenes(initialState.inventory, initialState.sceneOrder)
  let sceneCount = Belt.Array.length(activeScenes)
  let startIndex = if sceneCount == 0 {
    -1
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
        visitedLinkIds: [],
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
        let activeScenes = SceneInventory.getActiveScenes(
          currentState.inventory,
          currentState.sceneOrder,
        )
        switch Belt.Array.get(activeScenes, currentState.activeIndex) {
        | None => acc
        | Some(currentScene) =>
          // Note: We track linkIds, not scene indices
          // The visitedLinkIds is updated by getNextMove via AddVisitedLink action
          let visitedLinkIds = currentState.simulation.visitedLinkIds
          let stateWithVisited = {
            ...currentState,
            simulation: {
              ...currentState.simulation,
              visitedLinkIds,
            },
          }
          let isFirstScene = Belt.Array.length(visitedLinkIds) <= 1
          let waitBeforePanMs = calculateSimulationWaitDuration(
            currentScene,
            isFirstScene,
            skipAutoForward,
            includeIntroPan,
          )

          switch SimulationMainLogic.getNextMove(stateWithVisited) {
          | Move({targetIndex, hotspotIndex, yaw, pitch, hfov, triggerActions}) =>
            let pathData = NavigationGraph.calculatePathData(
              stateWithVisited,
              stateWithVisited.activeIndex,
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

            let visitedAfterMove = applyVisitedActions(visitedLinkIds, triggerActions)
            let nextState = {
              ...stateWithVisited,
              activeIndex: targetIndex,
              simulation: {
                ...stateWithVisited.simulation,
                visitedLinkIds: visitedAfterMove,
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

  let shots =
    steps->Belt.Array.map(step =>
      TeaserManifestSupport.buildLegacyShot(~scenes, ~step, ~style, ~config)
    )

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
