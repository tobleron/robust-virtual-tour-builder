// @efficiency-role: ui-component

external makeStyle: {..} => ReactDOM.Style.t = "%identity"

@react.component
let make = React.memo((~procState: SidebarLogic.SidebarTypes.processingPayload) => {
  React.useEffect0(() => {
    Logger.initialized(~module_="SidebarProcessing")
    None
  })

  if procState["active"] {
    <div
      className="mx-4 mb-3 bg-slate-50 border border-slate-200 rounded-xl p-3 shadow-sm animate-fade-in"
      role="status"
      ariaLive=#polite
    >
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center gap-2">
          <div className="spinner !w-3 !h-3 !border-2" />
          <div className="font-semibold text-slate-700 text-[10px] uppercase tracking-widest">
            {React.string(procState["phase"] == "" ? "Processing" : procState["phase"])}
          </div>
        </div>
        <div className="font-heading font-semibold text-primary text-[11px]">
          {React.string(Float.toFixed(procState["progress"], ~digits=0) ++ "%")}
        </div>
      </div>
      <div className="bg-slate-200 h-1.5 rounded-full overflow-hidden relative">
        <div
          className="h-full transition-all duration-300 rounded-full sidebar-progress-fill"
          style={makeStyle({"width": Float.toFixed(procState["progress"], ~digits=0) ++ "%"})}
        />
      </div>
      {
        let parts = String.split(procState["message"], "|")
        let leftPart = Belt.Array.get(parts, 0)->Option.getOr(procState["message"])
        let rightPart = Belt.Array.get(parts, 1)->Option.getOr("")

        <div
          className="text-[10px] text-slate-500 mt-2 font-semibold uppercase tracking-tight flex items-center justify-between gap-2"
        >
          <div className="flex items-center gap-2 min-w-0">
            <span className="w-1 h-1 bg-success rounded-full animate-pulse shrink-0" />
            <span className="truncate"> {React.string(leftPart)} </span>
          </div>
          {if rightPart != "" {
            <span className="text-slate-400 truncate max-w-[50%]"> {React.string(rightPart)} </span>
          } else {
            React.null
          }}
        </div>
      }
    </div>
  } else {
    React.null
  }
})
