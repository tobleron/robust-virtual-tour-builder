// @efficiency-role: domain-logic

type forwardRef = CanonicalTraversalTypes.forwardRef

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
