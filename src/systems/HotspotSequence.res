open Types

type badgeKind =
  | Sequence(int)
  | Return

type orderedHotspot = {
  sceneId: string,
  sceneIndex: int,
  hotspotIndex: int,
  linkId: string,
  sceneLabel: string,
  sceneNumber: option<int>,
  targetSceneId: string,
  targetLabel: string,
  targetSceneNumber: option<int>,
  sequence: int,
  sequenceOrder: option<int>,
}

type sequenceUpdate = {
  sceneIndex: int,
  hotspotIndex: int,
  linkId: string,
  sequenceOrder: int,
}

let clampOrder = (value: int, maxValue: int): int => {
  if maxValue <= 0 {
    Constants.Scene.Sequence.startSceneNumber
  } else if value < Constants.Scene.Sequence.startSceneNumber {
    Constants.Scene.Sequence.startSceneNumber
  } else if value > maxValue {
    maxValue
  } else {
    value
  }
}

let fromCanonicalBadge = (badge: CanonicalTraversal.badgeKind): badgeKind =>
  switch badge {
  | CanonicalTraversal.Sequence(n) => Sequence(n)
  | CanonicalTraversal.Return => Return
  }

let deriveBadgeByLinkId = (~state: state): Belt.Map.String.t<badgeKind> => {
  let model = CanonicalTraversal.derive(~state)
  model.badgeByLinkId
  ->Belt.Map.String.toArray
  ->Belt.Array.map(((linkId, badge)) => (linkId, fromCanonicalBadge(badge)))
  ->Belt.Map.String.fromArray
}

let deriveDisplayOrder = (~state: state): Belt.Map.String.t<int> =>
  CanonicalTraversal.derive(~state).displayOrderByLinkId

let deriveAdmissibleOrders = (~state: state, ~linkId: string): array<int> =>
  CanonicalTraversal.derive(~state).admissibleOrdersByLinkId
  ->Belt.Map.String.get(linkId)
  ->Option.getOr([])

let deriveSceneNumberBySceneIdFromTraversal = (
  ~activeScenes: array<scene>,
  ~orderedForwardRefs: array<CanonicalTraversal.forwardRef>,
): Belt.Map.String.t<int> => {
  let sceneNumberBySceneId = ref(Belt.Map.String.empty)
  let nextSceneNumber = ref(Constants.Scene.Sequence.startSceneNumber)

  let assignIfMissing = (sceneId: string) => {
    if !(sceneNumberBySceneId.contents->Belt.Map.String.has(sceneId)) {
      sceneNumberBySceneId :=
        sceneNumberBySceneId.contents->Belt.Map.String.set(sceneId, nextSceneNumber.contents)
      nextSceneNumber := nextSceneNumber.contents + 1
    }
  }

  activeScenes->Belt.Array.get(0)->Option.forEach(scene => assignIfMissing(scene.id))

  orderedForwardRefs->Belt.Array.forEach(item => {
    assignIfMissing(item.sceneId)
    assignIfMissing(item.targetSceneId)
  })

  activeScenes->Belt.Array.forEach(scene => assignIfMissing(scene.id))

  sceneNumberBySceneId.contents
}

let deriveSceneNumberBySceneId = (~state: state): Belt.Map.String.t<int> => {
  let model = CanonicalTraversal.derive(~state)
  let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
  deriveSceneNumberBySceneIdFromTraversal(
    ~activeScenes,
    ~orderedForwardRefs=model.orderedForwardRefs,
  )
}

