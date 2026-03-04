open Types

type badgeKind =
  | Sequence(int)
  | Return

type forwardRef = {
  sceneId: string,
  sceneIndex: int,
  hotspotIndex: int,
  linkId: string,
  sceneLabel: string,
  targetSceneId: string,
  targetLabel: string,
  fallbackOrder: int,
  baseOrder: int,
  sequenceOrder: option<int>,
  isAutoForward: bool,
}

type model = {
  badgeByLinkId: Belt.Map.String.t<badgeKind>,
  displayOrderByLinkId: Belt.Map.String.t<int>,
  orderedForwardRefs: array<forwardRef>,
  admissibleOrdersByLinkId: Belt.Map.String.t<array<int>>,
}

type traversalSnapshot = {orderByLinkId: Belt.Map.String.t<int>}

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

let deriveTraversalSnapshot = (
  ~state: state,
  ~activeScenes: array<scene>,
  ~maxSteps: int,
): traversalSnapshot => {
  switch Belt.Array.get(activeScenes, 0) {
  | None => {orderByLinkId: Belt.Map.String.empty}
  | Some(_) =>
    let orderByLinkId = ref(Belt.Map.String.empty)

    let nextOrder = ref(Constants.Scene.Sequence.startSceneNumber)
    let stepCount = ref(0)
    let continueLoop = ref(true)

    let currentStateRef = ref({
      ...state,
      activeIndex: Constants.Scene.Sequence.startSceneIndex,
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
          let maybeNewLinkId = firstNewLinkId(
            ~visited=currentState.simulation.visitedLinkIds,
            ~actions=triggerActions,
          )

          maybeNewLinkId->Option.forEach(linkId => {
            if orderByLinkId.contents->Belt.Map.String.get(linkId)->Option.isNone {
              orderByLinkId :=
                orderByLinkId.contents->Belt.Map.String.set(linkId, nextOrder.contents)
              nextOrder := nextOrder.contents + 1
            }
          })

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
        ~module_="CanonicalTraversal",
        ~message="HOTSPOT_SEQUENCE_MAX_STEPS_REACHED",
        ~data=Some({"maxSteps": maxSteps}),
        (),
      )
    }

    {orderByLinkId: orderByLinkId.contents}
  }
}

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
  refs->Belt.SortArray.stableSortBy((a, b) => {
    if a.baseOrder != b.baseOrder {
      a.baseOrder - b.baseOrder
    } else if a.sceneIndex != b.sceneIndex {
      a.sceneIndex - b.sceneIndex
    } else if a.isAutoForward != b.isAutoForward {
      a.isAutoForward ? 1 : -1
    } else if a.hotspotIndex != b.hotspotIndex {
      a.hotspotIndex - b.hotspotIndex
    } else {
      a.fallbackOrder - b.fallbackOrder
    }
  })

let applyManualOverrides = (baseOrdered: array<forwardRef>): array<forwardRef> => {
  let manual =
    baseOrdered
    ->Belt.Array.keep(item =>
      switch item.sequenceOrder {
      | Some(order) => order > 0
      | None => false
      }
    )
    ->Belt.SortArray.stableSortBy((a, b) => {
      let seqA = a.sequenceOrder->Option.getOr(Constants.Scene.Sequence.startSceneNumber)
      let seqB = b.sequenceOrder->Option.getOr(Constants.Scene.Sequence.startSceneNumber)
      if seqA == seqB {
        b.fallbackOrder - a.fallbackOrder
      } else {
        seqA - seqB
      }
    })

  let ordered = ref(baseOrdered)
  manual->Belt.Array.forEach(item => {
    switch ordered.contents->Belt.Array.getIndexBy(existing => existing.linkId == item.linkId) {
    | Some(currentIndex) =>
      let withoutCurrent =
        ordered.contents->Belt.Array.keepWithIndex((_, idx) => idx != currentIndex)
      let desiredOrder = item.sequenceOrder->Option.getOr(Constants.Scene.Sequence.startSceneNumber)
      let desiredIndex = clampOrder(desiredOrder, withoutCurrent->Belt.Array.length + 1) - 1
      ordered := UiHelpers.insertAt(withoutCurrent, desiredIndex, item)
    | None => ()
    }
  })

  ordered.contents
}

