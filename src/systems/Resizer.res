/* src/systems/Resizer.res - Facade for Resizer */

include ResizerTypes
include ResizerUtils
include ResizerLogic

let init = () => {
  Logger.initialized(~module_="Resizer")
}
