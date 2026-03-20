/* src/components/LinkModal.res */

open Types
open ReBindings
open! EventBus

// Constants

// Helper to escape HTML
let escapeHtml = unsafe => {
  unsafe
  ->String.replaceRegExp(/&/g, "&amp;")
  ->String.replaceRegExp(/</g, "&lt;")
  ->String.replaceRegExp(/>/g, "&gt;")
  ->String.replaceRegExp(/\"/g, "&quot;")
  ->String.replaceRegExp(/'/g, "&#039;")
}

let resolveDisplaySceneLabel = (scene: scene): string => {
  let trimmedLabel = scene.label->String.trim
  if trimmedLabel != "" {
    trimmedLabel
  } else {
    scene.name
  }
}

let formatSceneNumberLabel = (~sceneNumber: option<int>, ~label: string): string =>
  switch sceneNumber {
  | Some(value) => "#" ++ Belt.Int.toString(value) ++ " " ++ label
  | None => label
  }

let formatDestinationOptionLabel = (~sceneNumber: option<int>, ~scene: scene): string =>
  formatSceneNumberLabel(~sceneNumber, ~label=resolveDisplaySceneLabel(scene))

let formatSequenceOptionLabel = (
  ~sequence: int,
  ~targetSceneNumber: option<int>,
  ~targetLabel: string,
): string =>
  Belt.Int.toString(sequence) ++
  " -> " ++
  formatSceneNumberLabel(~sceneNumber=targetSceneNumber, ~label=targetLabel)

type sequenceChoice = {
  sequence: int,
  title: string,
  detail: string,
}

let formatSequenceChoiceTitle = (~sequence: int, ~currentSequence: int): string =>
  if sequence == currentSequence {
    "Keep current stop"
  } else if sequence < currentSequence {
    "Place before current stop"
  } else {
    "Place after current stop"
  }

let buildSequenceChoice = (
  ~row: HotspotSequence.orderedHotspot,
  ~currentSequence: int,
): sequenceChoice => {
  let title = formatSequenceChoiceTitle(~sequence=row.sequence, ~currentSequence)
  let detail =
    formatSequenceOptionLabel(
      ~sequence=row.sequence,
      ~targetSceneNumber=row.targetSceneNumber,
      ~targetLabel=row.targetLabel,
    )
  {sequence: row.sequence, title, detail}
}

let showLinkModal = (
  ~pitch: float,
  ~yaw: float,
  ~camPitch: float,
  ~camYaw: float,
  ~camHfov: float,
  ~linkDraft: Nullable.t<Types.linkDraft>=Nullable.null,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
  (),
) => {
  let state = getState()

  // Determine next sequential index for smart selection
  let nextIndex = state.activeIndex + 1
  let scenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)

  let draftOpt = Nullable.toOption(linkDraft)
  let isRetargeting = switch draftOpt {
  | Some(d) => d.retargetHotspot != None
  | None => false
  }

  let defaultTargetSceneId = if isRetargeting {
    let retarget = draftOpt->Option.flatMap(d => d.retargetHotspot)->Option.getOrThrow
    switch Belt.Array.get(scenes, retarget.sceneIndex) {
    | Some(sourceScene) =>
      switch Belt.Array.get(sourceScene.hotspots, retarget.hotspotIndex) {
      | Some(h) =>
        switch h.targetSceneId {
        | Some(sceneId) => sceneId
        | None =>
          scenes
          ->Belt.Array.getBy(s => s.name == h.target)
          ->Option.map(s => s.id)
          ->Option.getOr("")
        }
      | None => ""
      }
    | None => ""
    }
  } else {
    scenes
    ->Belt.Array.getIndexBy(s => {
      let isSelected = switch draftOpt {
      | Some(_) =>
        let idx = scenes->Belt.Array.getIndexBy(x => x.name == s.name)->Option.getOr(-1)
        idx == nextIndex
      | None => false
      }
      isSelected
    })
    ->Belt.Option.flatMap(idx => scenes->Belt.Array.get(idx))
    ->Belt.Option.map(s => s.id)
    ->Belt.Option.getWithDefault("")
  }

  let retargetLinkId = if isRetargeting {
    switch draftOpt->Option.flatMap(d => d.retargetHotspot) {
    | Some(retarget) =>
      switch retarget.hotspotLinkId {
      | Some(linkId) => Some(linkId)
      | None =>
        switch Belt.Array.get(scenes, retarget.sceneIndex) {
        | Some(sourceScene) =>
          Belt.Array.get(sourceScene.hotspots, retarget.hotspotIndex)->Option.map(h => h.linkId)
        | None => None
        }
      }
    | None => None
    }
  } else {
    None
  }

  let sequenceByLinkId = if isRetargeting {
    HotspotSequence.deriveDisplayOrder(~state)
  } else {
    Belt.Map.String.empty
  }
  let sceneNumberBySceneId = HotspotSequence.deriveSceneNumberBySceneId(~state)
  let contextualHotspots = if isRetargeting {
    switch retargetLinkId {
    | Some(linkId) => HotspotSequence.deriveContextualOrderedHotspots(~state, ~linkId)
    | None => []
    }
  } else {
    []
  }

  let retargetSequence =
    retargetLinkId->Option.flatMap(linkId => sequenceByLinkId->Belt.Map.String.get(linkId))

  let admissibleSequenceOrders = if isRetargeting {
    switch retargetLinkId {
    | Some(linkId) => HotspotSequence.deriveContextualSequenceOrders(~state, ~linkId)
    | None => []
    }
  } else {
    []
  }

  let sequenceDefaultValue = switch retargetSequence {
  | Some(currentSequence) =>
    if admissibleSequenceOrders->Belt.Array.some(order => order == currentSequence) {
      currentSequence
    } else {
      admissibleSequenceOrders->Belt.Array.get(0)->Option.getOr(currentSequence)
    }
  | None => admissibleSequenceOrders->Belt.Array.get(0)->Option.getOr(1)
  }

  let sequenceChoices = contextualHotspots->Belt.Array.map(row =>
    buildSequenceChoice(~row, ~currentSequence=sequenceDefaultValue)
  )

  let content =
    <div className="link-modal-form">
      <div className="link-modal-field">
        <label htmlFor="link-target" className="link-modal-field-label">
          {React.string("Destination")}
        </label>
        <select
          id="link-target"
          className="link-modal-select"
          ariaLabel="Select destination room for navigation link"
          defaultValue={defaultTargetSceneId}
        >
          <option value="" className="bg-slate-800"> {React.string("-- Select Room --")} </option>
          {scenes
          ->Belt.Array.mapWithIndex((i, s) => {
            // Hide source scene from options
            let isSource = if isRetargeting {
              let retarget = draftOpt->Option.flatMap(d => d.retargetHotspot)->Option.getOrThrow
              i == retarget.sceneIndex
            } else {
              i == state.activeIndex
            }

            if isSource {
              React.null
            } else {
              <option key={s.id} value={s.id} className="bg-slate-800">
                {React.string(
                  formatDestinationOptionLabel(
                    ~sceneNumber=sceneNumberBySceneId->Belt.Map.String.get(s.id),
                    ~scene=s,
                  ),
                )}
              </option>
            }
          })
          ->React.array}
        </select>
      </div>
      {if isRetargeting {
        <div className="link-modal-field">
          <div className="link-modal-field-label">
            {React.string("Sequence")}
          </div>
          {switch retargetSequence {
          | Some(_) =>
            if admissibleSequenceOrders->Belt.Array.length > 0 {
              <>
                <div className="link-modal-sequence-hint">
                  {React.string(
                    "Use this when you are placing a hotspot into the route. Pick whether it should sit before, at, or after the current stop; every hotspot after that point will shift automatically.",
                  )}
                </div>
                <div
                  id="link-sequence-order-group"
                  className="link-modal-sequence-grid"
                  role="radiogroup"
                  ariaLabel="Choose hotspot sequence position"
                >
                  {sequenceChoices
                  ->Belt.Array.map(choice => {
                    let inputId = "link-sequence-order-" ++ Belt.Int.toString(choice.sequence)
                    <label key=inputId htmlFor=inputId className="link-modal-sequence-choice">
                      <input
                        id=inputId
                        name="link-sequence-order"
                        type_="radio"
                        className="link-modal-sequence-choice-input"
                        value={Belt.Int.toString(choice.sequence)}
                        defaultChecked={choice.sequence == sequenceDefaultValue}
                      />
                      <span className="link-modal-sequence-choice-copy">
                        <span className="link-modal-sequence-choice-title">
                          {React.string(choice.title)}
                        </span>
                        <span className="link-modal-sequence-choice-detail">
                          {React.string(choice.detail)}
                        </span>
                      </span>
                    </label>
                  })
                  ->React.array}
                </div>
              </>
            } else {
              <div className="link-modal-return-note">
                {React.string("No valid sequence positions available for this link.")}
              </div>
            }
          | None =>
            <div className="link-modal-return-note">
              {React.string("Return link (R): sequence is not editable.")}
            </div>
          }}
        </div>
      } else {
        React.null
      }}
    </div>

  let onSave = () => {
    let parsedSequenceInput: option<option<int>> = if isRetargeting {
      switch Nullable.toOption(Dom.querySelector(Dom.documentBody, "#link-sequence-order-group input:checked")) {
      | Some(el) =>
        let raw = Dom.getValue(el)->String.trim
        if raw == "" {
          Some(None)
        } else {
          switch Belt.Int.fromString(raw) {
          | Some(value) if value >= 1 => Some(Some(value))
          | _ => None
          }
        }
      | None => Some(None)
      }
    } else {
      Some(None)
    }

    switch parsedSequenceInput {
    | None =>
      NotificationManager.dispatch({
        id: "",
        importance: Warning,
        context: Operation("link_modal"),
        message: "Please choose a sequence position",
        details: None,
        action: None,
        duration: NotificationTypes.defaultTimeoutMs(Warning),
        dismissible: true,
        createdAt: Date.now(),
      })
    | Some(desiredSequenceOrder) =>
      let element = Dom.getElementById("link-target")
      switch Nullable.toOption(element) {
      | Some(el) =>
        let selectedSceneId = Dom.getValue(el)
        let targetSceneOpt = scenes->Belt.Array.getBy(s => s.id == selectedSceneId)
        let targetName = targetSceneOpt->Option.map(s => s.name)->Option.getOr("")
        let targetSceneId = targetSceneOpt->Option.map(s => s.id)
        if selectedSceneId == "" || targetName == "" {
          NotificationManager.dispatch({
            id: "",
            importance: Warning,
            context: Operation("link_modal"),
            message: "Please select a destination room",
            details: None,
            action: None,
            duration: NotificationTypes.defaultTimeoutMs(Warning),
            dismissible: true,
            createdAt: Date.now(),
          })
        } else if isRetargeting {
          let retarget = draftOpt->Option.flatMap(d => d.retargetHotspot)->Option.getOrThrow
          let hasInvalidSequenceRequest = switch (retargetLinkId, desiredSequenceOrder) {
          | (Some(activeLinkId), Some(desiredOrder)) =>
            let allowedOrders = HotspotSequence.deriveContextualSequenceOrders(
              ~state=getState(),
              ~linkId=activeLinkId,
            )
            allowedOrders->Belt.Array.length > 0 &&
              !(allowedOrders->Belt.Array.some(order => order == desiredOrder))
          | _ => false
          }
          if hasInvalidSequenceRequest {
            NotificationManager.dispatch({
              id: "",
              importance: Warning,
              context: Operation("link_modal"),
              message: "Selected sequence is not valid for current traversal",
              details: Some("Choose one of the allowed sequence positions."),
              action: None,
              duration: NotificationTypes.defaultTimeoutMs(Warning),
              dismissible: true,
              createdAt: Date.now(),
            })
          } else {
            // RE-TARGETING LOGIC: Use direct target updater with stable IDs
            HotspotManager.handleUpdateHotspotTarget(
              ~sceneIndex=retarget.sceneIndex,
              ~hotspotIndex=retarget.hotspotIndex,
              ~sceneId=?retarget.sceneId,
              ~hotspotLinkId=?retarget.hotspotLinkId,
              targetName,
              targetSceneId,
            )->ignore

            // Also update timeline item for this linkId
            let linkId = switch retarget.hotspotLinkId {
            | Some(id) => id
            | None =>
              // Fallback to index-based lookup for the linkId if ID missing in draft
              let sourceScene = Belt.Array.get(scenes, retarget.sceneIndex)->Option.getOrThrow
              let hotspot =
                Belt.Array.get(sourceScene.hotspots, retarget.hotspotIndex)->Option.getOrThrow
              hotspot.linkId
            }

            // Find existing timeline item for this linkId and update its target
            state.timeline->Belt.Array.forEach(item => {
              if item.linkId == linkId {
                dispatch(
                  Actions.UpdateTimelineStep(
                    item.id,
                    Logger.castToJson({
                      "targetScene": targetSceneId->Option.getOr(targetName),
                    }),
                  ),
                )
              }
            })

            switch (retargetLinkId, desiredSequenceOrder) {
            | (Some(activeLinkId), Some(desiredOrder)) =>
              let reorderUpdates = HotspotSequence.buildReorderUpdates(
                ~state=getState(),
                ~linkId=activeLinkId,
                ~desiredOrder,
              )

              if reorderUpdates->Belt.Array.length > 0 {
                let actions =
                  reorderUpdates->Belt.Array.map(update => Actions.UpdateHotspotMetadata(
                    update.sceneIndex,
                    update.hotspotIndex,
                    Logger.castToJson({"sequenceOrder": update.sequenceOrder}),
                  ))
                dispatch(Actions.Batch(actions))
              }
            | _ => ()
            }

            // Close and cleanup
            EventBus.dispatch(CloseModal)
            if state.isLinking {
              dispatch(Actions.StopLinking)
            }
          }
        } else {
          let displayPitch = pitch -. Constants.hotspotVisualOffsetDegrees

          let draftOpt = Nullable.toOption(linkDraft)
          let startPitch = switch draftOpt {
          | Some(d) => d.camPitch
          | None => camPitch
          }
          let startYaw = switch draftOpt {
          | Some(d) => d.camYaw
          | None => camYaw
          }
          let startHfov = switch draftOpt {
          | Some(d) => d.camHfov
          | None => camHfov
          }

          // Generate unique Link ID
          let allLinkIds = scenes->Belt.Array.reduce([], (acc, s) => {
            Belt.Array.concat(acc, s.hotspots->Belt.Array.map(h => h.linkId))
          })
          let usedSet = Belt.Set.String.fromArray(allLinkIds)
          let newLinkId = TourLogic.generateLinkId(usedSet)

          // Handle types for Nullable fields
          let newHotspot: Types.hotspot = {
            linkId: newLinkId,
            yaw,
            pitch,
            target: targetName,
            targetSceneId,
            targetYaw: None,
            targetPitch: None,
            targetHfov: None,
            startYaw: Some(startYaw),
            startPitch: Some(startPitch),
            startHfov: Some(startHfov),
            viewFrame: Some({yaw: camYaw, pitch: camPitch, hfov: camHfov}),
            waypoints: switch draftOpt {
            | Some(d) =>
              switch d.intermediatePoints {
              | Some(points) =>
                let mapped = points->Belt.Array.map(p => {
                  let vf: Types.viewFrame = {
                    yaw: p.camYaw,
                    pitch: p.camPitch,
                    hfov: p.camHfov,
                  }
                  vf
                })
                Some(mapped)
              | None => None
              }
            | None => None
            },
            displayPitch: Some(displayPitch),
            transition: None,
            duration: None,
            isAutoForward: None,
            sequenceOrder: None,
          }

          Logger.info(
            ~module_="LinkModal",
            ~message="SAVING_LINK",
            ~data=Some({
              "targetName": targetName,
              "newLinkId": newLinkId,
              "beforeState": state.isLinking,
            }),
            (),
          )

          HotspotManager.handleAddHotspot(state.activeIndex, newHotspot)->ignore

          // Part 5 Helper: Auto-register in timeline for Visual Pipeline visibility
          let timelineItemJson = JsonParsers.Encoders.timelineItem({
            id: "step_" ++ Date.now()->Float.toString,
            linkId: newLinkId,
            sceneId: switch Belt.Array.get(scenes, state.activeIndex) {
            | Some(s) => s.id
            | None => ""
            },
            targetScene: targetSceneId->Option.getOr(targetName),
            transition: "fade",
            duration: 1000,
          })
          dispatch(Actions.AddToTimeline(timelineItemJson))

          // Use setTimeout to ensure state updates properly after hotspot is added
          let _ = setTimeout(() => {
            Logger.info(
              ~module_="LinkModal",
              ~message="EXIT_SEQUENCE_START",
              ~data=Some({"stateBeforeExit": getState().isLinking}),
              (),
            )

            // Step 1: Close modal first to prevent any re-renders
            EventBus.dispatch(CloseModal)
            Logger.info(~module_="LinkModal", ~message="MODAL_CLOSED", ())

            // Step 2: Hide draft lines immediately
            SvgManager.hide("link_draft_red")
            SvgManager.hide("link_draft_yellow")
            Logger.info(~module_="LinkModal", ~message="DRAFT_LINES_HIDDEN", ())

            // Step 3: Exit linking mode
            dispatch(Actions.StopLinking)
            Logger.info(
              ~module_="LinkModal",
              ~message="STOP_LINKING_DISPATCHED",
              ~data=Some({"stateAfterDispatch": getState().isLinking}),
              (),
            )
          }, 50)
        }
      | None => ()
      }
    }
  }

  EventBus.dispatch(
    ShowModal({
      title: "Link Destination",
      description: None,
      icon: Some("add_link"),
      content: Some(content),
      allowClose: Some(true),
      onClose: Some(
        () => {
          // Explicitly hide draft lines on modal close
          SvgManager.hide("link_draft_red")
          SvgManager.hide("link_draft_yellow")
          if getState().isLinking {
            dispatch(Actions.StopLinking)
          }
        },
      ),
      className: Some("modal-blue modal-link-destination"),
      buttons: [
        {
          label: "Save Link",
          class_: "modal-link-btn-primary",
          onClick: onSave,
          autoClose: Some(false),
        },
        {
          label: "Cancel",
          class_: "modal-link-btn-secondary",
          onClick: () => {
            // Explicitly hide draft lines on cancel
            SvgManager.hide("link_draft_red")
            SvgManager.hide("link_draft_yellow")
            EventBus.dispatch(CloseModal)
          },
          autoClose: Some(false),
        },
      ],
    }),
  )

  let _ = setTimeout(() => {
    switch Nullable.toOption(Dom.getElementById("link-target")) {
    | Some(el) => Dom.focus(el)
    | None => ()
    }
  }, 300)
}
