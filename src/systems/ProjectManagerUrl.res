/* src/systems/ProjectManagerUrl.res */
/* @efficiency-role: domain-logic */

open Types

let rebuildUrl = (f: Types.file, ~sessionId: string, ~tokenQuery: string) => {
  switch f {
  | Url(url) =>
    let isFullUrl = String.startsWith(url, "http")
    let isLegacyBackend = String.includes(url, "/api/project/")

    // Blob URLs from saved projects are invalid/dead in the new session.
    // We return Empty to force the scene-name fallback within validScenes loop.
    if String.startsWith(url, "blob:") {
      Types.Url("")
    } else if isLegacyBackend {
      // Extract filename from old backend URL and rebuild with current sessionId
      let parts = String.split(url, "/file/")
      switch Belt.Array.get(parts, 1) {
      | Some(afterFile) =>
        let filename = String.split(afterFile, "?")->Belt.Array.get(0)->Option.getOr(afterFile)
        Types.Url(
          Constants.backendUrl ++
          "/api/project/" ++
          sessionId ++
          "/file/" ++
          filename ++
          tokenQuery,
        )
      | None => f
      }
    } else if isFullUrl {
      f
    } else if url != "" {
      // It's a relative path (e.g., "images/room1.jpg" or "room1.jpg")
      let filename = if String.includes(url, "/") {
        let parts = String.split(url, "/")
        Belt.Array.get(parts, Array.length(parts) - 1)->Option.getOr(url)
      } else {
        url
      }
      Types.Url(
        Constants.backendUrl ++
        "/api/project/" ++
        sessionId ++
        "/file/" ++
        encodeURIComponent(filename) ++
        tokenQuery,
      )
    } else {
      f
    }
  | _ => f
  }
}

let rebuildSceneUrls = (scenes: array<Types.scene>, ~sessionId: string, ~tokenQuery: string) => {
  Belt.Array.map(scenes, scene => {
    // 1. Rebuild primary file URL
    let file = switch rebuildUrl(scene.file, ~sessionId, ~tokenQuery) {
    | Url(u) if u != "" && (String.startsWith(u, "http") || String.startsWith(u, "blob:")) =>
      Types.Url(u)
    | _ =>
      // Fallback: Use scene name as filename
      Types.Url(
        Constants.backendUrl ++
        "/api/project/" ++
        sessionId ++
        "/file/" ++
        encodeURIComponent(scene.name) ++
        tokenQuery,
      )
    }

    let originalFile = scene.originalFile->Option.flatMap(f => {
      switch rebuildUrl(f, ~sessionId, ~tokenQuery) {
      | Url("") => None
      | Url(u) => Some(Types.Url(u))
      | other => Some(other)
      }
    })

    let tinyFile = scene.tinyFile->Option.flatMap(f => {
      switch rebuildUrl(f, ~sessionId, ~tokenQuery) {
      | Url("") => None
      | Url(u) => Some(Types.Url(u))
      | other => Some(other)
      }
    })

    {...scene, file, originalFile, tinyFile}
  })
}
