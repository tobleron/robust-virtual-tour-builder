/* src/systems/Simulation/SimulationNavigation.res */

open ReBindings
open Types
@@warning("-45")

open SimulationTypes

@val external setTimeout: (unit => 'a, int) => int = "setTimeout"

module InternalDate = {
  @val @scope("Date") external now: unit => float = "now"
}

let getActiveViewerForExpectedScene = (sceneId: string): option<Viewer.t> => {
  ViewerSystem.getActiveViewerReadyForScene(sceneId)
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
      // Strict scene gate: only the active viewer for the expected scene is accepted.
      let v = getActiveViewerForExpectedScene(expectedSceneId)
      switch v {
      | Some(_viewer) => Ok()
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

let pickByPriority = (candidates: array<SimulationNavigationSupport.candidateLink>): option<
  enrichedLink,
> => {
  SimulationNavigationSupport.pickByPriority(candidates)
}

let findBestNextLink = (currentScene: scene, state: state, visited: array<int>): option<
  enrichedLink,
> => {
  let hotspots = currentScene.hotspots
  if Array.length(hotspots) == 0 {
    None
  } else {
    let allLinks = SimulationNavigationSupport.buildCandidateLinks(
      ~currentScene,
      ~state,
      ~isVisited=link => Array.includes(visited, link.targetIndex),
    )

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

    pickByPriority(allLinks)
  }
}

/**
 * Find the best next link using linkId-based visited tracking.
 * This is the correct approach for graph traversal - tracks edges (links), not nodes (scenes).
 */
let findBestNextLinkByLinkId = (
  currentScene: scene,
  state: state,
  visitedLinkIds: array<string>,
): option<enrichedLink> => {
  let hotspots = currentScene.hotspots
  if Array.length(hotspots) == 0 {
    None
  } else {
    let allLinks = SimulationNavigationSupport.buildCandidateLinks(
      ~currentScene,
      ~state,
      ~isVisited=link => Array.includes(visitedLinkIds, link.hotspot.linkId),
    )

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

    pickByPriority(allLinks)
  }
}
