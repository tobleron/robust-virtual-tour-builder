open Types

type headlessMotionProfile = {
  skipAutoForward: bool,
  startAtWaypoint: bool,
  includeIntroPan: bool,
}

external castHeadlessMotionProfile: 'a => headlessMotionProfile = "%identity"

let readHeadlessMotionProfile = (): headlessMotionProfile =>
  castHeadlessMotionProfile(
    %raw(`(() => {
      const p = (typeof window !== "undefined" && window.__VTB_HEADLESS_MOTION_PROFILE__) ? window.__VTB_HEADLESS_MOTION_PROFILE__ : {};
      return {
        skipAutoForward: typeof p.skipAutoForward === "boolean" ? p.skipAutoForward : false,
        startAtWaypoint: typeof p.startAtWaypoint === "boolean" ? p.startAtWaypoint : true,
        includeIntroPan: typeof p.includeIntroPan === "boolean" ? p.includeIntroPan : false
      };
    })()`),
  )

let readMotionManifest = (): option<motionManifest> => {
  let raw = %raw(`window.__VTB_MOTION_MANIFEST__`)
  if %raw(`(m => m !== null && typeof m === 'object')(raw)`) {
    switch JsonCombinators.Json.decode(raw, JsonParsers.Domain.motionManifest) {
    | Ok(m) => Some(m)
    | Error(msg) =>
      Logger.error(
        ~module_="TeaserLogic",
        ~message="MANIFEST_DECODE_FAILED",
        ~data=Some(Logger.castToJson({"error": msg})),
        (),
      )
      None
    }
  } else {
    None
  }
}

let resolveTeaserStartView = (state: state): option<(float, float, float)> => {
  let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
  Belt.Array.get(activeScenes, state.activeIndex)->Option.flatMap(scene => {
    let waypointCandidates = scene.hotspots->Belt.Array.keep(h =>
      switch h.waypoints {
      | Some(w) => Belt.Array.length(w) > 0
      | None => false
      }
    )
    let candidate =
      waypointCandidates->Belt.Array.get(0)->Option.orElse(scene.hotspots->Belt.Array.get(0))

    candidate->Option.map(h => (
      h.startYaw->Option.getOr(h.yaw),
      h.startPitch->Option.getOr(h.pitch),
      h.startHfov->Option.getOr(h.targetHfov->Option.getOr(ViewerSystem.getCorrectHfov())),
    ))
  })
}

type teaserProgressMetrics = {
  renderedFrame: option<int>,
  totalFrames: option<int>,
  etaSecondsFromMessage: option<int>,
}

let parseTeaserProgressMetrics = (msg: string): teaserProgressMetrics => {
  let primary =
    msg
    ->String.split("|")
    ->Belt.Array.get(0)
    ->Option.getOr("")
    ->String.trim
  let secondary =
    msg
    ->String.split("|")
    ->Belt.Array.get(1)
    ->Option.getOr("")
    ->String.trim

  let (renderedFrame, totalFrames) = if String.startsWith(primary, "Rendering frame ") {
    let rawPair = primary->String.split("Rendering frame ")->Belt.Array.get(1)->Option.getOr("")
    let pair = rawPair->String.split(" / ")
    switch (
      pair->Belt.Array.get(0)->Option.flatMap(Belt.Int.fromString),
      pair->Belt.Array.get(1)->Option.flatMap(Belt.Int.fromString),
    ) {
    | (Some(done), Some(total)) if total > 0 => (Some(done), Some(total))
    | _ => (None, None)
    }
  } else {
    (None, None)
  }

  {
    renderedFrame,
    totalFrames,
    etaSecondsFromMessage: EtaSupport.parseEtaTextSeconds(secondary),
  }
}

let signalIsAborted = signal =>
  switch signal {
  | Some(sig) => BrowserBindings.AbortSignal.aborted(sig)
  | None => false
  }
