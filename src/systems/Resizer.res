/* src/systems/Resizer.res */
// @efficiency-role: orchestrator

include ResizerTypes

module Utils = ResizerUtils
module Logic = ResizerLogic

let init = () => {Logger.initialized(~module_="Resizer")}
let getChecksum = Utils.getChecksum
let canUseStrongChecksum = Utils.isCryptoSubtleAvailableInCurrentContext
let checkBackendHealth = Utils.checkBackendHealth
let getMemoryUsage = Utils.getMemoryUsage
let processAndAnalyzeImage = Logic.processAndAnalyzeImage
let generateResolutions = Logic.generateResolutions
