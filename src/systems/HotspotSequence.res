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
  targetSceneId: string,
  targetLabel: string,
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

let deriveOrderedHotspots = (~state: state): array<orderedHotspot> => {
  let model = CanonicalTraversal.derive(~state)
  model.orderedForwardRefs->Belt.Array.mapWithIndex((idx, item) => {
    let sequenceValue = idx + Constants.Scene.Sequence.startSceneNumber
    {
      sceneId: item.sceneId,
      sceneIndex: item.sceneIndex,
      hotspotIndex: item.hotspotIndex,
      linkId: item.linkId,
      sceneLabel: item.sceneLabel,
      targetSceneId: item.targetSceneId,
      targetLabel: item.targetLabel,
      sequence: sequenceValue,
      sequenceOrder: item.sequenceOrder,
    }
  })
}

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
