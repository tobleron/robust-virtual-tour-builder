// @efficiency-role: ui-component

@react.component
let make = React.memo(() => {
  React.useEffect0(() => {
    Logger.initialized(~module_="SidebarBranding")
    None
  })

  <div className="flex flex-col items-center px-6 pt-6 pb-6">
    <div className="flex items-center justify-center gap-3 mb-1">
      <h1 className="font-heading font-semibold text-white tracking-widest uppercase text-[27px]">
        {React.string("ROBUST")}
      </h1>
      <LucideIcons.Home className="text-white text-[45px]" size=45 />
    </div>
    <div className="font-normal text-white tracking-[0.25em] text-[13px] uppercase">
      {React.string("Virtual Tour Builder")}
    </div>
    <div className="flex items-center text-slate-400 mt-1 sidebar-version-line font-normal font-mono">
      <span className="text-[10px] tracking-wider">
        {React.string(`${Version.getVersionLabel()} • ${Version.getBuildInfo()}`)}
      </span>
    </div>
  </div>
})
