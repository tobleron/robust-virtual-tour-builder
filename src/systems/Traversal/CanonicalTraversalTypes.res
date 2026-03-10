// @efficiency-role: data-model

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
