/* src/components/LabelMenu.res */
open Types

@react.component
let make = (~onClose: unit => unit, ~sceneIndex: option<int>=?) => {
  let state = AppContext.useAppState()
  let dispatch = AppContext.useAppDispatch()
  let (customLabel, setCustomLabel) = React.useState(_ => "")

  let targetIndex = sceneIndex->Option.getOr(state.activeIndex)

  // Get current scene data
  let currentScene = Belt.Array.get(state.scenes, targetIndex)
  let currentCategory = switch currentScene {
  | Some(s) => s.category == "" ? "outdoor" : s.category
  | None => "outdoor"
  }
  let currentLabel = switch currentScene {
  | Some(s) => s.label
  | None => ""
  }

  // Effect to sync custom label input with current scene label
  React.useEffect1(() => {
    setCustomLabel(_ => currentLabel)
    None
  }, [currentLabel])

  let handleSelect = label => {
    dispatch(UpdateSceneMetadata(targetIndex, Logger.castToJson({"label": label})))
    Logger.info(
      ~module_="LabelMenu",
      ~message="LABEL_SET",
      ~data=Some({"label": label, "index": targetIndex}),
      (),
    )
    EventBus.dispatch(ShowNotification("Label Set: " ++ label, #Success))
    onClose()
  }

  let handleApplyCustom = () => {
    let val = customLabel->String.trim
    if val != "" {
      dispatch(UpdateSceneMetadata(targetIndex, Logger.castToJson({"label": val})))
      Logger.info(
        ~module_="LabelMenu",
        ~message="LABEL_SET_CUSTOM",
        ~data=Some({"label": val, "index": targetIndex}),
        (),
      )
      EventBus.dispatch(ShowNotification("Label Set: " ++ val, #Success))
      onClose()
    }
  }

  let handleClear = () => {
    dispatch(UpdateSceneMetadata(targetIndex, Logger.castToJson({"label": ""})))
    EventBus.dispatch(ShowNotification("Label Cleared", #Warning))
    onClose()
  }

  let handleSetCategory = (cat, e) => {
    JsxEvent.Mouse.preventDefault(e)
    if currentCategory != cat {
      dispatch(UpdateSceneMetadata(targetIndex, Logger.castToJson({"category": cat})))
    }
  }

  <div className="flex flex-col w-[200px] max-h-[350px]">
    /* Category Toggle */
    <div className="px-3 pt-3 pb-2" onClick={e => JsxEvent.Mouse.stopPropagation(e)}>
      <div className="flex bg-slate-100 p-1 rounded-lg">
        <button
          className={`flex-1 py-0.5 text-[10px] font-black uppercase tracking-wider rounded-md transition-all focus:outline-none border border-transparent ${if currentCategory == "indoor" {
            "bg-white text-primary shadow-sm border-slate-200"
          } else {
            "text-slate-400 hover:text-slate-600"
          }}`}
          onClick={e => handleSetCategory("indoor", e)}
        >
          {React.string("Indoor")}
        </button>
        <button
          className={`flex-1 py-0.5 text-[10px] font-black uppercase tracking-wider rounded-md transition-all focus:outline-none border border-transparent ${if currentCategory == "outdoor" {
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

    /* Presets Header */
    <Shadcn.DropdownMenu.Label
      className="text-[10px] font-black uppercase tracking-widest text-slate-500 pb-2 px-3 pt-1"
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
            <span className="text-[8px] font-black text-slate-400 uppercase tracking-tighter">
              {React.string(category)}
            </span>
            <div className="flex-1 h-px bg-slate-100" />
          </div>
          {labels
          ->Belt.Array.map(label => {
            let isActive = label == currentLabel
            <Shadcn.DropdownMenu.Item
              key={label}
              onClick={_ => handleSelect(label)}
              className={`mx-1 my-0.5 px-2 py-1 text-[10px] font-bold uppercase tracking-wide cursor-pointer
                ${isActive ? "bg-primary/10 text-primary" : "text-slate-600"}`}
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

    /* Custom Label Section - Wrapped in a non-Item div to prevent auto-close */
    <div className="p-3 bg-slate-50/50" onClick={e => JsxEvent.Mouse.stopPropagation(e)}>
      <h4 className="text-[9px] font-black uppercase tracking-widest text-slate-400 mb-2">
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
            if JsxEvent.Keyboard.key(e) == "Enter" {
              handleApplyCustom()
            }
          }}
          className="flex-1 min-w-0 bg-white border border-slate-200 rounded-md px-2 py-1 text-[11px] font-bold text-slate-700 outline-none focus:border-primary transition-all"
        />
        <button
          onClick={_ => handleApplyCustom()}
          className="px-3 py-1 bg-primary text-white rounded-md text-[10px] font-black uppercase tracking-widest hover:bg-primary-light active:scale-95 transition-all shadow-sm"
        >
          {React.string("SET")}
        </button>
      </div>
      <button
        onClick={_ => handleClear()}
        className="w-full mt-2 py-1 bg-white border border-slate-200 text-slate-400 rounded-md text-[9px] font-black uppercase tracking-widest hover:bg-orange-50 hover:text-danger hover:border-danger/30 active:scale-95 transition-all"
      >
        {React.string("CLEAR LABEL")}
      </button>
    </div>
  </div>
}
