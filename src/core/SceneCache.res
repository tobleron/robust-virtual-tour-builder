/* src/core/SceneCache.res */
open ReBindings

type t = Belt.MutableMap.String.t<string>

/*
 * Map of sceneId -> blobUrl for pre-calculated snapshots
 * Used to pass visual state from idle to load phase without mutating immutable scene records
 */
let cache: t = Belt.MutableMap.String.make()

let getSnapshot = (sceneId: string) => {
  Belt.MutableMap.String.get(cache, sceneId)
}

let setSnapshot = (sceneId: string, url: string) => {
  /* Revoke existing if we overwrite to prevent memory leaks */
  switch Belt.MutableMap.String.get(cache, sceneId) {
  | Some(oldUrl) if oldUrl != url => URL.revokeObjectURL(oldUrl)
  | _ => ()
  }
  Belt.MutableMap.String.set(cache, sceneId, url)
}

let removeKeyOnly = (sceneId: string) => {
  Belt.MutableMap.String.remove(cache, sceneId)
}

let clearSnapshot = (sceneId: string) => {
  switch Belt.MutableMap.String.get(cache, sceneId) {
  | Some(oldUrl) => URL.revokeObjectURL(oldUrl)
  | None => ()
  }
  Belt.MutableMap.String.remove(cache, sceneId)
}

let clearAll = () => {
  Belt.MutableMap.String.forEach(cache, (_, url) => {
    URL.revokeObjectURL(url)
  })
  Belt.MutableMap.String.clear(cache)
}
