/* src/utils/ViewerTripodDeadZone.res */

open ReBindings

let referenceSafePitch = -30.0
let maxPitch = 90.0
let defaultAspectRatio = 16.0 /. 9.0
let portraitSafetyMargin = 14.0

let toRadians = degrees => degrees *. Math.Constants.pi /. 180.0
let toDegrees = radians => radians *. 180.0 /. Math.Constants.pi

let resolveAspectRatio = (~aspectRatio: float): float => {
  if aspectRatio > 0.0 && Float.isFinite(aspectRatio) {
    aspectRatio
  } else {
    defaultAspectRatio
  }
}

let resolveSafetyMargin = (~aspectRatio: float): float => {
  let safeAspectRatio = resolveAspectRatio(~aspectRatio)
  if safeAspectRatio < 1.0 {
    portraitSafetyMargin
  } else {
    0.0
  }
}

let safePitchForHfov = (~hfov: float, ~aspectRatio: float): float => {
  let safeAspectRatio = resolveAspectRatio(~aspectRatio)
  let vfov =
    2.0 *.
    toDegrees(Math.atan(Math.tan(toRadians(hfov) /. 2.0) /. safeAspectRatio))
  referenceSafePitch -. (vfov /. 2.0) +. resolveSafetyMargin(~aspectRatio=safeAspectRatio)
}

let safePitchBoundsForHfov = (~hfov: float, ~aspectRatio: float): (float, float) => {
  (safePitchForHfov(~hfov, ~aspectRatio), maxPitch)
}

let safePitchBoundsForViewport = (~hfov: float): (float, float) => {
  let aspectRatio =
    switch Dom.getElementById("viewer-stage")->Nullable.toOption {
    | Some(stage) =>
      let rect = Dom.getBoundingClientRect(stage)
      if rect.width > 0.0 && rect.height > 0.0 {
        rect.width /. rect.height
      } else {
        defaultAspectRatio
      }
    | None => defaultAspectRatio
  }
  safePitchBoundsForHfov(~hfov, ~aspectRatio)
}

let applyPitchBounds = (~viewer: ReBindings.Viewer.t, ~hfov: float) => {
  let (minPitch, maxPitch) = safePitchBoundsForViewport(~hfov)
  ViewerSystem.Adapter.setPitchBounds(viewer, [minPitch, maxPitch])
}
