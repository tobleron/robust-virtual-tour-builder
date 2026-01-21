/* src/components/SceneActionMenu.res */

@react.component
let make = (~anchor: Dom.element, ~index: int, ~onClose: unit => unit) => {
  let dispatch = AppContext.useAppDispatch()

  let handleDelete = () => {
    dispatch(Actions.DeleteScene(index))
    onClose()
  }

  let handleClearLinks = () => {
    dispatch(Actions.ClearHotspots(index))
    onClose()
  }

  <PopOver anchor onClose offset=8.0 alignment=#BottomRight>
    <div className="flex flex-col min-w-[200px] p-1.5" onClick={JsxEvent.Mouse.stopPropagation}>
      <button
        className="px-4 py-3 cursor-pointer text-slate-700 font-bold text-[11px] uppercase tracking-widest hover:bg-white/40 rounded-xl transition-all flex items-center gap-3 group outline-none focus:ring-2 focus:ring-primary/20"
        onClick={_ => handleClearLinks()}
      >
        <span className="material-icons text-lg text-primary" ariaHidden=true>
          {React.string("link_off")}
        </span>
        <span> {React.string("Clear Links")} </span>
      </button>

      <div className="h-px bg-slate-200/30 my-1 mx-2" />

      <button
        className="px-4 py-3 cursor-pointer text-slate-700 font-bold text-[11px] uppercase tracking-widest hover:bg-danger/10 hover:text-danger rounded-xl transition-all flex items-center gap-3 group outline-none focus:ring-2 focus:ring-danger/20"
        onClick={_ => handleDelete()}
      >
        <span className="material-icons text-lg text-danger" ariaHidden=true>
          {React.string("delete_outline")}
        </span>
        <span> {React.string("Remove Scene")} </span>
      </button>
    </div>
  </PopOver>
}
