/* src/components/Sidebar/SidebarProjectInfo.res */

@react.component
let make = React.memo((~localTourName, ~onTourNameChange, ~onUploadClick) => {
  React.useEffect0(() => {
    Logger.initialized(~module_="SidebarProjectInfo")
    None
  })

  <div className="flex flex-col bg-white border-b border-slate-200 shrink-0 z-20">
    <div className="flex items-stretch gap-3 p-4 pb-2">
      <button
        className="w-14 h-auto min-h-14 flex flex-col items-center justify-center gap-1 rounded-xl transition-all hover:brightness-110 hover:shadow-lg hover-lift active-push group overflow-hidden relative focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:outline-none sidebar-upload-btn shrink-0 text-white"
        onClick={_ => onUploadClick()}
      >
        <div
          className="absolute inset-0 bg-gradient-to-b from-transparent via-white/10 to-transparent translate-x-[-150%] translate-y-[-150%] rotate-45 group-hover:translate-x-[150%] group-hover:translate-y-[150%] transition-transform duration-1000"
        />
        <LucideIcons.Camera className="text-white" size=24 strokeWidth=2.0 />
        <span
          className="text-[10px] font-semibold tracking-widest uppercase writing-vertical-lr hidden"
        >
          {React.string("Add")}
        </span>
      </button>

      <div className="flex-1 flex flex-col justify-center gap-1.5">
        <label className="sidebar-project-label" htmlFor="project-name-input">
          {React.string("Project Name")}
        </label>
        <input
          id="project-name-input"
          type_="text"
          className="sidebar-project-input"
          placeholder="New Tour..."
          value={localTourName}
          onChange={onTourNameChange}
        />
      </div>
    </div>
  </div>
})
