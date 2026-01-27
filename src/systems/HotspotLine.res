/* src/systems/HotspotLine.res */

open ReBindings
open HotspotLineTypes
open HotspotLineLogic

/* --- FACADE --- */

let isViewerReady = HotspotLineLogic.isViewerReady
let getScreenCoords = (v, p, y, rect) => {
  let cam = HotspotLineLogic.getCamState(v, rect)
  HotspotLineLogic.getScreenCoords(cam, p, y, rect)
}

let updateSimulationArrow = (
  v,
  sp,
  sy,
  ep,
  ey,
  prog,
  ~opacity=?,
  ~waypoints=?,
  ~colorOverride=?,
  ~preComputedSegments=?,
  ~preComputedTotalDistance=?,
  ~id="sim_arrow",
  (),
) => {
  let svgOpt = Dom.getElementById("viewer-hotspot-lines")
  switch Nullable.toOption(svgOpt) {
  | Some(svg) =>
    let rect = Dom.getBoundingClientRect(svg)
    if rect.width > 0.0 && isViewerReady(v) {
      let cam = HotspotLineLogic.getCamState(v, rect)
      HotspotLineLogic.updateSimulationArrow(
        cam,
        sp,
        sy,
        ep,
        ey,
        prog,
        rect,
        ~opacity?,
        ~waypoints?,
        ~colorOverride?,
        ~preComputedSegments?,
        ~preComputedTotalDistance?,
        ~id,
        (),
      )
    }
  | _ => ()
  }
}

external asCustom: Viewer.t => customViewerProps = "%identity"

let updateLines = (viewer, state: Types.state, ~mouseEvent: option<Dom.event>=?, ()) => {
  let svgOpt = Dom.getElementById("viewer-hotspot-lines")
  switch Nullable.toOption(svgOpt) {
  | Some(svg) =>
    // Garbage Collection: Track what we draw this frame
    let currentFrameIds = Belt.MutableSet.String.make()

    if !isViewerReady(viewer) {
      () // Skip if viewer not ready
    } else {
      let rect = Dom.getBoundingClientRect(svg)

      if rect.width > 0.0 && state.activeIndex >= 0 {
        let cam = HotspotLineLogic.getCamState(viewer, rect)
        let viewerSceneId = asCustom(viewer).sceneId

        let sceneToRender = switch Belt.Array.getBy(state.scenes, s => s.id == viewerSceneId) {
        | Some(s) => Some(s)
        | None =>
          switch Belt.Array.get(state.scenes, state.activeIndex) {
          | Some(activeS) if activeS.id == viewerSceneId => Some(activeS)
          | _ => None
          }
        }

        switch sceneToRender {
        | Some(currentScene) => {
            // 1. Persistent Red Dashed Lines & Arrows
            drawPersistentLines(
              cam,
              rect,
              currentScene.hotspots,
              currentFrameIds,
              state.simulation.status,
            )

            // 2. Linking Mode
            if state.isLinking {
              switch state.linkDraft {
              | Some(draft) =>
                drawLinkingDraft(viewer, cam, rect, draft, mouseEvent, currentFrameIds)
              | None => ()
              }
            }

            // Cleanup phase: Hide anything that wasn't drawn this frame
            Belt.MutableSet.String.forEach(HotspotLineUtils.lastFrameIds.contents, id => {
              if !Belt.MutableSet.String.has(currentFrameIds, id) {
                SvgManager.hide(id)
              }
            })

            // Swap / Update lastFrameIds
            HotspotLineUtils.lastFrameIds := currentFrameIds
          }
        | None => () // CRITICAL: If no scene detected, we DO NOTHING.
        }
      }
    }
  | None => ()
  }
}