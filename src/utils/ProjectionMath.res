/* src/utils/ProjectionMath.res */
open ReBindings
open HotspotLineTypes

let degToRad = Math.Constants.pi /. 180.0
let toRad = deg => deg *. degToRad

type projState = {
  aspectRatio: float,
  halfTanHfov: float,
  halfTanVfov: float,
  invHalfTanHfov: float,
  invHalfTanVfov: float,
}

type camState = {
  yaw: float,
  pitch: float,
  hfov: float,
  proj: projState,
}

// Internal cache for projection state to avoid re-calculation
let lastProjState = ref(None)

let getProjState = (hfov, rect: Dom.rect) => {
  switch lastProjState.contents {
  | Some((h, w, h_, state)) if h == hfov && w == rect.width && h_ == rect.height => state
  | _ =>
    let hfovRad = hfov *. degToRad
    let aspectRatio = rect.width /. rect.height
    let halfTanHfov = Math.tan(hfovRad /. 2.0)

    // vfov calculation: tan(vfov/2) = tan(hfov/2) / aspectRatio
    let halfTanVfov = halfTanHfov /. aspectRatio

    let invHalfTanHfov = if halfTanHfov != 0.0 {
      1.0 /. halfTanHfov
    } else {
      0.0
    }

    let invHalfTanVfov = if halfTanVfov != 0.0 {
      1.0 /. halfTanVfov
    } else {
      0.0
    }

    let state = {
      aspectRatio,
      halfTanHfov,
      halfTanVfov,
      invHalfTanHfov,
      invHalfTanVfov,
    }
    lastProjState := Some((hfov, rect.width, rect.height, state))
    state
  }
}

// Pure factory for camState, decoupling from Viewer module
let makeCamState = (yaw, pitch, hfov, rect: Dom.rect) => {
  let proj = getProjState(hfov, rect)
  {
    yaw,
    pitch,
    hfov,
    proj,
  }
}

// Core projection logic
let getScreenCoords = (cam: camState, targetPitch, targetYaw, rect: Dom.rect): option<
  screenCoords,
> => {
  let diff = ref(targetYaw -. cam.yaw)
  while diff.contents > 180.0 {
    diff := diff.contents -. 360.0
  }
  while diff.contents < -180.0 {
    diff := diff.contents +. 360.0
  }

  let yawRad = diff.contents *. degToRad
  let pitchRad = (targetPitch -. cam.pitch) *. degToRad

  let cosYaw = Math.cos(yawRad)

  if cosYaw <= 0.0 || cam.hfov <= 0.0 {
    None
  } else {
    // Optimization: (1 / cosYaw) is used for both X and Y in many projection variants
    // Here we use it to scale the tangent results.
    let invCosYaw = 1.0 /. cosYaw
    let x = Math.tan(yawRad) *. cam.proj.invHalfTanHfov
    let y = Math.tan(pitchRad) *. (cam.proj.invHalfTanVfov *. invCosYaw)

    if !Float.isFinite(x) || !Float.isFinite(y) {
      None
    } else {
      let screenX = rect.width /. 2.0 *. (1.0 +. x)
      let screenY = rect.height /. 2.0 *. (1.0 -. y)

      Some({
        x: screenX,
        y: screenY,
      })
    }
  }
}
