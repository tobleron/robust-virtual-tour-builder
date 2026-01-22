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
 * Helper function to find a viewer instance that is currently
 * loading or has loaded a specific scene.
 * It checks the global window.pannellumViewer as well as the 
 * dual-viewer instances in ViewerState.
 */
let findViewerForScene = (sceneId: string): option<Viewer.t> => {
  // 1. Check global instance (window.pannellumViewer)
  let globalViewer = Nullable.toOption(Viewer.instance)
  switch globalViewer {
  | Some(v) if LocalViewerBindings.sceneId(v) == sceneId => Some(v)
  | _ =>
    // 2. Check dual-viewer state (viewerA/viewerB)
    let viewerA = Nullable.toOption(ViewerState.state.viewerA)
    let viewerB = Nullable.toOption(ViewerState.state.viewerB)

    switch viewerA {
    | Some(v) if LocalViewerBindings.sceneId(v) == sceneId => Some(v)
    | _ =>
      switch viewerB {
      | Some(v) if LocalViewerBindings.sceneId(v) == sceneId => Some(v)
      | _ => None
      }
    }
  }
}

/**
 * Waits for the Pannellum viewer to load a specific scene.
 * This is used during autopilot to ensure scene transitions complete before advancing.
 * Now includes a retry mechanism with exponential backoff for robustness.
 */
let waitForViewerScene = async (
  sceneIndex: int,
  isAutoPilotActive: unit => bool,
  ~maxRetries=3,
  (),
): result<unit, string> => {
  let state = GlobalStateBridge.getState()
  switch Belt.Array.get(state.scenes, sceneIndex) {
  | Some(expectedScene) =>
    let rec attemptLoad = async (attempt: int) => {
      let timeout = Float.fromInt(Constants.sceneLoadTimeout)
      let start = Date.now()
      let loop = ref(true)
      let currentResult = ref(Ok())

      while loop.contents {
        if !isAutoPilotActive() {
          loop := false
        } else if Date.now() -. start > timeout {
          loop := false
          currentResult := Error("Timeout waiting for viewer to load scene " ++ expectedScene.name)
        } else {
          let v = findViewerForScene(expectedScene.id)
          switch v {
          | Some(viewer) =>
            if HotspotLine.isViewerReady(viewer) {
              Logger.debug(
                ~module_="Simulation",
                ~message="VIEWER_READY",
                ~data=Some({"scene": expectedScene.name, "elapsed": Date.now() -. start}),
                (),
              )
              loop := false
            } else {
              let _ = await Promise.make((resolve, _reject) => {
                let _ = setTimeout(() => resolve(), 50)
              })
            }
          | None =>
            let _ = await Promise.make((resolve, _reject) => {
              let _ = setTimeout(() => resolve(), 50)
            })
          }
        }
      }

      switch currentResult.contents {
      | Ok() => Ok()
      | Error(msg) =>
        if attempt < maxRetries && isAutoPilotActive() {
          let nextAttempt = attempt + 1
          Logger.warn(
            ~module_="Simulation",
            ~message="SCENE_LOAD_RETRY",
            ~data=Some({
              "scene": expectedScene.name,
              "attempt": nextAttempt,
              "maxRetries": maxRetries,
              "error": msg,
            }),
            (),
          )

          EventBus.dispatch(
            ShowNotification(
              "Retrying scene load (" ++
              Belt.Int.toString(nextAttempt) ++
              "/" ++
              Belt.Int.toString(maxRetries) ++ ")...",
              #Warning,
            ),
          )

          // Exponential backoff: 1s, 2s, 4s
          let backoffMs = switch attempt {
          | 1 => 1000
          | 2 => 2000
          | 3 => 4000
          | _ => 8000
          }

          let _ = await Promise.make((resolve, _) => {
            let _ = setTimeout(() => resolve(), backoffMs)
          })

          await attemptLoad(nextAttempt)
        } else {
          Error(msg)
        }
      }
    }

    await attemptLoad(1)
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
