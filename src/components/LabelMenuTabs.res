module SceneTagTab = {
  @react.component
  let make = (
    ~currentCategory: string,
    ~currentLabel: string,
    ~flickeringLabel: option<string>,
    ~customLabel: string,
    ~setCustomLabel: (string => string) => unit,
    ~handleSetCategory: (string, JsxEvent.Mouse.t) => unit,
    ~handleSelect: (string, JsxEvent.Mouse.t) => unit,
    ~handleApplyCustom: unit => unit,
    ~handleClear: unit => unit,
    ~handleRemoveAllUntagged: unit => unit,
  ) => <>
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
          onClick={e => handleSetCategory("indoor", e)}
        >
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
          onClick={e => handleSetCategory("outdoor", e)}
        >
          {React.string("Outdoor")}
        </button>
      </div>
    </div>

    <Shadcn.DropdownMenu.Label
      className="text-[10px] font-semibold uppercase tracking-widest text-slate-500 pb-2 px-3 pt-1"
    >
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
              `}
            >
              {React.string(label)}
            </Shadcn.DropdownMenu.Item>
          })
          ->React.array}
        </Shadcn.DropdownMenu.Group>
      })
      ->React.array}
    </div>

    <Shadcn.DropdownMenu.Separator />

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
          className="px-3 py-1 bg-primary text-white rounded-md text-[10px] font-semibold uppercase tracking-widest hover:bg-primary-light active:scale-95 transition-all shadow-sm"
        >
          {React.string("SET")}
        </button>
      </div>
      <button
        onClick={_ => handleClear()}
        className="w-full mt-2 py-1 bg-white border border-slate-200 text-slate-400 rounded-md text-[10px] font-semibold uppercase tracking-widest hover:bg-orange-50 hover:text-danger hover:border-danger/30 active:scale-95 transition-all"
      >
        {React.string("CLEAR LABEL")}
      </button>
      <button
        onClick={_ => handleRemoveAllUntagged()}
        className="w-full mt-2 py-1 bg-white border border-slate-200 text-slate-400 rounded-md text-[10px] font-semibold uppercase tracking-widest hover:bg-red-50 hover:text-danger hover:border-danger/30 active:scale-95 transition-all"
      >
        {React.string("REMOVE ALL UNTAGGED")}
      </button>
    </div>
  </>
}

module SequenceTab = {
  let formatSceneNumber = (value: option<int>): string =>
    switch value {
    | Some(sceneNumber) => "#" ++ Belt.Int.toString(sceneNumber)
    | None => "#?"
    }

  @react.component
  let make = (
    ~orderedHotspots: array<HotspotSequence.orderedHotspot>,
    ~sequenceDrafts: Belt.Map.String.t<string>,
    ~setSequenceDrafts: (Belt.Map.String.t<string> => Belt.Map.String.t<string>) => unit,
    ~commitSequenceDraft: (~linkId: string, ~currentSequence: int) => unit,
  ) =>
    <div className="flex flex-col h-full max-h-[300px]">
      <div className="px-3 py-2 border-b border-slate-100 bg-slate-50/50">
        <h4 className="text-[10px] font-semibold uppercase tracking-widest text-slate-500">
          {React.string("Hotspot Sequence")}
        </h4>
        <p className="text-[10px] text-slate-400 mt-1 leading-relaxed">
          {React.string(
            "Scene numbers stay fixed. Editing a step changes internal traversal order only.",
          )}
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
            let draftValue =
              sequenceDrafts
              ->Belt.Map.String.get(row.linkId)
              ->Option.getOr(Belt.Int.toString(row.sequence))
            let isDirty = draftValue != Belt.Int.toString(row.sequence)
            <div
              key={row.linkId}
              className="flex items-center gap-2 px-2 py-1.5 rounded-md border border-slate-100 hover:border-slate-200 bg-white"
            >
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
                  {React.string(
                    formatSceneNumber(row.sceneNumber) ++
                    " " ++
                    row.sceneLabel ++
                    " -> " ++
                    formatSceneNumber(row.targetSceneNumber) ++
                    " " ++
                    row.targetLabel,
                  )}
                </div>
                <div className="text-[9px] font-mono text-slate-400 truncate">
                  {React.string(
                    "step " ++ Belt.Int.toString(row.sequence) ++ " • " ++ row.linkId,
                  )}
                </div>
              </div>
              <button
                onClick={_ =>
                  commitSequenceDraft(~linkId=row.linkId, ~currentSequence=row.sequence)}
                disabled={!isDirty}
                className={`px-2 py-1 rounded text-[9px] font-semibold uppercase tracking-wider transition-all ${if (
                    isDirty
                  ) {
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
}
