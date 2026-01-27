/* src/systems/SceneLoader.res - Facade for SceneLoader */

include SceneLoaderTypes
include SceneLoaderLogic

let init = () => {
  Logger.initialized(~module_="SceneLoader")
}
