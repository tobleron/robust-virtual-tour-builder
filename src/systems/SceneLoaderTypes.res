/* src/systems/SceneLoaderTypes.res */

external castToString: 'a => string = "%identity"
external castToDict: 'a => dict<'b> = "%identity"
external asDynamic: 'a => {..} = "%identity"

let loadStartTime = ref(0.0)
