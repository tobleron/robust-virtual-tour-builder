open Types

type traversalHotspot = {
  hotspot: hotspot,
  hotspotIndex: int,
  isAutoForward: bool,
}

let orderTraversalHotspots = (hotspots: array<hotspot>): array<traversalHotspot> =>
  hotspots
  ->Belt.Array.mapWithIndex((hotspotIndex, hotspot) => {
    let isAutoForward = hotspot.isAutoForward->Option.getOr(false)
    {hotspot, hotspotIndex, isAutoForward}
  })
  ->Belt.SortArray.stableSortBy((a, b) => {
    if a.isAutoForward == b.isAutoForward {
      a.hotspotIndex - b.hotspotIndex
    } else if a.isAutoForward {
      1
    } else {
      -1
    }
  })

let derive = (~activeScenes: array<scene>): Belt.Map.String.t<string> => {
  let sceneById =
    activeScenes->Belt.Array.reduce(Belt.Map.String.empty, (acc, scene) =>
      acc->Belt.Map.String.set(scene.id, scene)
    )

  let visitedSceneIds = Belt.MutableSet.String.make()
  let parentBySceneId = ref(Belt.Map.String.empty)

  let traverseFromSceneId = (rootSceneId: string): unit => {
    visitedSceneIds->Belt.MutableSet.String.add(rootSceneId)
    let queue: array<string> = [rootSceneId]
    let cursor = ref(0)

    while cursor.contents < queue->Belt.Array.length {
      let currentSceneId = queue->Belt.Array.get(cursor.contents)->Option.getOr("")
      cursor := cursor.contents + 1

      if currentSceneId != "" {
        switch sceneById->Belt.Map.String.get(currentSceneId) {
        | Some(currentScene) =>
          currentScene.hotspots
          ->orderTraversalHotspots
          ->Belt.Array.forEach(candidate =>
            switch HotspotTarget.resolveSceneId(activeScenes, candidate.hotspot) {
            | Some(targetSceneId) if targetSceneId != "" =>
              let targetSeen = visitedSceneIds->Belt.MutableSet.String.has(targetSceneId)
              if !targetSeen {
                parentBySceneId :=
                  parentBySceneId.contents->Belt.Map.String.set(targetSceneId, currentSceneId)
                visitedSceneIds->Belt.MutableSet.String.add(targetSceneId)
                Array.push(queue, targetSceneId)->ignore
              }
            | _ => ()
            }
          )
        | None => ()
        }
      }
    }
  }

  activeScenes->Belt.Array.forEach(scene => {
    let alreadyVisited = visitedSceneIds->Belt.MutableSet.String.has(scene.id)
    if !alreadyVisited {
      traverseFromSceneId(scene.id)
    }
  })

  parentBySceneId.contents
}

let isReturnTarget = (
  ~parentBySceneId: Belt.Map.String.t<string>,
  ~sourceSceneId: string,
  ~targetSceneId: string,
): bool =>
  switch parentBySceneId->Belt.Map.String.get(sourceSceneId) {
  | Some(parentSceneId) => parentSceneId == targetSceneId
  | None => false
  }
