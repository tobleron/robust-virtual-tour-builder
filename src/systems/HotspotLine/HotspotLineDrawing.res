/* src/systems/HotspotLine/HotspotLineDrawing.res */
// @efficiency-role: domain-logic

open ReBindings

let areCoordinatesValid = viewer => {
  let hfov = Viewer.getHfov(viewer)
  let yaw = Viewer.getYaw(viewer)
  let pitch = Viewer.getPitch(viewer)
  hfov > 0.0 && Float.isFinite(hfov) && Float.isFinite(yaw) && Float.isFinite(pitch)
}

let isViewerValid = (viewer: Viewer.t): bool => {
  Viewer.isLoaded(viewer) && areCoordinatesValid(viewer)
}

let getCamState = (viewer, rect: Dom.rect) => {
  let yaw = Viewer.getYaw(viewer)
  let pitch = Viewer.getPitch(viewer)
  let hfov = Viewer.getHfov(viewer)
  ProjectionMath.makeCamState(yaw, pitch, hfov, rect)
}

let updatePolyLine = HotspotLineDrawingSupport.updatePolyLine

let renderPathSegment = (
  _h: Types.hotspot,
  id,
  points,
  color,
  width,
  opacity,
  ~dashArray=?,
  ~className=?,
  (),
) => {
  SvgManager.Renderer.drawPolyLine(id, points, color, width, opacity, ~dashArray?, ~className?, ())
}

let drawSingleHotspotLine = (
  h: Types.hotspot,
  cam,
  rect,
  currentFrameIds,
  _simulationStatus: Types.simulationStatus,
) => {
  HotspotLineDrawingSupport.drawSingleHotspotLine(h, cam, rect, currentFrameIds, _simulationStatus)
}

let drawPersistentLines = (
  cam,
  rect,
  hotspots: array<Types.hotspot>,
  currentFrameIds,
  _simulationStatus: Types.simulationStatus,
) => {
  for i in 0 to Array.length(hotspots) - 1 {
    switch Belt.Array.get(hotspots, i) {
    | Some(h) => drawSingleHotspotLine(h, cam, rect, currentFrameIds, _simulationStatus)
    | None => ()
    }
  }
}

let drawLinkingDraft = (
  viewer,
  cam: ProjectionMath.camState,
  rect,
  draft: Types.linkDraft,
  mouseEvent,
  currentFrameIds,
) => {
  HotspotLineDrawingSupport.drawLinkingDraft(viewer, cam, rect, draft, mouseEvent, currentFrameIds)
}
