// @efficiency-role: ui-component

@react.component
let make = React.memo((
  ~onNew: unit => unit,
  ~onSave: (~signal: BrowserBindings.AbortController.signal, ~onCancel: unit => unit) => unit,
  ~onLoad: (~signal: BrowserBindings.AbortController.signal, ~onCancel: unit => unit) => unit,
  ~onAbout: unit => unit,
  ~onExport: (~signal: BrowserBindings.AbortController.signal, ~onCancel: unit => unit) => unit,
  ~onTeaser: unit => unit,
  ~exportReady: bool,
  ~teaserReady: bool,
) => {
  let isPermitted = UseIsInteractionPermitted.useIsInteractionPermitted()

  let saveCancelRef = React.useRef(() => ())
  let (saveExecute, saveCancel, savePending, _saveThrottled) = UseThrottledAction.useThrottledAction(
    ~action=async (~signal) => onSave(~signal, ~onCancel=() => saveCancelRef.current()),
    ~debounceMs=2000,
    ~rateLimit=(5, 60000),
  )
  React.useEffect1(() => {
    saveCancelRef.current = saveCancel
    None
  }, [saveCancel])

  let loadCancelRef = React.useRef(() => ())
  let (loadExecute, loadCancel, loadPending, _loadThrottled) = UseThrottledAction.useThrottledAction(
    ~action=async (~signal) => onLoad(~signal, ~onCancel=() => loadCancelRef.current()),
    ~debounceMs=2000,
    ~rateLimit=(5, 60000),
  )
  React.useEffect1(() => {
    loadCancelRef.current = loadCancel
    None
  }, [loadCancel])

  let exportCancelRef = React.useRef(() => ())
  let (
    exportExecute,
    exportCancel,
    exportPending,
    _exportThrottled,
  ) = UseThrottledAction.useThrottledAction(
    ~action=async (~signal) => onExport(~signal, ~onCancel=() => exportCancelRef.current()),
    ~debounceMs=5000,
    ~rateLimit=(3, 60000),
  )
  React.useEffect1(() => {
    exportCancelRef.current = exportCancel
    None
  }, [exportCancel])

  React.useEffect0(() => {
    Logger.initialized(~module_="SidebarActions")
    None
  })

  <div className="px-5 pb-6">
    <div className="grid grid-cols-4 gap-2 mb-3">
      <button
        className="sidebar-action-btn-square hover-lift active-push group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/50 disabled:opacity-50 disabled:cursor-not-allowed"
        onClick={_ => onNew()}
        disabled={!isPermitted}
        ariaLabel="New"
      >
        <LucideIcons.FilePlus size=20 strokeWidth=1.0 />
        <span> {React.string("New")} </span>
      </button>

      <button
        className={`sidebar-action-btn-square hover-lift active-push group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/50 disabled:opacity-50 disabled:cursor-not-allowed ${savePending
            ? "btn-loading"
            : ""}`}
        onClick={_ => {
          let _ = saveExecute()
        }}
        disabled={!isPermitted || savePending}
        ariaLabel="Save"
      >
        <LucideIcons.Save size=20 strokeWidth=1.0 />
        <span> {React.string(savePending ? "Saving" : "Save")} </span>
      </button>

      <button
        className={`sidebar-action-btn-square hover-lift active-push group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/50 disabled:opacity-50 disabled:cursor-not-allowed ${loadPending
            ? "btn-loading"
            : ""}`}
        onClick={_ => {
          let _ = loadExecute()
        }}
        disabled={!isPermitted || loadPending}
        ariaLabel="Load"
      >
        <LucideIcons.FolderOpen size=20 strokeWidth=1.0 />
        <span> {React.string("Load")} </span>
      </button>

      <button
        className="sidebar-action-btn-square hover-lift active-push group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/50 disabled:opacity-50 disabled:cursor-not-allowed"
        onClick={_ => onAbout()}
        disabled={!isPermitted}
        ariaLabel="About"
      >
        <LucideIcons.Info size=20 strokeWidth=1.0 />
        <span> {React.string("About")} </span>
      </button>
    </div>

    <div className="grid grid-cols-2 gap-2">
      <button
        className={`sidebar-action-btn-wide hover-lift active-push group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/50 disabled:opacity-50 disabled:cursor-not-allowed ${exportPending
            ? "btn-loading"
            : ""}`}
        disabled={!exportReady || !isPermitted || exportPending}
        onClick={_ => {
          let _ = exportExecute()
        }}
        ariaLabel="Export Tour"
      >
        <LucideIcons.Download
          className="text-white transition-all duration-300" size=20 strokeWidth=1.0
        />
        <span> {React.string(exportPending ? "Exporting" : "Export")} </span>
      </button>

      <button
        className="sidebar-action-btn-wide hover-lift active-push group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/50 disabled:opacity-50 disabled:cursor-not-allowed"
        disabled={!teaserReady || !isPermitted}
        onClick={_ => onTeaser()}
        ariaLabel="Create Teaser"
      >
        <LucideIcons.Film
          className="text-white transition-all duration-300" size=20 strokeWidth=1.0
        />
        <span> {React.string("Teaser")} </span>
      </button>
    </div>
  </div>
})
