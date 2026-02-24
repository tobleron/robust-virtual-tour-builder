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
  let globalViewer = Nullable.toOption(ViewerSystem.getActiveViewer())
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

let pollForViewer = async (
  expectedSceneId,
  expectedSceneName,
  isAutoPilotActive,
  ~currentRunId: int,
  ~getRunId: unit => int,
) => {
  let timeout = Float.fromInt(Constants.sceneLoadTimeout)
  let start = InternalDate.now()

  let rec pollLoop = async () => {
    let stillRunning = isAutoPilotActive() && getRunId() == currentRunId
    if !stillRunning {
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
  ~currentRunId: int,
  ~getRunId: unit => int,
  ~getState: unit => state=AppContext.getBridgeState,
  ~maxRetries=3,
  (),
): result<unit, string> => {
  let state = getState()
  let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
  switch Belt.Array.get(activeScenes, sceneIndex) {
  | Some(expectedScene) =>
    let rec attemptLoad = async (attempt: int) => {
      let result = await pollForViewer(
        expectedScene.id,
        expectedScene.name,
        isAutoPilotActive,
        ~currentRunId,
        ~getRunId,
      )

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
    let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
    let allLinks =
      hotspots
      ->Belt.Array.mapWithIndex((i, hotspot) => {
        let targetIdx = HotspotTarget.resolveSceneIndex(activeScenes, hotspot)
        switch targetIdx {
        | Some(idx) =>
          switch Belt.Array.get(activeScenes, idx) {
          | Some(_targetScene) =>
            Some({
              hotspot,
              hotspotIndex: i,
              targetIndex: idx,
              isVisited: Array.includes(visited, idx),
              isReturn: hotspot.isReturnLink->Option.getOr(false),
              // Use hotspot-level isAutoForward (more granular than scene-level)
              isBridge: switch hotspot.isAutoForward {
              | Some(af) => af
              | None => false
              },
            })
          | None => None
          }
        | None => None
        }
      })
      ->Belt.Array.keepMap(x => x)

    Logger.debug(
      ~module_="SimulationNavigation",
      ~message="FIND_BEST_NEXT_LINK",
      ~data=Some({
        "currentScene": currentScene.name,
        "hotspotCount": Array.length(hotspots),
        "allLinksCount": Belt.Array.length(allLinks),
        "visited": visited,
      }),
      (),
    )

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
            let uniqueVisitedCount = visited->Belt.Set.Int.fromArray->Belt.Set.Int.size
            let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
            if uniqueVisitedCount >= Belt.Array.length(activeScenes) {
              Array.find(allLinks, l => l.targetIndex == 0)
            } else {
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
}

/**
 * Find the best next link using linkId-based visited tracking.
 * This is the correct approach for graph traversal - tracks edges (links), not nodes (scenes).
 */
let findBestNextLinkByLinkId = (currentScene: scene, state: state, visitedLinkIds: array<string>): option<
  enrichedLink,
> => {
  let hotspots = currentScene.hotspots
  if Array.length(hotspots) == 0 {
    None
  } else {
    let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
    let allLinks =
      hotspots
      ->Belt.Array.mapWithIndex((i, hotspot) => {
        let targetIdx = HotspotTarget.resolveSceneIndex(activeScenes, hotspot)
        switch targetIdx {
        | Some(idx) =>
          switch Belt.Array.get(activeScenes, idx) {
          | Some(_targetScene) =>
            Some({
              hotspot,
              hotspotIndex: i,
              targetIndex: idx,
              // KEY CHANGE: Check if linkId was traversed, not if scene was visited
              isVisited: Array.includes(visitedLinkIds, hotspot.linkId),
              isReturn: hotspot.isReturnLink->Option.getOr(false),
              // Use hotspot-level isAutoForward (more granular than scene-level)
              isBridge: switch hotspot.isAutoForward {
              | Some(af) => af
              | None => false
              },
            })
          | None => None
          }
        | None => None
        }
      })
      ->Belt.Array.keepMap(x => x)

    Logger.debug(
      ~module_="SimulationNavigation",
      ~message="FIND_BEST_NEXT_LINK_BY_LINKID",
      ~data=Some({
        "currentScene": currentScene.name,
        "hotspotCount": Array.length(hotspots),
        "allLinksCount": Belt.Array.length(allLinks),
        "visitedLinkIds": visitedLinkIds,
      }),
      (),
    )

    // Same priority logic, but now correctly identifies untraversed links
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
            // All links traversed - return to start
            Array.find(allLinks, l => l.targetIndex == 0)
          }
        }
      }
    }
  }
}
