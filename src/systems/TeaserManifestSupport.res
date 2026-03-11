// @efficiency-role: domain-logic

open Types

let pickWaypointHotspot = (scene: scene): option<hotspot> => {
  let waypointCandidates = scene.hotspots->Belt.Array.keep(h =>
    switch h.waypoints {
    | Some(w) => Belt.Array.length(w) > 0
    | None => false
    }
  )

  waypointCandidates->Belt.Array.get(0)->Option.orElse(scene.hotspots->Belt.Array.get(0))
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
    let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
    switch Belt.Array.get(activeScenes, activeIndex) {
    | Some(scene) => getSceneWaypointPose(scene)
    | None => {
        yaw: state.activeYaw,
        pitch: state.activePitch,
        hfov: ViewerSystem.getCorrectHfov(),
      }
    }
  }
}

let addVisited = (visited: array<string>, linkId: string): array<string> => {
  if Array.includes(visited, linkId) {
    visited
  } else {
    Belt.Array.concat(visited, [linkId])
  }
}

let applyVisitedActions = (visited: array<string>, actions: array<Actions.action>): array<
  string,
> => {
  actions->Belt.Array.reduce(visited, (acc, a) =>
    switch a {
    | Actions.AddVisitedLink(linkId) => addVisited(acc, linkId)
    | _ => acc
    }
  )
}

let calculateSimulationWaitDuration = (
  scene: scene,
  isFirstScene: bool,
  skipAutoForward: bool,
  includeIntroPan: bool,
  ~simulationIntroPanMs: int,
): int => {
  let hasAutoForwardLink = Belt.Array.some(scene.hotspots, h =>
    switch h.isAutoForward {
    | Some(true) => true
    | _ => false
    }
  )
  let isAutoForward = hasAutoForwardLink || scene.isAutoForward

  let baseWait = if skipAutoForward {
    if isAutoForward {
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

let buildLegacyShot = (
  ~scenes: array<scene>,
  ~step: step,
  ~style: string,
  ~config: TeaserStyleConfig.teaserConfig,
): motionShot => {
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
}
