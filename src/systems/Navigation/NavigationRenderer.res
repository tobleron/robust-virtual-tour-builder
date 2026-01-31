/* src/systems/Navigation/NavigationRenderer.res */

open Types
open ReBindings
open NavigationFSM

let activeJourneyId = ref(None)

let setupBlinks = () => (
  Float.fromInt(Constants.blinkDurationPreview),
  Float.fromInt(Constants.blinkDurationSimulation),
  Float.fromInt(Constants.blinkRatePreview),
  Float.fromInt(Constants.blinkRateSimulation),
)

let renderJourneyFrame = (v, prog, pd: Types.pathData, asP, asY, aWp, aSeg) => {
  let (cp, cy) = NavigationLogic.calculateCameraPosition(~progress=prog, ~pathData=pd)
  Viewer.setPitch(v, cp, false)
  Viewer.setYaw(v, cy, false)
  Viewer.setHfov(v, pd.startHfov +. (pd.targetHfovForPan -. pd.startHfov) *. prog, false)
  if ViewerSystem.isViewerReady(v) {
    Dom.getElementById("viewer-hotspot-lines")
    ->Nullable.toOption
    ->Option.forEach(svg => {
      let r = Dom.getBoundingClientRect(svg)
      if r.width > 0.0 {
        HotspotLine.Logic.updateSimulationArrow(
          HotspotLine.Logic.getCamState(v, r),
          asP,
          asY,
          pd.targetPitchForPan,
          pd.targetYawForPan,
          prog,
          r,
          ~opacity=1.0,
          ~waypoints=aWp,
          ~preComputedSegments=aSeg,
          ~preComputedTotalDistance=pd.totalPathDistance,
          (),
        )
      }
    })
  }
}

let handleJourneyCompletion = (
  v,
  data: EventBus.navStartPayload,
  pd: Types.pathData,
  bst,
  cft,
  asP,
  asY,
  aWp,
  aSeg,
  loop,
) => {
  let sb = bst.contents->Option.getOr({
    let n = Date.now()
    bst := Some(n)
    n
  })
  let bel = Date.now() -. sb
  let isP = data.previewOnly
  let (bdP, bdS, brP, brS) = setupBlinks()
  let dur = isP ? bdP : bdS
  let rate = isP ? brP : brS
  Viewer.setPitch(v, pd.targetPitchForPan, false)
  Viewer.setYaw(v, pd.targetYawForPan, false)
  Viewer.setHfov(v, pd.targetHfovForPan, false)
  if bel < dur {
    let op = mod(Belt.Float.toInt(bel /. rate), 2) == 0 ? 1.0 : 0.0
    if ViewerSystem.isViewerReady(v) {
      HotspotLine.updateSimulationArrow(
        v,
        asP,
        asY,
        pd.targetPitchForPan,
        pd.targetYawForPan,
        1.0,
        ~opacity=op,
        ~waypoints=aWp,
        ~colorOverride=?isP ? Some("red") : None,
        ~preComputedSegments=aSeg,
        ~preComputedTotalDistance=pd.totalPathDistance,
        (),
      )
    }
    let _ = Window.requestAnimationFrame(loop)
  } else {
    cft := true
    EventBus.dispatch(
      NavCompleted({
        journeyId: data.journeyId,
        targetIndex: data.targetIndex,
        sourceIndex: data.sourceIndex,
        hotspotIndex: data.hotspotIndex,
        arrivalYaw: pd.arrivalYaw,
        arrivalPitch: pd.arrivalPitch,
        arrivalHfov: pd.arrivalHfov,
        previewOnly: data.previewOnly,
        pathData: None,
      }),
    )
  }
}

let prepareSegments = (pd: Types.pathData) => {
  pd.segments->Belt.Array.map(s => (
    s.dist,
    s.yawDiff,
    s.pitchDiff,
    ({PathInterpolation.yaw: s.p1.yaw, pitch: s.p1.pitch}: PathInterpolation.point),
    ({PathInterpolation.yaw: s.p2.yaw, pitch: s.p2.pitch}: PathInterpolation.point),
  ))
}

let prepareWaypoints = (pd: Types.pathData) => {
  pd.waypoints->Belt.Array.map((w): PathInterpolation.point => {
    PathInterpolation.yaw: w.yaw,
    pitch: w.pitch,
  })
}

let rec runJourneyLoop = (
  v,
  data: EventBus.navStartPayload,
  pd,
  bst,
  cft,
  asP,
  asY,
  aWp,
  aSeg,
  st,
  (),
) => {
  if activeJourneyId.contents == Some(data.journeyId) && !cft.contents {
    let elap = Date.now() -. st
    let prog = Math.min(elap /. pd.panDuration, 1.0)
    if prog >= 1.0 {
      handleJourneyCompletion(v, data, pd, bst, cft, asP, asY, aWp, aSeg, () =>
        runJourneyLoop(v, data, pd, bst, cft, asP, asY, aWp, aSeg, st, ())
      )
    } else {
      renderJourneyFrame(v, prog, pd, asP, asY, aWp, aSeg)
      let _ = Window.requestAnimationFrame(() =>
        runJourneyLoop(v, data, pd, bst, cft, asP, asY, aWp, aSeg, st, ())
      )
    }
  } else {
    SvgManager.hide("sim_arrow")
  }
}

