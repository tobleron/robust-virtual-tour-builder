/* src/systems/TeaserManifest.res */
open Types

let moduleName = "TeaserManifest"

let generateManifest = (
  scenes: array<scene>,
  steps: array<step>,
  style: string,
  config: TeaserStyleConfig.teaserConfig,
): motionManifest => {
  Logger.debug(
    ~module_=moduleName,
    ~message="GENERATING_MANIFEST",
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

let calculateTotalManifestDuration = (manifest: motionManifest): float => {
  manifest.shots->Belt.Array.reduce(0.0, (acc, shot) => {
    let animDur = shot.animationSegments->Belt.Array.reduce(0.0, (sum, seg) => sum +. Belt.Int.toFloat(seg.durationMs))
    let transitDur = shot.transitionOut->Option.map(t => Belt.Int.toFloat(t.durationMs))->Option.getOr(0.0)
    acc +. animDur +. transitDur
  })
}

let init = () => {
  Logger.initialized(~module_=moduleName)
}
