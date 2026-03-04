open Types

type badgeKind =
  | Sequence(int)
  | Return

type hotspotRef = {
  sceneId: string,
  sceneIndex: int,
  hotspotIndex: int,
  linkId: string,
  sceneLabel: string,
  targetSceneId: string,
  targetLabel: string,
  fallbackOrder: int,
  sequenceOrder: option<int>,
}

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

type rankedRef = {
  item: hotspotRef,
  baseOrder: int,
  manualOrder: option<int>,
}

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
    1
  } else if value < 1 {
    1
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

let addVisitedSceneId = (visited: array<string>, sceneId: string): array<string> =>
  if sceneId == "" || visited->Belt.Array.some(existing => existing == sceneId) {
    visited
  } else {
    Belt.Array.concat(visited, [sceneId])
  }

let applyVisitedActions = (~visited: array<string>, ~actions: array<Actions.action>): array<string> =>
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

type parentTraversalHotspot = {
  hotspot: hotspot,
  hotspotIndex: int,
  isAutoForward: bool,
}

let orderParentTraversalHotspots = (hotspots: array<hotspot>): array<parentTraversalHotspot> =>
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

let deriveParentSceneMap = (~activeScenes: array<scene>): Belt.Map.String.t<string> => {
  let sceneById =
    activeScenes->Belt.Array.reduce(Belt.Map.String.empty, (acc, scene) =>
      acc->Belt.Map.String.set(scene.id, scene)
    )
  let visitedSceneIds = ref([])
  let parentBySceneId = ref(Belt.Map.String.empty)

  let traverseFromSceneId = (rootSceneId: string): unit => {
    visitedSceneIds := addVisitedSceneId(visitedSceneIds.contents, rootSceneId)
    let queue: array<string> = [rootSceneId]
    let cursor = ref(0)

    while cursor.contents < queue->Belt.Array.length {
      let currentSceneId = queue->Belt.Array.get(cursor.contents)->Option.getOr("")
      cursor := cursor.contents + 1

      if currentSceneId != "" {
        switch sceneById->Belt.Map.String.get(currentSceneId) {
        | Some(currentScene) =>
          currentScene.hotspots
          ->orderParentTraversalHotspots
          ->Belt.Array.forEach(candidate =>
            switch HotspotTarget.resolveSceneId(activeScenes, candidate.hotspot) {
            | Some(targetSceneId) if targetSceneId != "" =>
              let targetSeen =
                visitedSceneIds.contents->Belt.Array.some(id => id == targetSceneId)
              if !targetSeen {
                parentBySceneId :=
                  parentBySceneId.contents->Belt.Map.String.set(
                    targetSceneId,
                    currentSceneId,
                  )
                visitedSceneIds :=
                  addVisitedSceneId(visitedSceneIds.contents, targetSceneId)
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
    let alreadyVisited = visitedSceneIds.contents->Belt.Array.some(id => id == scene.id)
    if !alreadyVisited {
      traverseFromSceneId(scene.id)
    }
  })

  parentBySceneId.contents
}

let applyParentReturnBadges = (
  ~activeScenes: array<scene>,
  ~parentBySceneId: Belt.Map.String.t<string>,
  ~badges: Belt.Map.String.t<badgeKind>,
): Belt.Map.String.t<badgeKind> => {
  let finalizedBadges = ref(badges)
  activeScenes->Belt.Array.forEach(sourceScene => {
    switch parentBySceneId->Belt.Map.String.get(sourceScene.id) {
    | Some(parentSceneId) =>
      sourceScene.hotspots->Belt.Array.forEach(hotspot =>
        switch HotspotTarget.resolveSceneId(activeScenes, hotspot) {
        | Some(targetSceneId) if targetSceneId == parentSceneId =>
          finalizedBadges :=
            finalizedBadges.contents->Belt.Map.String.set(hotspot.linkId, Return)
        | _ => ()
        }
      )
    | None => ()
    }
  })
  finalizedBadges.contents
}

let deriveTraversalBadgeByLinkId = (~state: state, ~maxSteps: int=400): Belt.Map.String.t<badgeKind> => {
  let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)

  switch Belt.Array.get(activeScenes, 0) {
  | None => Belt.Map.String.empty
  | Some(_) =>
    let badgeByLinkId = ref(Belt.Map.String.empty)
    let nextSequence = ref(1)
    let stepCount = ref(0)
    let continueLoop = ref(true)

    let currentStateRef = ref({
      ...state,
      activeIndex: 0,
      simulation: {
        ...state.simulation,
        status: Running,
        visitedLinkIds: [],
      },
    })

    while continueLoop.contents && stepCount.contents < maxSteps {
      let currentState = currentStateRef.contents

      switch Belt.Array.get(activeScenes, currentState.activeIndex) {
      | Some(_) =>
        switch SimulationMainLogic.getNextMove(currentState) {
        | Move({targetIndex, triggerActions, hotspotIndex: _, yaw: _, pitch: _, hfov: _}) =>
          let maybeToScene = Belt.Array.get(activeScenes, targetIndex)
          let maybeNewLinkId = firstNewLinkId(
            ~visited=currentState.simulation.visitedLinkIds,
            ~actions=triggerActions,
          )

          switch (maybeNewLinkId, maybeToScene) {
          | (Some(linkId), Some(_)) =>
            if badgeByLinkId.contents->Belt.Map.String.get(linkId)->Option.isNone {
              badgeByLinkId :=
                badgeByLinkId.contents->Belt.Map.String.set(
                  linkId,
                  Sequence(nextSequence.contents),
                )
              nextSequence := nextSequence.contents + 1
            }
          | (None, Some(_)) =>
            ()
          | _ => ()
          }

          let visitedAfterMove = applyVisitedActions(
            ~visited=currentState.simulation.visitedLinkIds,
            ~actions=triggerActions,
          )

          currentStateRef := {
            ...currentState,
            activeIndex: targetIndex,
            simulation: {
              ...currentState.simulation,
              visitedLinkIds: visitedAfterMove,
            },
          }

          stepCount := stepCount.contents + 1
        | Complete(_) | None => continueLoop := false
        }
      | None => continueLoop := false
      }
    }

    if stepCount.contents >= maxSteps {
      Logger.warn(
        ~module_="HotspotSequence",
        ~message="HOTSPOT_SEQUENCE_MAX_STEPS_REACHED",
        ~data=Some({"maxSteps": maxSteps}),
        (),
      )
    }

    let parentBySceneId = deriveParentSceneMap(~activeScenes)
    applyParentReturnBadges(
      ~activeScenes,
      ~parentBySceneId,
      ~badges=badgeByLinkId.contents,
    )
  }
}

let collectForwardHotspots = (
  ~state: state,
  ~traversalBadges: Belt.Map.String.t<badgeKind>,
): array<hotspotRef> => {
  let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
  let sceneById =
    activeScenes->Belt.Array.reduce(Belt.Map.String.empty, (acc, s) =>
      acc->Belt.Map.String.set(s.id, s)
    )

  let fallbackCounter = ref(0)
  let rows: array<hotspotRef> = []

  activeScenes->Belt.Array.forEachWithIndex((sceneIndex, sourceScene) => {
    sourceScene.hotspots->Belt.Array.forEachWithIndex((hotspotIndex, hotspot) => {
      switch (traversalBadges->Belt.Map.String.get(hotspot.linkId), HotspotTarget.resolveSceneId(activeScenes, hotspot)) {
      | (Some(Return), _) => ()
      | (_, Some(targetSceneId)) =>
        let fallbackOrder = fallbackCounter.contents
        fallbackCounter := fallbackCounter.contents + 1
        let targetLabel = switch sceneById->Belt.Map.String.get(targetSceneId) {
        | Some(targetScene) => displaySceneLabel(targetScene)
        | None => hotspot.target
        }

        Array.push(
          rows,
          {
            sceneId: sourceScene.id,
            sceneIndex,
            hotspotIndex,
            linkId: hotspot.linkId,
            sceneLabel: displaySceneLabel(sourceScene),
            targetSceneId,
            targetLabel,
            fallbackOrder,
            sequenceOrder: hotspot.sequenceOrder,
          },
        )->ignore
      | _ => ()
      }
    })
  })

  rows
}

let toRankedRefs = (
  ~refs: array<hotspotRef>,
  ~traversalBadges: Belt.Map.String.t<badgeKind>,
): array<rankedRef> =>
  refs->Belt.Array.map(item => {
    let baseOrder = switch traversalBadges->Belt.Map.String.get(item.linkId) {
    | Some(Sequence(order)) => order
    | _ => 100000 + item.fallbackOrder
    }
    {item, baseOrder, manualOrder: item.sequenceOrder}
  })

let deriveOrderedForwardRefs = (
  ~state: state,
  ~traversalBadges: Belt.Map.String.t<badgeKind>,
): array<hotspotRef> => {
  let refs = collectForwardHotspots(~state, ~traversalBadges)

  if refs->Belt.Array.length == 0 {
    []
  } else {
    let rankedRefs = toRankedRefs(~refs, ~traversalBadges)
    let manual: array<rankedRef> = []
    let automatic: array<rankedRef> = []

    rankedRefs->Belt.Array.forEach(row => {
      switch row.manualOrder {
      | Some(order) if order > 0 => Array.push(manual, row)->ignore
      | _ => Array.push(automatic, row)->ignore
      }
    })

    let sortedAuto =
      automatic
      ->Belt.SortArray.stableSortBy((a, b) => {
        if a.baseOrder == b.baseOrder {
          a.item.fallbackOrder - b.item.fallbackOrder
        } else {
          a.baseOrder - b.baseOrder
        }
      })
      ->Belt.Array.map(row => row.item)

    if manual->Belt.Array.length == 0 {
      sortedAuto
    } else if automatic->Belt.Array.length == 0 {
      manual
      ->Belt.SortArray.stableSortBy((a, b) => {
        let seqA = a.manualOrder->Option.getOr(1)
        let seqB = b.manualOrder->Option.getOr(1)
        if seqA == seqB {
          a.item.fallbackOrder - b.item.fallbackOrder
        } else {
          seqA - seqB
        }
      })
      ->Belt.Array.map(row => row.item)
    } else {
      let manualAscending = manual->Belt.SortArray.stableSortBy((a, b) => {
        let seqA = a.manualOrder->Option.getOr(1)
        let seqB = b.manualOrder->Option.getOr(1)
        if seqA == seqB {
          b.item.fallbackOrder - a.item.fallbackOrder
        } else {
          seqA - seqB
        }
      })

      let ordered = ref(sortedAuto)
      manualAscending->Belt.Array.forEach(row => {
        let desiredOrder = row.manualOrder->Option.getOr(1)
        let desiredIndex = clampOrder(desiredOrder, ordered.contents->Belt.Array.length + 1) - 1
        ordered := UiHelpers.insertAt(ordered.contents, desiredIndex, row.item)
      })
      ordered.contents
    }
  }
}

let deriveBadgeByLinkId = (~state: state): Belt.Map.String.t<badgeKind> => {
  let traversalBadges = deriveTraversalBadgeByLinkId(~state)
  let orderedForward = deriveOrderedForwardRefs(~state, ~traversalBadges)

  let forwardBadgeMap =
    orderedForward
    ->Belt.Array.mapWithIndex((idx, item) => (item.linkId, Sequence(idx + 1)))
    ->Belt.Map.String.fromArray

  traversalBadges->Belt.Map.String.toArray->Belt.Array.reduce(forwardBadgeMap, (acc, (linkId, badge)) =>
    switch badge {
    | Return => acc->Belt.Map.String.set(linkId, Return)
    | Sequence(_) => acc
    }
  )
}

let deriveDisplayOrder = (~state: state): Belt.Map.String.t<int> =>
  deriveBadgeByLinkId(~state)
  ->Belt.Map.String.toArray
  ->Belt.Array.keepMap(((linkId, badge)) =>
    switch badge {
    | Sequence(n) => Some((linkId, n))
    | Return => None
    }
  )
  ->Belt.Map.String.fromArray

let deriveOrderedHotspots = (~state: state): array<orderedHotspot> => {
  let traversalBadges = deriveTraversalBadgeByLinkId(~state)
  let ordered = deriveOrderedForwardRefs(~state, ~traversalBadges)

  ordered->Belt.Array.mapWithIndex((idx, item) => {
    {
      sceneId: item.sceneId,
      sceneIndex: item.sceneIndex,
      hotspotIndex: item.hotspotIndex,
      linkId: item.linkId,
      sceneLabel: item.sceneLabel,
      targetSceneId: item.targetSceneId,
      targetLabel: item.targetLabel,
      sequence: idx + 1,
      sequenceOrder: item.sequenceOrder,
    }
  })
}

let buildReorderUpdates = (
  ~state: state,
  ~linkId: string,
  ~desiredOrder: int,
): array<sequenceUpdate> => {
  let traversalBadges = deriveTraversalBadgeByLinkId(~state)
  let ordered = deriveOrderedForwardRefs(~state, ~traversalBadges)
  let total = ordered->Belt.Array.length

  if total == 0 {
    []
  } else {
    switch ordered->Belt.Array.getIndexBy(item => item.linkId == linkId) {
    | None => []
    | Some(currentIndex) =>
      let nextOrder = clampOrder(desiredOrder, total)
      let targetIndex = nextOrder - 1
      if targetIndex == currentIndex {
        []
      } else {
        switch ordered->Belt.Array.get(currentIndex) {
        | Some(moved) =>
          let withoutCurrent = ordered->Belt.Array.keepWithIndex((_, idx) => idx != currentIndex)
          let reordered = UiHelpers.insertAt(withoutCurrent, targetIndex, moved)
          reordered->Belt.Array.mapWithIndex((idx, item) => {
            {
              sceneIndex: item.sceneIndex,
              hotspotIndex: item.hotspotIndex,
              linkId: item.linkId,
              sequenceOrder: idx + 1,
            }
          })
        | None => []
        }
      }
    }
  }
}
