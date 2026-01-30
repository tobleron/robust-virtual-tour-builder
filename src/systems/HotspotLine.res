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
  GlobalStateBridge.dispatch(
    Actions.DispatchNavigationFsmEvent(
      NavigationFSM.UserClickedScene({targetSceneId: targetSceneId}),
    ),
  )
}

let renderGoldArrow: (Dom.element, {..}) => unit = %raw(`
  function(hotSpotDiv, args) {
    hotSpotDiv.classList.add('custom-tooltip');
    hotSpotDiv.style.width = "40px";
    hotSpotDiv.style.height = "40px";

    const ns = "http://www.w3.org/2000/svg";
    const svg = document.createElementNS(ns, "svg");
    svg.setAttribute("class", "custom-arrow-svg");
    svg.setAttribute("viewBox", "0 0 100 100");
    svg.style.overflow = "visible";

    const isHome = args.isReturnLink === true;
    const i = args.i;

    if (isHome) {
      hotSpotDiv.setAttribute('data-target-home', 'true');
      const defs = document.createElementNS(ns, "defs");
      const grad = document.createElementNS(ns, "linearGradient");
      grad.setAttribute("id", "homeGrad_" + i);
      grad.setAttribute("x1", "0%"); grad.setAttribute("y1", "0%");
      grad.setAttribute("x2", "0%"); grad.setAttribute("y2", "100%");

      [{o:"0%",c:"#FFD700"},{o:"50%",c:"#FDB931"},{o:"100%",c:"#B8860B"}].forEach(s=>{
        const stop=document.createElementNS(ns,"stop");
        stop.setAttribute("offset",s.o);
        stop.style.stopColor=s.c;
        grad.appendChild(stop);
      });
      defs.appendChild(grad);
      svg.appendChild(defs);

      const rect = document.createElementNS(ns, "rect");
      rect.setAttribute("x", "5"); rect.setAttribute("y", "5");
      rect.setAttribute("width", "90"); rect.setAttribute("height", "90");
      rect.setAttribute("rx", "8");
      rect.setAttribute("fill", "url(#homeGrad_" + i + ")");
      svg.appendChild(rect);

      const text = document.createElementNS(ns, "text");
      text.setAttribute("x", "50"); text.setAttribute("y", "52");
      text.setAttribute("text-anchor", "middle");
      text.setAttribute("dominant-baseline", "middle");
      text.style.fontFamily = "Outfit, sans-serif";
      text.style.fontWeight = "700";
      text.style.fontSize = "24px";
      text.setAttribute("fill", "#4B3300");
      text.textContent = "HOME";
      svg.appendChild(text);
    } else {
      const defs = document.createElementNS(ns, "defs");
      const grad = document.createElementNS(ns, "linearGradient");
      grad.setAttribute("id", "arrowGrad_" + i);
      grad.setAttribute("x1", "0%"); grad.setAttribute("y1", "0%");
      grad.setAttribute("x2", "0%"); grad.setAttribute("y2", "100%");

      [{o:"0%",c:"#FFD700"},{o:"50%",c:"#FDB931"},{o:"100%",c:"#B8860B"}].forEach(s=>{
        const stop=document.createElementNS(ns,"stop");
        stop.setAttribute("offset",s.o);
        stop.style.stopColor=s.c;
        grad.appendChild(stop);
      });
      defs.appendChild(grad);
      svg.appendChild(defs);

      const p1 = document.createElementNS(ns, "path");
      p1.setAttribute("d", "M10 43 L50 13 L90 43 L90 53 L50 23 L10 53 Z M10 73 L50 43 L90 73 L90 83 L50 53 L10 83 Z");
      p1.setAttribute("fill", "#8B6508");
      svg.appendChild(p1);

      const p2 = document.createElementNS(ns, "path");
      p2.setAttribute("d", "M10 40 L50 10 L90 40 L90 60 L50 30 L10 60 Z M10 70 L50 40 L90 70 L90 90 L50 60 L10 90 Z");
      p2.setAttribute("fill", "url(#arrowGrad_" + i + ")");
      svg.appendChild(p2);

      const p3 = document.createElementNS(ns, "path");
      p3.setAttribute("d", "M10 40 L50 10 L90 40 L50 11 Z");
      p3.setAttribute("fill", "rgba(255, 255, 255, 0.5)");
      svg.appendChild(p3);
    }

    while (hotSpotDiv.firstChild) hotSpotDiv.removeChild(hotSpotDiv.firstChild);
    hotSpotDiv.appendChild(svg);

    hotSpotDiv.onclick = function(e) {
      e.stopPropagation();
      handleHotspotClick(args.targetSceneId);
    };
  }
`)

// --- COMPATIBILITY ALIASES ---
module HotspotLineTypes = {
  type screenCoords = Types.screenCoords
  type customViewerProps = customViewerProps
}
