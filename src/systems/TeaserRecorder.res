/* src/systems/TeaserRecorder.res - Facade for TeaserRecorder */

include TeaserRecorderTypes
module Overlay = TeaserRecorderOverlay
include TeaserRecorderLogic

let init = () => {
  Logger.initialized(~module_="TeaserRecorder")
}
