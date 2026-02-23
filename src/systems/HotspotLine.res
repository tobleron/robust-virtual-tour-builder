/* src/systems/HotspotLine.res - Consolidated Hotspot Line System */

open ReBindings
open Types

// --- RE-EXPORT LOGIC MODULES ---
module Logic = HotspotLineLogic.Logic
module Utils = HotspotLineLogic.Utils

// --- TYPES ---
type customViewerProps = HotspotLineLogic.customViewerProps

// --- FACADE ---

let getScreenCoords = (v, p, y, rect) => {
  let cam = Logic.getCamState(v, rect)
  ProjectionMath.getScreenCoords(cam, p, y, rect)
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
    if rect.width > 0.0 {
      let cam = Logic.getCamState(v, rect)
      Logic.updateSimulationArrow(
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
    let currentFrameIds = Belt.MutableSet.String.make()
    if Logic.isViewerValid(viewer) {
      let rect = Dom.getBoundingClientRect(svg)
      if rect.width > 0.0 && state.activeIndex >= 0 {
        let cam = Logic.getCamState(viewer, rect)
        let viewerSceneId = asCustom(viewer).sceneId
        let scenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
        let sceneToRender = switch Belt.Array.getBy(scenes, s => s.id == viewerSceneId) {
        | Some(s) => Some(s)
        | None =>
          switch Belt.Array.get(scenes, state.activeIndex) {
          | Some(activeS) if activeS.id == viewerSceneId => Some(activeS)
          | _ => None
          }
        }

        switch sceneToRender {
        | Some(currentScene) => {
            Logic.drawPersistentLines(
              cam,
              rect,
              currentScene.hotspots,
              currentFrameIds,
              state.simulation.status,
            )
            if state.isLinking {
              switch state.linkDraft {
              | Some(draft) =>
                Logic.drawLinkingDraft(viewer, cam, rect, draft, mouseEvent, currentFrameIds)
              | None => ()
              }
            }
            Belt.MutableSet.String.forEach(Utils.lastFrameIds.contents, id => {
              if !Belt.MutableSet.String.has(currentFrameIds, id) {
                SvgManager.hide(id)
              }
            })
            Utils.lastFrameIds := currentFrameIds
          }
        | None => ()
        }
      }
    }
  | None => ()
  }
}

let handleHotspotClick = (targetSceneId: string) => {
  let action = () => {
    NavigationSupervisor.requestNavigation(targetSceneId)
    Promise.resolve()
  }

  switch InteractionGuard.attempt("scene_navigation", InteractionPolicies.sceneNavigation, action) {
  | Ok(_) => ()
  | Error(_) =>
    NotificationManager.dispatch({
      id: "",
      importance: Warning,
      context: Operation("hotspot_click"),
      message: "Switching too fast...",
      details: None,
      action: None,
      duration: NotificationTypes.defaultTimeoutMs(Warning),
      dismissible: true,
      createdAt: Date.now(),
    })
  }
}

// --- COMPATIBILITY ALIASES ---
module HotspotLineTypes = {
  type screenCoords = Types.screenCoords
  type customViewerProps = customViewerProps
}
