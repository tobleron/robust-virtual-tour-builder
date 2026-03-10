open Types

type badgeKind = CanonicalTraversalTypes.badgeKind =
  | Sequence(int)
  | Return
type forwardRef = CanonicalTraversalTypes.forwardRef
type model = CanonicalTraversalTypes.model
type traversalSnapshot = CanonicalTraversalTypes.traversalSnapshot

let stripSceneTag = (raw: string): string => {
  CanonicalTraversalSupport.stripSceneTag(raw)
}
let displaySceneLabel = (scene: scene): string => {
  CanonicalTraversalSupport.displaySceneLabel(scene)
}
let clampOrder = (value: int, maxValue: int): int =>
  CanonicalTraversalSupport.clampOrder(value, maxValue)
let addVisitedLink = (visited: array<string>, linkId: string): array<string> =>
  CanonicalTraversalSupport.addVisitedLink(visited, linkId)
let applyVisitedActions = (~visited: array<string>, ~actions: array<Actions.action>): array<
  string,
> => CanonicalTraversalSupport.applyVisitedActions(~visited, ~actions)
let firstNewLinkId = (~visited: array<string>, ~actions: array<Actions.action>): option<string> =>
  CanonicalTraversalSupport.firstNewLinkId(~visited, ~actions)

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

let deriveReturnLinkIdSet = (~activeScenes: array<scene>, ~parentBySceneId: Belt.Map.String.t<string>) =>
  CanonicalTraversalSupport.deriveReturnLinkIdSet(~activeScenes, ~parentBySceneId)

let collectForwardRefs = (~activeScenes: array<scene>, ~traversalOrderByLinkId: Belt.Map.String.t<int>, ~returnLinkIdSet: Belt.Set.String.t) =>
  CanonicalTraversalSupport.collectForwardRefs(~activeScenes, ~traversalOrderByLinkId, ~returnLinkIdSet)
let sortDefaultForwardRefs = (refs: array<forwardRef>): array<forwardRef> =>
  CanonicalTraversalSupport.sortDefaultForwardRefs(refs)
let applyManualOverrides = (baseOrdered: array<forwardRef>): array<forwardRef> =>
  CanonicalTraversalSupport.applyManualOverrides(baseOrdered)
let isValidForwardOrder = (~ordered: array<forwardRef>): bool =>
  CanonicalTraversalSupport.isValidForwardOrder(~ordered)
let moveRefToIndex = (~ordered: array<forwardRef>, ~currentIndex: int, ~nextIndex: int): array<
  forwardRef,
> => CanonicalTraversalSupport.moveRefToIndex(~ordered, ~currentIndex, ~nextIndex)
let deriveAdmissibleOrdersByLinkId = (~ordered: array<forwardRef>): Belt.Map.String.t<
  array<int>,
> => CanonicalTraversalSupport.deriveAdmissibleOrdersByLinkId(~ordered)

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
