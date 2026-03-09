open Actions

let buildSequenceDrafts = (
  orderedHotspots: array<HotspotSequence.orderedHotspot>,
): Belt.Map.String.t<string> =>
  orderedHotspots->Belt.Array.reduce(Belt.Map.String.empty, (acc, row) =>
    acc->Belt.Map.String.set(row.linkId, Belt.Int.toString(row.sequence))
  )

let applySequenceReorder = (
  ~dispatch: action => unit,
  ~linkId: string,
  ~desiredOrder: int,
) => {
  let liveState = AppContext.getBridgeState()
  let updates = HotspotSequence.buildReorderUpdates(~state=liveState, ~linkId, ~desiredOrder)

  if updates->Belt.Array.length > 0 {
    let actions =
      updates->Belt.Array.map(update => UpdateHotspotMetadata(
        update.sceneIndex,
        update.hotspotIndex,
        Logger.castToJson({"sequenceOrder": update.sequenceOrder}),
      ))
    dispatch(Batch(actions))
    LabelMenuSupport.notifySuccess(~message="Hotspot sequence updated")
  } else {
    let allowedOrders = HotspotSequence.deriveAdmissibleOrders(~state=liveState, ~linkId)
    if (
      allowedOrders->Belt.Array.length > 0 &&
        !(allowedOrders->Belt.Array.some(order => order == desiredOrder))
    ) {
      LabelMenuSupport.notifyWarning(
        ~message="Sequence position is not valid",
        ~details="Only traversal-valid positions are allowed for this hotspot.",
      )
    }
  }
}

let commitSequenceDraft = (
  ~sequenceDrafts: Belt.Map.String.t<string>,
  ~setSequenceDrafts: ((Belt.Map.String.t<string> => Belt.Map.String.t<string>)) => unit,
  ~dispatch: action => unit,
  ~linkId: string,
  ~currentSequence: int,
) => {
  let currentText =
    sequenceDrafts->Belt.Map.String.get(linkId)->Option.getOr(Belt.Int.toString(currentSequence))

  switch Belt.Int.fromString(currentText) {
  | Some(parsed) if parsed >= 1 => applySequenceReorder(~dispatch, ~linkId, ~desiredOrder=parsed)
  | _ =>
    setSequenceDrafts(prev => prev->Belt.Map.String.set(linkId, Belt.Int.toString(currentSequence)))
    LabelMenuSupport.notifyWarning(~message="Sequence must be a positive integer")
  }
}
