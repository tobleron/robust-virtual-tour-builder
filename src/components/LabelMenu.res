/* src/components/LabelMenu.res */
open Types

@react.component
let make = (~onClose: unit => unit) => {
  let state = AppContext.useAppState()
  let dispatch = AppContext.useAppDispatch()
  let (customLabel, setCustomLabel) = React.useState(_ => "")
  let scrollRef = React.useRef(Nullable.null)

  // Get current scene data
  let currentScene = Belt.Array.get(state.scenes, state.activeIndex)
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
    dispatch(UpdateSceneMetadata(state.activeIndex, Obj.magic({"label": label})))
    Logger.info(~module_="LabelMenu", ~message="LABEL_SET", ~data=Some({"label": label}), ())
    EventBus.dispatch(ShowNotification("Label Set: " ++ label, #Success))
    onClose()
  }

  let handleApplyCustom = () => {
    let val = customLabel->String.trim
    if val != "" {
      dispatch(UpdateSceneMetadata(state.activeIndex, Obj.magic({"label": val})))
      Logger.info(~module_="LabelMenu", ~message="LABEL_SET_CUSTOM", ~data=Some({"label": val}), ())
      EventBus.dispatch(ShowNotification("Label Set: " ++ val, #Success))
      onClose()
    }
  }

  let handleClear = () => {
    dispatch(UpdateSceneMetadata(state.activeIndex, Obj.magic({"label": ""})))
    EventBus.dispatch(ShowNotification("Label Cleared", #Warning))
    onClose()
  }

  <div className="flex flex-col w-[280px]">
    /* Scrollable Presets Section */
    <div
      ref={ReactDOM.Ref.domRef(scrollRef)} className="flex-1 overflow-y-auto py-2 custom-scrollbar"
    >
      {Constants.roomLabelPresets
      ->Dict.toArray
      ->Belt.Array.keep(((cat, _)) => cat == currentCategory)
      ->Belt.Array.map(((category, labels)) => {
        <div key={category} className="flex flex-col">
          <div className="flex items-center gap-2 px-4 py-2">
            <span className="text-[10px] font-black uppercase tracking-widest text-slate-500">
              {React.string(category)}
            </span>
            <div className="flex-1 h-px bg-slate-200" />
          </div>
          <div className="grid grid-cols-1 gap-0.5 px-2">
            {labels
            ->Belt.Array.map(label => {
              let isActive = label == currentLabel
              <button
                key={label}
                onClick={_ => handleSelect(label)}
                className={`w-full text-left px-3 py-2.5 rounded-xl text-[11px] font-bold uppercase tracking-wider transition-all
                  ${isActive
                    ? "bg-slate-100 text-primary-light"
                    : "text-slate-600 hover:bg-slate-50 hover:text-primary"}`}
              >
                {React.string(label)}
              </button>
            })
            ->React.array}
          </div>
        </div>
      })
      ->React.array}
    </div>

    /* Custom Label Section */
    <div className="p-4 border-t border-slate-100">
      <h4 className="text-[10px] font-black uppercase tracking-widest text-slate-500 mb-3">
        {React.string("Custom Label Entry")}
      </h4>
      <div className="flex gap-2">
        <input
          type_="text"
          placeholder="Enter name..."
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
          className="flex-1 bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-bold text-slate-700 outline-none focus:border-primary-light focus:ring-4 focus:ring-primary/5 transition-all"
        />
        <button
          onClick={_ => handleApplyCustom()}
          className="px-4 py-2 bg-primary text-white rounded-xl text-[10px] font-black uppercase tracking-widest hover:bg-primary-light active:scale-95 transition-all shadow-md shadow-primary/20"
        >
          {React.string("SET")}
        </button>
        <button
          onClick={_ => handleClear()}
          className="px-3 py-2 bg-white border border-slate-200 text-slate-600 rounded-xl text-[10px] font-black uppercase tracking-widest hover:bg-orange-50 hover:text-danger hover:border-danger/30 active:scale-95 transition-all"
        >
          {React.string("CLEAR")}
        </button>
      </div>
    </div>
  </div>
}
