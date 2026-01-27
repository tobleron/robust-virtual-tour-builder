/* src/systems/HotspotLineLogic.res */

let isViewerValid = HotspotLineLogicLogic.isViewerValid
let isActiveViewer = HotspotLineLogicLogic.isActiveViewer
let isViewerReady = HotspotLineLogicLogic.isViewerReady
let getCamState = HotspotLineLogicLogic.getCamState
let getScreenCoords = ProjectionMath.getScreenCoords
let updateLine = SvgRenderer.updateLine
let updatePolyLine = HotspotLineLogicLogic.updatePolyLine
let updateSimulationArrow = HotspotLineLogicArrow.updateSimulationArrow
let drawPersistentLines = HotspotLineLogicLogic.drawPersistentLines
let drawLinkingDraft = HotspotLineLogicLogic.drawLinkingDraft