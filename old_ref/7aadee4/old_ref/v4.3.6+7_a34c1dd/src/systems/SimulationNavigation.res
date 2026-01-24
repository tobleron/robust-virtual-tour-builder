open ReBindings
open Types

// --- BINDINGS ---
@val external setTimeout: (unit => 'a, int) => int = "setTimeout"

module Date = {
  @val @scope("Date") external now: unit => float = "now"
}

module LocalViewerBindings = {
  type t = Viewer.t
  @send external isLoaded: t => bool = "isLoaded"
  @get external sceneId: t => string = "_sceneId"
}

// --- TYPES ---

type enrichedLink = {
  hotspot: hotspot,
  hotspotIndex: int,
  targetIndex: int,
  isVisited: bool,
  isReturn: bool,
  isBridge: bool,
}

// --- NAVIGATION UTILITIES ---

/**
 * Waits for the Pannellum viewer to load a specific scene.
 * This is used during autopilot to ensure scene transitions complete before advancing.
 */
let waitForViewerScene = async (sceneIndex: int, isAutoPilotActive: unit => bool): result<
  unit,
  string,
> => {
  let state = GlobalStateBridge.getState()
  switch Belt.Array.get(state.scenes, sceneIndex) {
  | Some(expectedScene) =>
    let timeout = 8000.0
    let start = Date.now()
    let loop = ref(true)
    let result = ref(Ok())

    while loop.contents {
      if !isAutoPilotActive() {
        loop := false
      } else if Date.now() -. start > timeout {
        loop := false
        result := Error("Timeout waiting for viewer to load scene " ++ expectedScene.name)
      } else {
        let v = Nullable.toOption(Viewer.instance)
        switch v {
        | Some(viewer) =>
          let sceneId = LocalViewerBindings.sceneId(viewer)
          if sceneId == expectedScene.id && LocalViewerBindings.isLoaded(viewer) {
            loop := false
          } else {
            let _ = await Promise.make((resolve, _reject) => {
              let _ = setTimeout(() => resolve(), 100)
            })
          }
        | None =>
          let _ = await Promise.make((resolve, _reject) => {
            let _ = setTimeout(() => resolve(), 100)
          })
        }
      }
    }
    result.contents
  | None => Error("Scene index out of bounds")
  }
}

/**
 * Finds the best next link to navigate to during autopilot.
 * Priority order:
 * 1. Unvisited, non-return, non-bridge scenes
 * 2. Unvisited, non-return, bridge scenes
 * 3. Unvisited, return, non-bridge scenes
 * 4. Unvisited, return, bridge scenes
 * 5. Any non-return scene (revisit)
 * 6. Any return scene (revisit)
 */
let findBestNextLink = (currentScene: scene, state: state, visited: array<int>): option<
  enrichedLink,
> => {
  let hotspots = currentScene.hotspots
  if Array.length(hotspots) == 0 {
    None
  } else {
    let allLinks =
      hotspots
      ->Belt.Array.mapWithIndex((i, hotspot) => {
        let targetIdx = Belt.Array.getIndexBy(state.scenes, s => s.name == hotspot.target)
        switch targetIdx {
        | Some(idx) =>
          switch Belt.Array.get(state.scenes, idx) {
          | Some(targetScene) =>
            let isVisited = Js.Array.includes(idx, visited)
            let isReturn = switch hotspot.isReturnLink {
            | Some(b) => b
            | None => false
            }
            let isBridge = targetScene.isAutoForward

            Some({
              hotspot,
              hotspotIndex: i,
              targetIndex: idx,
              isVisited,
              isReturn,
              isBridge,
            })
          | None => None
          }
        | None => None
        }
      })
      ->Belt.Array.keepMap(x => x)

    let p1 = Js.Array.find(l => !l.isVisited && !l.isReturn && !l.isBridge, allLinks)
    switch p1 {
    | Some(l) => Some(l)
    | None =>
      let p2 = Js.Array.find(l => !l.isVisited && !l.isReturn && l.isBridge, allLinks)
      switch p2 {
      | Some(l) => Some(l)
      | None =>
        let p3 = Js.Array.find(l => !l.isVisited && l.isReturn && !l.isBridge, allLinks)
        switch p3 {
        | Some(l) => Some(l)
        | None =>
          let p4 = Js.Array.find(l => !l.isVisited && l.isReturn && l.isBridge, allLinks)
          switch p4 {
          | Some(l) => Some(l)
          | None =>
            let p5 = Js.Array.find(l => !l.isReturn, allLinks)
            switch p5 {
            | Some(l) => Some(l)
            | None => Js.Array.find(l => l.isReturn, allLinks)
            }
          }
        }
      }
    }
  }
}
