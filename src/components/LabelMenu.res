/* src/components/LabelMenu.res */
open Types
open Actions

type tab =
  | SceneTag
  | Sequence

let isUntaggedScene = (scene: scene): bool => {
  let normalized = scene.label->String.trim->String.toLowerCase
  normalized == "" || normalized->String.includes("untagged")
}

let bulkDeleteBlockReason = (state: state): option<string> => {
  let simulationBusy = switch state.simulation.status {
  | Idle => false
  | _ => true
  }

  let navBusy =
    (switch state.navigationState.navigation {
    | Idle => false
    | _ => true
    }) ||
    (switch state.navigationState.navigationFsm {
    | IdleFsm => false
    | _ => true
    })

  if state.isLinking {
    Some("Linking mode is active.")
  } else if state.movingHotspot != None {
    Some("Finish moving hotspot placement first.")
  } else if simulationBusy {
    Some("Stop tour preview first.")
  } else if navBusy {
    Some("Wait for scene navigation to finish.")
  } else {
    switch state.appMode {
    | SystemBlocking(_) => Some("Please wait until the current system operation finishes.")
    | _ => None
    }
  }
}

let notifyInfo = (~message: string) => {
  NotificationManager.dispatch({
    id: "",
    importance: Info,
    context: Operation("label_menu"),
    message,
    details: None,
    action: None,
    duration: NotificationTypes.defaultTimeoutMs(Info),
    dismissible: true,
    createdAt: Date.now(),
  })
}

let notifyWarning = (~message: string, ~details: option<string>=?) => {
  NotificationManager.dispatch({
    id: "",
    importance: Warning,
    context: Operation("label_menu"),
    message,
    details,
    action: None,
    duration: NotificationTypes.defaultTimeoutMs(Warning),
    dismissible: true,
    createdAt: Date.now(),
  })
}

let notifySuccess = (~message: string) => {
  NotificationManager.dispatch({
    id: "",
    importance: Success,
    context: Operation("label_menu"),
    message,
    details: None,
    action: None,
    duration: NotificationTypes.defaultTimeoutMs(Success),
    dismissible: true,
    createdAt: Date.now(),
  })
}

