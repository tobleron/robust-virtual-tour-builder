/* src/systems/SceneLoader.res - Facade for SceneLoader */

include SceneLoaderTypes
include SceneLoaderLogic
include SceneLoaderLogicConfig

let init = () => {
  Logger.initialized(~module_="SceneLoader")
}
