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
    }
  })
}