let isValidForwardOrder = (~ordered: array<forwardRef>): bool => {
  if ordered->Belt.Array.length == 0 {
    true
  } else {
    let remainingNonAutoByScene = Belt.MutableMap.String.make()
    ordered->Belt.Array.forEach(item => {
      if !item.isAutoForward {
        let count =
          remainingNonAutoByScene->Belt.MutableMap.String.get(item.sceneId)->Option.getOr(0)
        remainingNonAutoByScene->Belt.MutableMap.String.set(item.sceneId, count + 1)
      }
    })

    let total = ordered->Belt.Array.length
    let idx = ref(0)
    let isValid = ref(true)

    while isValid.contents && idx.contents < total {
      let currentIndex = idx.contents
      switch ordered->Belt.Array.get(currentIndex) {
      | Some(item) =>
        let remainingNonAuto =
          remainingNonAutoByScene->Belt.MutableMap.String.get(item.sceneId)->Option.getOr(0)

        if item.isAutoForward && remainingNonAuto > 0 {
          isValid := false
        } else if !item.isAutoForward && remainingNonAuto > 0 {
          remainingNonAutoByScene->Belt.MutableMap.String.set(item.sceneId, remainingNonAuto - 1)
        }
      | None => ()
      }

      idx := idx.contents + 1
    }

    isValid.contents
  }
}

let moveRefToIndex = (~ordered: array<forwardRef>, ~currentIndex: int, ~nextIndex: int): array<
  forwardRef,
> => {
  switch ordered->Belt.Array.get(currentIndex) {
  | None => ordered
  | Some(item) =>
    let withoutCurrent = ordered->Belt.Array.keepWithIndex((_, idx) => idx != currentIndex)
    UiHelpers.insertAt(withoutCurrent, nextIndex, item)
  }
}

let deriveAdmissibleOrdersByLinkId = (~ordered: array<forwardRef>): Belt.Map.String.t<
  array<int>,
> => {
  let total = ordered->Belt.Array.length
  if total == 0 {
    Belt.Map.String.empty
  } else {
    ordered
    ->Belt.Array.mapWithIndex((currentIndex, item) => {
      let options = ref([])
      for desiredOrder in 1 to total {
        let targetIndex = desiredOrder - 1
        let candidate = if targetIndex == currentIndex {
          ordered
        } else {
          moveRefToIndex(~ordered, ~currentIndex, ~nextIndex=targetIndex)
        }

        if isValidForwardOrder(~ordered=candidate) {
          options := Belt.Array.concat(options.contents, [desiredOrder])
        }
      }

      let safeOptions = if options.contents->Belt.Array.length == 0 {
        [currentIndex + 1]
      } else {
        options.contents
      }

      (item.linkId, safeOptions)
    })
    ->Belt.Map.String.fromArray
  }
}

let derive = (~state: state, ~maxSteps: int=400): model => {
  let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)

  switch Belt.Array.get(activeScenes, 0) {
  | None => {
      badgeByLinkId: Belt.Map.String.empty,
      displayOrderByLinkId: Belt.Map.String.empty,
      orderedForwardRefs: [],
      admissibleOrdersByLinkId: Belt.Map.String.empty,
    }
  | Some(_) =>
    let traversal = deriveTraversalSnapshot(~state, ~activeScenes, ~maxSteps)
    let parentBySceneId = TraversalParentMap.derive(~activeScenes)

    let returnLinkIdSet = deriveReturnLinkIdSet(~activeScenes, ~parentBySceneId)
    let forwardRefs = collectForwardRefs(
      ~activeScenes,
      ~traversalOrderByLinkId=traversal.orderByLinkId,
      ~returnLinkIdSet,
    )

    let defaultOrdered = sortDefaultForwardRefs(forwardRefs)
    let manualOrdered = applyManualOverrides(defaultOrdered)
    let finalOrdered = if isValidForwardOrder(~ordered=manualOrdered) {
      manualOrdered
    } else {
      defaultOrdered
    }

    let displayOrderByLinkId =
      finalOrdered
      ->Belt.Array.mapWithIndex((idx, item) => (item.linkId, idx + 1))
      ->Belt.Map.String.fromArray

    let forwardBadgeByLinkId =
      displayOrderByLinkId
      ->Belt.Map.String.toArray
      ->Belt.Array.reduce(Belt.Map.String.empty, (acc, (linkId, order)) =>
        acc->Belt.Map.String.set(linkId, Sequence(order))
      )

    let badgeByLinkId =
      returnLinkIdSet
      ->Belt.Set.String.toArray
      ->Belt.Array.reduce(forwardBadgeByLinkId, (acc, linkId) =>
        acc->Belt.Map.String.set(linkId, Return)
      )

    let admissibleOrdersByLinkId = deriveAdmissibleOrdersByLinkId(~ordered=finalOrdered)

    {
      badgeByLinkId,
      displayOrderByLinkId,
      orderedForwardRefs: finalOrdered,
      admissibleOrdersByLinkId,
    }
  }
}

let deriveAdmissibleOrders = (~state: state, ~linkId: string): array<int> =>
  derive(~state).admissibleOrdersByLinkId->Belt.Map.String.get(linkId)->Option.getOr([])
