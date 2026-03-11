// @efficiency-role: domain-logic

open Types

type forwardRef = CanonicalTraversalTypes.forwardRef

let stripSceneTag = (raw: string): string => {
  let trimmed = raw->String.trim
  if trimmed == "" {
    ""
  } else if String.startsWith(trimmed, "#") {
    trimmed
    ->String.substring(~start=1, ~end=String.length(trimmed))
    ->String.trim
  } else {
    trimmed
  }
}

let displaySceneLabel = (scene: scene): string => {
  let source = if scene.label->String.trim != "" {
    scene.label
  } else {
    scene.name
  }
  let cleaned = stripSceneTag(source)
  if cleaned == "" {
    scene.name
  } else {
    cleaned
  }
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

let addVisitedLink = (visited: array<string>, linkId: string): array<string> =>
  if visited->Belt.Array.some(existing => existing == linkId) {
    visited
  } else {
    Belt.Array.concat(visited, [linkId])
  }

let applyVisitedActions = (~visited: array<string>, ~actions: array<Actions.action>): array<
  string,
> =>
  actions->Belt.Array.reduce(visited, (acc, action) =>
    switch action {
    | AddVisitedLink(linkId) => addVisitedLink(acc, linkId)
    | _ => acc
    }
  )

let firstNewLinkId = (~visited: array<string>, ~actions: array<Actions.action>): option<string> =>
  actions->Belt.Array.reduce(None, (acc, action) =>
    switch (acc, action) {
    | (Some(_), _) => acc
    | (None, AddVisitedLink(linkId)) =>
      if visited->Belt.Array.some(existing => existing == linkId) {
        None
      } else {
        Some(linkId)
      }
    | _ => None
    }
  )

let deriveReturnLinkIdSet = (
  ~activeScenes: array<scene>,
  ~parentBySceneId: Belt.Map.String.t<string>,
): Belt.Set.String.t => {
  let returnIds = Belt.MutableSet.String.make()

  activeScenes->Belt.Array.forEach(sourceScene => {
    sourceScene.hotspots->Belt.Array.forEach(hotspot =>
      switch HotspotTarget.resolveSceneId(activeScenes, hotspot) {
      | Some(targetSceneId) =>
        if (
          TraversalParentMap.isReturnTarget(
            ~parentBySceneId,
            ~sourceSceneId=sourceScene.id,
            ~targetSceneId,
          )
        ) {
          returnIds->Belt.MutableSet.String.add(hotspot.linkId)
        }
      | None => ()
      }
    )
  })

  returnIds
  ->Belt.MutableSet.String.toArray
  ->Belt.Set.String.fromArray
}

let collectForwardRefs = (
  ~activeScenes: array<scene>,
  ~traversalOrderByLinkId: Belt.Map.String.t<int>,
  ~returnLinkIdSet: Belt.Set.String.t,
): array<forwardRef> => {
  let sceneById =
    activeScenes->Belt.Array.reduce(Belt.Map.String.empty, (acc, scene) =>
      acc->Belt.Map.String.set(scene.id, scene)
    )

  let fallbackCounter = ref(0)
  let refs: array<forwardRef> = []

  activeScenes->Belt.Array.forEachWithIndex((sceneIndex, sourceScene) => {
    sourceScene.hotspots->Belt.Array.forEachWithIndex((hotspotIndex, hotspot) => {
      let isReturn = returnLinkIdSet->Belt.Set.String.has(hotspot.linkId)
      if !isReturn {
        switch HotspotTarget.resolveSceneId(activeScenes, hotspot) {
        | Some(targetSceneId) =>
          let fallbackOrder = fallbackCounter.contents
          fallbackCounter := fallbackCounter.contents + 1
          let targetLabel = switch sceneById->Belt.Map.String.get(targetSceneId) {
          | Some(targetScene) => displaySceneLabel(targetScene)
          | None => hotspot.target
          }

          let baseOrder = switch traversalOrderByLinkId->Belt.Map.String.get(hotspot.linkId) {
          | Some(order) => order
          | None => 100000 + fallbackOrder
          }

          Array.push(
            refs,
            {
              sceneId: sourceScene.id,
              sceneIndex,
              hotspotIndex,
              linkId: hotspot.linkId,
              sceneLabel: displaySceneLabel(sourceScene),
              targetSceneId,
              targetLabel,
              fallbackOrder,
              baseOrder,
              sequenceOrder: hotspot.sequenceOrder,
              isAutoForward: hotspot.isAutoForward->Option.getOr(false),
            },
          )->ignore
        | None => ()
        }
      }
    })
  })

  refs
}

let sortDefaultForwardRefs = (refs: array<forwardRef>): array<forwardRef> =>
  CanonicalTraversalOrdering.sortDefaultForwardRefs(refs)

let applyManualOverrides = (baseOrdered: array<forwardRef>): array<forwardRef> =>
  CanonicalTraversalOrdering.applyManualOverrides(baseOrdered)

let isValidForwardOrder = (~ordered: array<forwardRef>): bool =>
  CanonicalTraversalOrdering.isValidForwardOrder(~ordered)

let moveRefToIndex = (~ordered: array<forwardRef>, ~currentIndex: int, ~nextIndex: int): array<
  forwardRef,
> => CanonicalTraversalOrdering.moveRefToIndex(~ordered, ~currentIndex, ~nextIndex)

let deriveAdmissibleOrdersByLinkId = (~ordered: array<forwardRef>): Belt.Map.String.t<array<int>> =>
  CanonicalTraversalOrdering.deriveAdmissibleOrdersByLinkId(~ordered)