let deriveOrderedHotspots = (~state: state): array<orderedHotspot> => {
  let model = CanonicalTraversal.derive(~state)
  let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
  let sceneNumberBySceneId = deriveSceneNumberBySceneIdFromTraversal(
    ~activeScenes,
    ~orderedForwardRefs=model.orderedForwardRefs,
  )
  model.orderedForwardRefs->Belt.Array.mapWithIndex((idx, item) => {
    let sequenceValue = idx + Constants.Scene.Sequence.startSceneNumber
    {
      sceneId: item.sceneId,
      sceneIndex: item.sceneIndex,
      hotspotIndex: item.hotspotIndex,
      linkId: item.linkId,
      sceneLabel: item.sceneLabel,
      sceneNumber: sceneNumberBySceneId->Belt.Map.String.get(item.sceneId),
      targetSceneId: item.targetSceneId,
      targetLabel: item.targetLabel,
      targetSceneNumber: sceneNumberBySceneId->Belt.Map.String.get(item.targetSceneId),
      sequence: sequenceValue,
      sequenceOrder: item.sequenceOrder,
    }
  })
}

let deriveContextualOrderedHotspots = (~state: state, ~linkId: string): array<orderedHotspot> => {
  let orderedHotspots = deriveOrderedHotspots(~state)
  switch orderedHotspots->Belt.Array.getIndexBy(item => item.linkId == linkId) {
  | None => []
  | Some(currentIndex) =>
    let currentRows = switch orderedHotspots->Belt.Array.get(currentIndex) {
    | Some(current) => [current]
    | None => []
    }

    let previousRows = if currentIndex > 0 {
      switch orderedHotspots->Belt.Array.get(currentIndex - 1) {
      | Some(previous) => [previous]
      | None => []
      }
    } else {
      []
    }

    let nextRows = if currentIndex + 1 < orderedHotspots->Belt.Array.length {
      switch orderedHotspots->Belt.Array.get(currentIndex + 1) {
      | Some(next) => [next]
      | None => []
      }
    } else {
      []
    }

    previousRows->Belt.Array.concat(currentRows)->Belt.Array.concat(nextRows)
  }
}

let deriveContextualSequenceOrders = (~state: state, ~linkId: string): array<int> =>
  deriveContextualOrderedHotspots(~state, ~linkId)->Belt.Array.map(item => item.sequence)

let moveToOrder = (
  ~ordered: array<CanonicalTraversal.forwardRef>,
  ~currentIndex: int,
  ~targetIndex: int,
): array<CanonicalTraversal.forwardRef> => {
  switch ordered->Belt.Array.get(currentIndex) {
  | Some(moved) =>
    let withoutCurrent = ordered->Belt.Array.keepWithIndex((_, idx) => idx != currentIndex)
    UiHelpers.insertAt(withoutCurrent, targetIndex, moved)
  | None => ordered
  }
}

let buildReorderUpdates = (~state: state, ~linkId: string, ~desiredOrder: int): array<
  sequenceUpdate,
> => {
  let model = CanonicalTraversal.derive(~state)
  let ordered = model.orderedForwardRefs
  let total = ordered->Belt.Array.length

  if total == 0 {
    []
  } else {
    switch ordered->Belt.Array.getIndexBy(item => item.linkId == linkId) {
    | None => []
    | Some(currentIndex) =>
      let nextOrder = clampOrder(desiredOrder, total)
      let allowed = model.admissibleOrdersByLinkId->Belt.Map.String.get(linkId)->Option.getOr([])
      let isAllowed = if allowed->Belt.Array.length == 0 {
        true
      } else {
        allowed->Belt.Array.some(order => order == nextOrder)
      }

      if !isAllowed {
        []
      } else {
        let targetIndex = nextOrder - 1
        if targetIndex == currentIndex {
          []
        } else {
          let reordered = moveToOrder(~ordered, ~currentIndex, ~targetIndex)
          reordered->Belt.Array.mapWithIndex((idx, item) => {
            let sequenceValue = idx + Constants.Scene.Sequence.startSceneNumber
            {
              sceneIndex: item.sceneIndex,
              hotspotIndex: item.hotspotIndex,
              linkId: item.linkId,
              sequenceOrder: sequenceValue,
            }
          })
        }
      }
    }
  }
}
