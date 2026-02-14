@react.component
let make = () => {
  let (isDiagnostic, setIsDiagnostic) = React.useState(_ => Logger.isDiagnosticMode())

    let toggleDiagnostic = _ => {
      if Logger.isDiagnosticMode() {
        Logger.disableDiagnostics()
        setIsDiagnostic(_ => false)
        NotificationManager.dispatch({
          id: "",
          importance: Info,
          context: Operation("sidebar_diagnostics"),
          message: "Diagnostic Mode Disabled",
          details: None,
          action: None,
          duration: 10000,
          dismissible: true,
          createdAt: Date.now(),
        })
      } else {
        Logger.enableDiagnostics()
        Logger.trace(
          ~module_="About",
          ~message="User enabled diagnostic mode via About Dialog.",
          (),
        )
        setIsDiagnostic(_ => true)
        NotificationManager.dispatch({
          id: "",
          importance: Success,
          context: Operation("sidebar_diagnostics"),
          message: "Diagnostic Mode Enabled",
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Success),
          dismissible: true,
          createdAt: Date.now(),
        })
      }
    }

    <div className="flex flex-col gap-6 mt-2 items-center w-full">
      <div className="flex flex-col gap-1 items-center text-center">
        <p className="text-white font-semibold font-mono text-[11px]">
          {React.string(`Version: ${Version.version}`)}
        </p>
        <p className="text-slate-300 font-mono text-[10px]">
          {React.string(`Build: ${Version.buildInfo}`)}
        </p>
      </div>

      <div
        className="cursor-pointer flex items-center gap-2 group opacity-70 hover:opacity-100 transition-opacity"
        onClick={toggleDiagnostic}
      >
        <span
          className={`text-[9px] font-mono uppercase tracking-wider transition-colors ${isDiagnostic
              ? "text-green-500 font-bold"
              : "text-slate-500 group-hover:text-slate-400"}`}
        >
          {React.string("Debug Mode")}
        </span>
        <div
          className={`w-8 h-4 rounded-full relative transition-colors ${isDiagnostic
              ? "bg-green-500"
              : "bg-slate-700 group-hover:bg-slate-600"}`}
        >
          <div
            className={`absolute top-0.5 w-3 h-3 rounded-full bg-white shadow-sm transition-all ${isDiagnostic
                ? "right-0.5"
                : "left-0.5"}`}
          />
        </div>
      </div>
    </div>
  }
