/* src/systems/HotspotLineLogic.res */
// @efficiency-role: orchestrator

include HotspotLineState

module Utils = HotspotLineUtils
module Logic = {
  include HotspotLineDrawing
  include HotspotLineLogicArrow
}

// Re-export common functions at the top level if they were expected there
let renderPathSegment = Logic.renderPathSegment
let updateArrow = Logic.updateArrow
let calculatePointAtProgress = Logic.calculatePointAtProgress
let updateSimulationArrow = Logic.updateSimulationArrow
let drawSingleHotspotLine = Logic.drawSingleHotspotLine
let drawPersistentLines = Logic.drawPersistentLines
let drawLinkingDraft = Logic.drawLinkingDraft
