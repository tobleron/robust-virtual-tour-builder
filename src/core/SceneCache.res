/* src/core/SceneCache.res */
open ReBindings

type t = Belt.MutableMap.String.t<string>

/*
 * Map of sceneId -> blobUrl for pre-calculated snapshots
 */
let cache: t = Belt.MutableMap.String.make()

/*
 * Map of sceneId -> blobUrl for source files
 * Prevents redundant creates and memory leaks during rapid switching
 */
let sourceUrls: t = Belt.MutableMap.String.make()

/*
 * Map of sceneId -> blobUrl for thumbnails
 * Prevents redundant creates and memory leaks in the sidebar
 */
let thumbUrls: t = Belt.MutableMap.String.make()

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

let getSourceUrl = (sceneId: string, file: Types.file) => {
  switch Belt.MutableMap.String.get(sourceUrls, sceneId) {
  | Some(url) => url
  | None =>
    let url = UrlUtils.fileToUrl(file)
    Belt.MutableMap.String.set(sourceUrls, sceneId, url)
    url
  }
}

let getThumbUrl = (sceneId: string, file: Types.file) => {
  switch Belt.MutableMap.String.get(thumbUrls, sceneId) {
  | Some(url) => url
  | None =>
    let url = UrlUtils.fileToUrl(file)
    Belt.MutableMap.String.set(thumbUrls, sceneId, url)
    url
  }
}

let clearThumbUrl = (sceneId: string) => {
  switch Belt.MutableMap.String.get(thumbUrls, sceneId) {
  | Some(url) => URL.revokeObjectURL(url)
  | None => ()
  }
  Belt.MutableMap.String.remove(thumbUrls, sceneId)
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

  Belt.MutableMap.String.forEach(sourceUrls, (_, url) => {
    URL.revokeObjectURL(url)
  })
  Belt.MutableMap.String.clear(sourceUrls)

  Belt.MutableMap.String.forEach(thumbUrls, (_, url) => {
    URL.revokeObjectURL(url)
  })
  Belt.MutableMap.String.clear(thumbUrls)
}
