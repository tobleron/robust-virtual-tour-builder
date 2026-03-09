// @efficiency-role: domain-logic

open Types

type candidateLink = {
  link: SimulationTypes.enrichedLink,
  isReturn: bool,
}

let pickByPriority = (
  candidates: array<candidateLink>,
): option<SimulationTypes.enrichedLink> => {
  let pick = predicate =>
    Array.find(candidates, candidate => predicate(candidate))->Option.map(candidate =>
      candidate.link
    )

  let p1 = pick(candidate =>
    !candidate.link.isVisited && !candidate.isReturn && !candidate.link.isBridge
  )
  switch p1 {
  | Some(link) => Some(link)
  | None =>
    let p2 = pick(candidate =>
      !candidate.link.isVisited && !candidate.isReturn && candidate.link.isBridge
    )
    switch p2 {
    | Some(link) => Some(link)
    | None =>
      let p3 = pick(candidate =>
        !candidate.link.isVisited && candidate.isReturn && !candidate.link.isBridge
      )
      switch p3 {
      | Some(link) => Some(link)
      | None =>
        let p4 = pick(candidate =>
          !candidate.link.isVisited && candidate.isReturn && candidate.link.isBridge
        )
        switch p4 {
        | Some(link) => Some(link)
        | None =>
          let p5 = pick(candidate => candidate.link.isVisited && candidate.isReturn)
          switch p5 {
          | Some(link) => Some(link)
          | None => pick(candidate => candidate.link.targetIndex == 0)
          }
        }
      }
    }
  }
}

let buildCandidateLinks = (
  ~currentScene: scene,
  ~state: state,
  ~isVisited: SimulationTypes.enrichedLink => bool,
): array<candidateLink> => {
  let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
  let parentBySceneId = TraversalParentMap.derive(~activeScenes)

  currentScene.hotspots
  ->Belt.Array.mapWithIndex((i, hotspot) => {
    let targetIdx = HotspotTarget.resolveSceneIndex(activeScenes, hotspot)
    switch targetIdx {
    | Some(idx) =>
      switch Belt.Array.get(activeScenes, idx) {
      | Some(targetScene) =>
        let candidate = {
          link: {
            hotspot,
            hotspotIndex: i,
            targetIndex: idx,
            isVisited: false,
            isBridge: switch hotspot.isAutoForward {
            | Some(af) => af
            | None => false
            },
          },
          isReturn: TraversalParentMap.isReturnTarget(
            ~parentBySceneId,
            ~sourceSceneId=currentScene.id,
            ~targetSceneId=targetScene.id,
          ),
        }
        Some({...candidate, link: {...candidate.link, isVisited: isVisited(candidate.link)}})
      | None => None
      }
    | None => None
    }
  })
  ->Belt.Array.keepMap(x => x)
}