@react.component
let make = (~onClose: unit => unit, ~sceneIndex: option<int>=?) => {
  let state = AppContext.useAppState()
  let dispatch = AppContext.useAppDispatch()
  let canMutateProject = Capability.useCapability(CanMutateProject)

  let (activeTab, _setActiveTab) = React.useState(_ => SceneTag)
  let (customLabel, setCustomLabel) = React.useState(_ => "")
  let (flickeringLabel, setFlickeringLabel) = React.useState(_ => None)
  let (sequenceDrafts, setSequenceDrafts) = React.useState(_ => Belt.Map.String.empty)

  let targetIndex = sceneIndex->Option.getOr(state.activeIndex)

  // Get current scene data
  let currentScene = Belt.Array.get(
    SceneInventory.getActiveScenes(state.inventory, state.sceneOrder),
    targetIndex,
  )
  let currentCategory = switch currentScene {
  | Some(s) => s.category == "" ? "outdoor" : s.category
  | None => "outdoor"
  }
  let currentLabel = switch currentScene {
  | Some(s) => s.label
  | None => ""
  }

  let orderedHotspots = React.useMemo1(() => HotspotSequence.deriveOrderedHotspots(~state), [
    state.structuralRevision,
  ])

  // Effect to sync custom label input with current scene label
  React.useEffect1(() => {
    setCustomLabel(_ => currentLabel)
    None
  }, [currentLabel])

  React.useEffect1(() => {
    let drafts =
      orderedHotspots
      ->Belt.Array.reduce(Belt.Map.String.empty, (acc, row) => {
        acc->Belt.Map.String.set(row.linkId, Belt.Int.toString(row.sequence))
      })
    setSequenceDrafts(_ => drafts)
    None
  }, [state.structuralRevision])

  let handleSelect = (label, e) => {
    JsxEvent.Mouse.preventDefault(e)
    setFlickeringLabel(_ => Some(label))

    // Recover base name using current state (before label change)
    let baseName = switch currentScene {
    | Some(s) => TourLogic.recoverBaseName(s.name, s.label)
    | None => ""
    }

    let _ = ReBindings.Window.setTimeout(() => {
      setFlickeringLabel(_ => None)
      // Pass _baseName to help the reducer preserve it during rename
      dispatch(
        UpdateSceneMetadata(
          targetIndex,
          Logger.castToJson({
            "label": label,
            "_baseName": baseName,
          }),
        ),
      )
      Logger.info(
        ~module_="LabelMenu",
        ~message="LABEL_SET",
        ~data=Some({"label": label, "index": targetIndex, "preservedBase": baseName}),
        (),
      )
      notifySuccess(~message="Label Set: " ++ label)
      onClose()
    }, 800)
  }

  let handleApplyCustom = () => {
    let rawVal = customLabel->String.trim
    if rawVal != "" {
      let isAllCaps = String.toUpperCase(rawVal) == rawVal && String.toLowerCase(rawVal) != rawVal
      let val = if isAllCaps {
        rawVal
        ->String.split(" ")
        ->Belt.Array.map(word => {
          let len = String.length(word)
          if len > 0 {
            String.toUpperCase(String.substring(word, ~start=0, ~end=1)) ++
            String.toLowerCase(String.substring(word, ~start=1, ~end=len))
          } else {
            word
          }
        })
        ->Array.joinUnsafe(" ")
      } else {
        rawVal
      }

      // Recover base name using current state (before label change)
      let baseName = switch currentScene {
      | Some(s) => TourLogic.recoverBaseName(s.name, s.label)
      | None => ""
      }
      dispatch(
        UpdateSceneMetadata(
          targetIndex,
          Logger.castToJson({
            "label": val,
            "_baseName": baseName,
          }),
        ),
      )
      Logger.info(
        ~module_="LabelMenu",
        ~message="LABEL_SET_CUSTOM",
        ~data=Some({"label": val, "index": targetIndex}),
        (),
      )
      notifySuccess(~message="Label Set: " ++ val)
      onClose()
    }
  }

  let handleClear = () => {
    // Recover base name using current state (before label change)
    let baseName = switch currentScene {
    | Some(s) => TourLogic.recoverBaseName(s.name, s.label)
    | None => ""
    }

    dispatch(
      UpdateSceneMetadata(
        targetIndex,
        Logger.castToJson({
          "label": "",
          "_baseName": baseName,
        }),
      ),
    )
    notifyWarning(~message="Label Cleared")
    onClose()
  }

  let handleSetCategory = (cat, e) => {
    JsxEvent.Mouse.preventDefault(e)
    if currentCategory != cat {
      dispatch(UpdateSceneMetadata(targetIndex, Logger.castToJson({"category": cat})))
    }
  }

  let applySequenceReorder = (linkId: string, desiredOrder: int) => {
    let liveState = AppContext.getBridgeState()
    let updates = HotspotSequence.buildReorderUpdates(~state=liveState, ~linkId, ~desiredOrder)

    if updates->Belt.Array.length > 0 {
      let actions = updates->Belt.Array.map(update =>
        UpdateHotspotMetadata(
          update.sceneIndex,
          update.hotspotIndex,
          Logger.castToJson({"sequenceOrder": update.sequenceOrder}),
        )
      )
      dispatch(Batch(actions))
      notifySuccess(~message="Hotspot sequence updated")
    } else {
      let allowedOrders = HotspotSequence.deriveAdmissibleOrders(~state=liveState, ~linkId)
      if allowedOrders->Belt.Array.length > 0 &&
          !(allowedOrders->Belt.Array.some(order => order == desiredOrder)) {
        notifyWarning(
          ~message="Sequence position is not valid",
          ~details="Only traversal-valid positions are allowed for this hotspot.",
        )
      }
    }
  }

  let commitSequenceDraft = (~linkId: string, ~currentSequence: int) => {
    let currentText = sequenceDrafts->Belt.Map.String.get(linkId)->Option.getOr(
      Belt.Int.toString(currentSequence),
    )

    switch Belt.Int.fromString(currentText) {
    | Some(parsed) if parsed >= 1 =>
      applySequenceReorder(linkId, parsed)
    | _ =>
      setSequenceDrafts(prev =>
        prev->Belt.Map.String.set(linkId, Belt.Int.toString(currentSequence))
      )
      notifyWarning(~message="Sequence must be a positive integer")
    }
  }

  let executeRemoveAllUntagged = () => {
    let liveState = AppContext.getBridgeState()
    switch bulkDeleteBlockReason(liveState) {
    | Some(reason) => notifyWarning(~message="Cannot remove untagged scenes now", ~details=reason)
    | None =>
      let activeScenes = SceneInventory.getActiveScenes(liveState.inventory, liveState.sceneOrder)
      let untaggedIds =
        activeScenes
        ->Belt.Array.keep(isUntaggedScene)
        ->Belt.Array.map(scene => scene.id)

      if untaggedIds->Belt.Array.length == 0 {
        notifyInfo(~message="No untagged scenes found")
      } else {
        let indicesDescending =
          untaggedIds
          ->Belt.Array.keepMap(id => activeScenes->Belt.Array.getIndexBy(scene => scene.id == id))
          ->Belt.SortArray.stableSortBy((a, b) => b - a)

        if indicesDescending->Belt.Array.length == 0 {
          notifyInfo(~message="No untagged scenes found")
        } else {
          let deleteActions = indicesDescending->Belt.Array.map(idx => DeleteScene(idx))
          let actions = Belt.Array.concat(deleteActions, [CleanupTimeline])
          dispatch(Batch(actions))
          notifySuccess(
            ~message="Removed " ++
            Belt.Int.toString(indicesDescending->Belt.Array.length) ++
            " untagged scenes",
          )
          onClose()
        }
      }
    }
  }

  let handleRemoveAllUntagged = () => {
    if !canMutateProject {
      notifyWarning(~message="Project is currently locked")
    } else {
      let liveState = AppContext.getBridgeState()
      switch bulkDeleteBlockReason(liveState) {
      | Some(reason) => notifyWarning(~message="Cannot remove untagged scenes now", ~details=reason)
      | None =>
        let untaggedCount =
          SceneInventory.getActiveScenes(liveState.inventory, liveState.sceneOrder)
          ->Belt.Array.keep(isUntaggedScene)
          ->Belt.Array.length

        if untaggedCount == 0 {
          notifyInfo(~message="No untagged scenes found")
        } else {
          EventBus.dispatch(
            EventBus.ShowModal({
              title: "Remove Untagged Scenes",
              description: Some(
                "This will permanently delete " ++
                Belt.Int.toString(untaggedCount) ++
                " untagged scenes from the project.",
              ),
              icon: Some("warning"),
              content: Some(
                <div className="text-[12px] text-white/80 leading-relaxed">
                  {React.string("This action cannot be undone.")}
                </div>,
              ),
              allowClose: Some(true),
              onClose: None,
              className: Some("modal-blue"),
              buttons: [
                {
                  label: "Cancel",
                  class_: "bg-slate-100/10 text-white hover:bg-white/20",
                  onClick: () => (),
                  autoClose: Some(true),
                },
                {
                  label: "Delete Untagged",
                  class_: "bg-red-500/20 text-white hover:bg-red-500/40",
                  onClick: executeRemoveAllUntagged,
                  autoClose: Some(true),
                },
              ],
            }),
          )
        }
      }
    }
  }

  let renderSceneTagTab = () =>
    <>
      /* Category Toggle */
      <div className="px-3 pt-3 pb-2" onClick={e => JsxEvent.Mouse.stopPropagation(e)}>
        <div className="flex bg-slate-100 p-1 rounded-lg">
          <button
            className={`flex-1 py-0.5 text-[10px] font-semibold uppercase tracking-wider rounded-md transition-all focus:outline-none border border-transparent ${if (
                currentCategory == "indoor"
              ) {
                "bg-white text-primary shadow-sm border-slate-200"
              } else {
                "text-slate-400 hover:text-slate-600"
              }}`}
            onClick={e => handleSetCategory("indoor", e)}>
            {React.string("Indoor")}
          </button>
          <button
            className={`flex-1 py-0.5 text-[10px] font-semibold uppercase tracking-wider rounded-md transition-all focus:outline-none border border-transparent ${if (
                currentCategory == "outdoor"
              ) {
                "bg-white text-primary shadow-sm border-slate-200"
              } else {
                "text-slate-400 hover:text-slate-600"
              }}`}
            onClick={e => handleSetCategory("outdoor", e)}>
            {React.string("Outdoor")}
          </button>
        </div>
      </div>

      /* Presets Header */
      <Shadcn.DropdownMenu.Label
        className="text-[10px] font-semibold uppercase tracking-widest text-slate-500 pb-2 px-3 pt-1">
        {React.string("Room Presets")}
      </Shadcn.DropdownMenu.Label>

      <div className="flex-1 overflow-y-auto custom-scrollbar">
        {Constants.roomLabelPresets
        ->Dict.toArray
        ->Belt.Array.keep(((cat, _)) => cat == currentCategory)
        ->Belt.Array.map(((category, labels)) => {
          <Shadcn.DropdownMenu.Group key={category}>
            <div className="px-3 py-1 flex items-center gap-2">
              <span className="text-[10px] font-semibold text-slate-400 uppercase tracking-tighter">
                {React.string(category)}
              </span>
              <div className="flex-1 h-px bg-slate-100" />
            </div>
            {labels
            ->Belt.Array.map(label => {
              let isActive = label == currentLabel
              let isFlickering = flickeringLabel == Some(label)
              <Shadcn.DropdownMenu.Item
                key={label}
                onClick={e => handleSelect(label, e)}
                className={`mx-1 my-0.5 px-2 py-1 text-[10px] font-semibold uppercase tracking-wide cursor-pointer
                ${isActive ? "bg-primary/10 text-primary" : "text-slate-600"}
                ${isFlickering ? "animate-flicker-orange-flat" : ""}
              `}>
                {React.string(label)}
              </Shadcn.DropdownMenu.Item>
            })
            ->React.array}
          </Shadcn.DropdownMenu.Group>
        })
        ->React.array}
      </div>

      <Shadcn.DropdownMenu.Separator />

      /* Custom Label Section - Wrapped in a non-Item div to prevent auto-close */
      <div className="p-3 bg-slate-50/50" onClick={e => JsxEvent.Mouse.stopPropagation(e)}>
        <h4 className="text-[10px] font-semibold uppercase tracking-widest text-slate-400 mb-2">
          {React.string("Custom Label")}
        </h4>
        <div className="flex gap-1.5">
          <input
            type_="text"
            placeholder="Name..."
            value={customLabel}
            onChange={e => {
              let val = JsxEvent.Form.target(e)["value"]
              setCustomLabel(_ => val)
            }}
            onKeyDown={e => {
              JsxEvent.Keyboard.stopPropagation(e)
              if JsxEvent.Keyboard.key(e) == "Enter" {
                handleApplyCustom()
              }
            }}
            className="flex-1 min-w-0 bg-white border border-slate-200 rounded-md px-2 py-1 text-[11px] font-semibold text-slate-700 outline-none focus:border-primary transition-all"
          />
          <button
            onClick={_ => handleApplyCustom()}
            className="px-3 py-1 bg-primary text-white rounded-md text-[10px] font-semibold uppercase tracking-widest hover:bg-primary-light active:scale-95 transition-all shadow-sm">
            {React.string("SET")}
          </button>
        </div>
        <button
          onClick={_ => handleClear()}
          className="w-full mt-2 py-1 bg-white border border-slate-200 text-slate-400 rounded-md text-[10px] font-semibold uppercase tracking-widest hover:bg-orange-50 hover:text-danger hover:border-danger/30 active:scale-95 transition-all">
          {React.string("CLEAR LABEL")}
        </button>
        <button
          onClick={_ => handleRemoveAllUntagged()}
          className="w-full mt-2 py-1 bg-white border border-slate-200 text-slate-400 rounded-md text-[10px] font-semibold uppercase tracking-widest hover:bg-red-50 hover:text-danger hover:border-danger/30 active:scale-95 transition-all">
          {React.string("REMOVE ALL UNTAGGED")}
        </button>
      </div>
    </>

  let renderSequenceTab = () =>
    <div className="flex flex-col h-full max-h-[300px]">
      <div className="px-3 py-2 border-b border-slate-100 bg-slate-50/50">
        <h4 className="text-[10px] font-semibold uppercase tracking-widest text-slate-500">
          {React.string("Hotspot Sequence")}
        </h4>
        <p className="text-[10px] text-slate-400 mt-1 leading-relaxed">
          {React.string("Numbers follow simulation order. Editing a number auto-shifts others.")}
        </p>
      </div>
      <div className="flex-1 overflow-y-auto custom-scrollbar px-2 py-2 space-y-1">
        {if orderedHotspots->Belt.Array.length == 0 {
          <div className="px-2 py-4 text-[11px] text-slate-400 text-center">
            {React.string("No navigable hotspots found.")}
          </div>
        } else {
          orderedHotspots
          ->Belt.Array.map(row => {
            let draftValue = sequenceDrafts->Belt.Map.String.get(row.linkId)->Option.getOr(
              Belt.Int.toString(row.sequence),
            )
            let isDirty = draftValue != Belt.Int.toString(row.sequence)
            <div
              key={row.linkId}
              className="flex items-center gap-2 px-2 py-1.5 rounded-md border border-slate-100 hover:border-slate-200 bg-white">
              <input
                type_="number"
                min="1"
                step=1.0
                value={draftValue}
                onChange={e => {
                  let value = JsxEvent.Form.target(e)["value"]
                  setSequenceDrafts(prev => prev->Belt.Map.String.set(row.linkId, value))
                }}
                onBlur={_ => commitSequenceDraft(~linkId=row.linkId, ~currentSequence=row.sequence)}
                onKeyDown={e => {
                  JsxEvent.Keyboard.stopPropagation(e)
                  if JsxEvent.Keyboard.key(e) == "Enter" {
                    commitSequenceDraft(~linkId=row.linkId, ~currentSequence=row.sequence)
                  }
                }}
                className="w-12 bg-[#0e2d52] text-white font-mono text-[11px] text-center rounded border border-[#0e2d52] px-1 py-1 outline-none"
              />
              <div className="min-w-0 flex-1">
                <div className="text-[10px] font-semibold text-slate-700 truncate">
                  {React.string(row.sceneLabel ++ " -> " ++ row.targetLabel)}
                </div>
                <div className="text-[9px] font-mono text-slate-400 truncate"> {React.string(row.linkId)} </div>
              </div>
              <button
                onClick={_ => commitSequenceDraft(~linkId=row.linkId, ~currentSequence=row.sequence)}
                disabled={!isDirty}
                className={`px-2 py-1 rounded text-[9px] font-semibold uppercase tracking-wider transition-all ${if isDirty {
                    "bg-primary text-white hover:bg-primary-light active:scale-95"
                  } else {
                    "bg-slate-200 text-slate-400 cursor-not-allowed"
                  }}`}
              >
                {React.string("Set")}
              </button>
            </div>
          })
          ->React.array
        }}
      </div>
    </div>

  <div className="flex flex-col w-[230px] max-h-[380px]">
    {switch activeTab {
    | SceneTag => renderSceneTagTab()
    | Sequence => renderSequenceTab()
    }}
  </div>
}
