// @efficiency-role: ui-component

@react.component
let make = React.memo((
  ~onNew: unit => unit,
  ~onSave: (
    ~signal: BrowserBindings.AbortController.signal,
    ~onCancel: unit => unit,
  ) => Promise.t<unit>,
  ~onLoad: (
    ~signal: BrowserBindings.AbortController.signal,
    ~onCancel: unit => unit,
  ) => Promise.t<unit>,
  ~onAbout: unit => unit,
  ~onExport: (
    ~signal: BrowserBindings.AbortController.signal,
    ~onCancel: unit => unit,
  ) => Promise.t<unit>,
  ~onTeaser: unit => unit,
  ~exportReady: bool,
  ~teaserReady: bool,
) => {
  let isPermitted = Hooks.useIsInteractionPermitted()

  let saveAbortRef = React.useRef(None)
  let (saveExecute, savePending, _saveThrottled) = UseInteraction.useInteraction(
    ~id="project_save",
    ~policy=InteractionPolicies.projectMutation,
    ~action=async () => {
      let ctrl = BrowserBindings.AbortController.newAbortController()
      saveAbortRef.current = Some(ctrl)
      let signal = BrowserBindings.AbortController.signal(ctrl)
      let onCancel = () => {
        switch saveAbortRef.current {
        | Some(c) => BrowserBindings.AbortController.abort(c)
        | None => ()
        }
      }
      await onSave(~signal, ~onCancel)
      saveAbortRef.current = None
    },
  )

  let loadAbortRef = React.useRef(None)
  let (loadExecute, loadPending, _loadThrottled) = UseInteraction.useInteraction(
    ~id="project_load",
    ~policy=InteractionPolicies.projectMutation,
    ~action=async () => {
      let ctrl = BrowserBindings.AbortController.newAbortController()
      loadAbortRef.current = Some(ctrl)
      let signal = BrowserBindings.AbortController.signal(ctrl)
      let onCancel = () => {
        switch loadAbortRef.current {
        | Some(c) => BrowserBindings.AbortController.abort(c)
        | None => ()
        }
      }
      await onLoad(~signal, ~onCancel)
      loadAbortRef.current = None
    },
  )

  let exportAbortRef = React.useRef(None)
  let (
    exportExecute,
    exportPending,
    _exportThrottled,
  ) = UseInteraction.useInteraction(
    ~id="project_export",
    ~policy=InteractionPolicies.projectMutation,
    ~action=async () => {
      let ctrl = BrowserBindings.AbortController.newAbortController()
      exportAbortRef.current = Some(ctrl)
      let signal = BrowserBindings.AbortController.signal(ctrl)
      let onCancel = () => {
        switch exportAbortRef.current {
        | Some(c) => BrowserBindings.AbortController.abort(c)
        | None => ()
        }
      }
      await onExport(~signal, ~onCancel)
      exportAbortRef.current = None
    },
  )

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
