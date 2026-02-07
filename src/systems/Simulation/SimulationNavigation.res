/* src/systems/Simulation/SimulationNavigation.res */

open ReBindings
open Types
@@warning("-45")

open SimulationTypes

@val external setTimeout: (unit => 'a, int) => int = "setTimeout"
@val external clearTimeout: int => unit = "clearTimeout"

module InternalDate = {
  @val @scope("Date") external now: unit => float = "now"
}

let getGlobalViewerForScene = (sceneId: string): option<Viewer.t> => {
  let globalViewer = Nullable.toOption(Viewer.instance)
  switch globalViewer {
  | Some(v) if ViewerSystem.Adapter.getSceneId(ViewerSystem.Adapter.asCustom(v)) == Some(sceneId) =>
    Some(v)
  | _ => None
  }
}

let getPooledViewerForScene = (sceneId: string): option<Viewer.t> => {
  ViewerSystem.Pool.pool.contents
  ->Belt.Array.getBy(vp => {
    switch vp.instance {
    | Some(v) => ViewerSystem.Adapter.getSceneId(ViewerSystem.Adapter.asCustom(v)) == Some(sceneId)
    | None => false
    }
  })
  ->Option.flatMap(vp => vp.instance)
}

let findViewerForScene = (sceneId: string): option<Viewer.t> => {
  switch getGlobalViewerForScene(sceneId) {
  | Some(v) => Some(v)
  | None => getPooledViewerForScene(sceneId)
  }
}

let pollForViewer = async (expectedSceneId, expectedSceneName, isAutoPilotActive) => {
  let timeout = Float.fromInt(Constants.sceneLoadTimeout)
  let start = InternalDate.now()

  let rec pollLoop = async () => {
    if !isAutoPilotActive() {
      Ok()
    } else if InternalDate.now() -. start > timeout {
      Error("Timeout waiting for viewer to load scene " ++ expectedSceneName)
    } else {
      let v = findViewerForScene(expectedSceneId)
      switch v {
      | Some(viewer) =>
        if ViewerSystem.isViewerReady(viewer) {
          Ok()
        } else {
          let _ = await Promise.make((resolve, _) => {
            let _ = setTimeout(() => resolve(), 100)
          })
          await pollLoop()
        }
      | None =>
        let _ = await Promise.make((resolve, _) => {
          let _ = setTimeout(() => resolve(), 100)
        })
        await pollLoop()
      }
    }
  }
  await pollLoop()
}

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
      let result = await pollForViewer(expectedScene.id, expectedScene.name, isAutoPilotActive)

      switch result {
      | Ok() => Ok()
      | Error(msg) =>
        if attempt < maxRetries && isAutoPilotActive() {
          let nextAttempt = attempt + 1
          Logger.warn(
            ~module_="Simulation",
            ~message="SCENE_LOAD_RETRY",
            ~data=Some({"scene": expectedScene.name, "attempt": nextAttempt, "error": msg}),
            (),
          )
          NotificationManager.dispatch({
            id: "",
            importance: Warning,
            context: Operation("simulation_navigation"),
            message: "Retrying scene load...",
            details: None,
            action: None,
            duration: NotificationTypes.defaultTimeoutMs(Warning),
            dismissible: true,
            createdAt: Date.now(),
          })
          let backoffMs = switch attempt {
          | 1 => 1000
          | 2 => 2000
          | _ => 4000
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
            Some({
              hotspot,
              hotspotIndex: i,
              targetIndex: idx,
              isVisited: Array.includes(visited, idx),
              isReturn: hotspot.isReturnLink->Option.getOr(false),
              isBridge: targetScene.isAutoForward,
            })
          | None => None
          }
        | None => None
        }
      })
      ->Belt.Array.keepMap(x => x)

    let p1 = Array.find(allLinks, l => !l.isVisited && !l.isReturn && !l.isBridge)
    switch p1 {
    | Some(l) => Some(l)
    | None =>
      let p2 = Array.find(allLinks, l => !l.isVisited && !l.isReturn && l.isBridge)
      switch p2 {
      | Some(l) => Some(l)
      | None =>
        let p3 = Array.find(allLinks, l => !l.isVisited && l.isReturn && !l.isBridge)
        switch p3 {
        | Some(l) => Some(l)
        | None =>
          let p4 = Array.find(allLinks, l => !l.isVisited && l.isReturn && l.isBridge)
          switch p4 {
          | Some(l) => Some(l)
          | None =>
            let p5 = Array.find(allLinks, l => !l.isReturn)
            switch p5 {
            | Some(l) => Some(l)
            | None => Array.find(allLinks, l => l.isReturn)
            }
          }
        }
      }
    }
  }
}