let startJourney = (data: EventBus.navStartPayload) => {
  Viewer.instance
  ->Nullable.toOption
  ->Option.forEach(v => {
    activeJourneyId := Some(data.journeyId)
    let st = Date.now()
    let bst = ref(None)
    let cft = ref(false)
    let pd = data.pathData
    Viewer.setPitch(v, pd.startPitch, false)
    Viewer.setYaw(v, pd.startYaw, false)
    Viewer.setHfov(v, pd.startHfov, false)
    let (asP, asY) = (pd.startPitch, pd.startYaw)

    let aSeg = prepareSegments(pd)
    let aWp = prepareWaypoints(pd)

    let _ = Window.requestAnimationFrame(() =>
      runJourneyLoop(v, data, pd, bst, cft, asP, asY, aWp, aSeg, st, ())
    )
  })
}

module AnimationLoop = {
  let rec loop = (
    v,
    state,
    j: journeyData,
    pd: Types.pathData,
    st,
    bst,
    cft,
    dispatch,
    req: React.ref<option<int>>,
    (),
  ) => {
    if cft.contents {
      Dom.getElementById("viewer-hotspot-lines")
      ->Nullable.toOption
      ->Option.forEach(svg => Dom.setTextContent(svg, ""))
    } else {
      let prog = Math.min((Date.now() -. st) /. pd.panDuration, 1.0)
      if prog >= 1.0 {
        let sb = bst.contents->Option.getOr({
          let n = Date.now()
          bst := Some(n)
          n
        })
        let bel = Date.now() -. sb
        let dur = j.previewOnly ? 1000.0 : 2000.0
        let rate = j.previewOnly ? 200.0 : 400.0
        Viewer.setPitch(v, pd.targetPitchForPan, false)
        Viewer.setYaw(v, pd.targetYawForPan, false)
        Viewer.setHfov(v, pd.targetHfovForPan, false)
        if bel < dur {
          if ViewerSystem.isViewerReady(v) {
            HotspotLine.updateLines(v, state, ())
            HotspotLine.updateSimulationArrow(
              v,
              pd.startPitch,
              pd.startYaw,
              pd.targetPitchForPan,
              pd.targetYawForPan,
              1.0,
              ~opacity=mod(Belt.Float.toInt(bel /. rate), 2) == 0 ? 1.0 : 0.0,
              ~waypoints=pd.waypoints->Belt.Array.map((w): PathInterpolation.point => {
                PathInterpolation.yaw: w.yaw,
                pitch: w.pitch,
              }),
              ~colorOverride=?j.previewOnly ? Some("red") : None,
              (),
            )
          }
          req.current = Some(
            Window.requestAnimationFrame(() =>
              loop(v, state, j, pd, st, bst, cft, dispatch, req, ())
            ),
          )
        } else {
          cft := true
          dispatch(Actions.DispatchNavigationFsmEvent(TransitionComplete))
        }
      } else {
        dispatch(Actions.DispatchNavigationFsmEvent(AnimationProgress(prog)))
        let (cp, cy) = NavigationLogic.calculateCameraPosition(~progress=prog, ~pathData=pd)
        Viewer.setPitch(v, cp, false)
        Viewer.setYaw(v, cy, false)
        Viewer.setHfov(v, pd.startHfov +. (pd.targetHfovForPan -. pd.startHfov) *. prog, false)
        if ViewerSystem.isViewerReady(v) {
          HotspotLine.updateLines(v, state, ())
          HotspotLine.updateSimulationArrow(
            v,
            pd.startPitch,
            pd.startYaw,
            pd.targetPitchForPan,
            pd.targetYawForPan,
            prog,
            ~opacity=1.0,
            ~waypoints=pd.waypoints->Belt.Array.map((w): PathInterpolation.point => {
              PathInterpolation.yaw: w.yaw,
              pitch: w.pitch,
            }),
            (),
          )
        }
        req.current = Some(
          Window.requestAnimationFrame(() =>
            loop(v, state, j, pd, st, bst, cft, dispatch, req, ())
          ),
        )
      }
    }
  }

  let startLoop = (v, state, j, pd: Types.pathData, dispatch, req: React.ref<option<int>>) => {
    let st = Date.now()
    let bst = ref(None)
    let cft = ref(false)
    Viewer.setPitch(v, pd.startPitch, false)
    Viewer.setYaw(v, pd.startYaw, false)
    Viewer.setHfov(v, pd.startHfov, false)

    req.current = Some(
      Window.requestAnimationFrame(() => loop(v, state, j, pd, st, bst, cft, dispatch, req, ())),
    )
  }
}

let init = () => {
  let _ = EventBus.subscribe(e => {
    switch e {
    | NavStart(d) => startJourney(d)
    | NavCancelled => activeJourneyId := None
    | ClearSimUi => SvgManager.hide("sim_arrow")
    | _ => ()
    }
  })
}
