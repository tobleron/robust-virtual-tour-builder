/* src/systems/Scene/Loader/SceneLoaderReuse.res */
open Types

external idToUnknown: string => unknown = "%identity"

let findReusableInstance = (pathRequest: pathRequest, targetIdx: int): option<ViewerSystem.Adapter.t> => {
  let targetSceneId = pathRequest.scenes[targetIdx]->Option.map(s => s.id)
  ViewerSystem.Pool.pool.contents
  ->Belt.Array.getBy(v => {
    v.instance
    ->Option.map(inst => {
      let metaId = ViewerSystem.Adapter.getMetaData(inst, "sceneId")
      metaId == targetSceneId->Option.map(idToUnknown)
    })
    ->Option.getOr(false)
  })
  ->Option.flatMap(v => v.instance)
}
