// @efficiency-role: ui-component

@react.component
let make = React.memo((
  ~onNew: unit => unit,
  ~onSave: (~signal: BrowserBindings.AbortSignal.t, ~onCancel: unit => unit) => Promise.t<unit>,
  ~onLoad: (~signal: BrowserBindings.AbortSignal.t, ~onCancel: unit => unit) => Promise.t<unit>,
  ~onAbout: unit => unit,
  ~onExport: (~signal: BrowserBindings.AbortSignal.t, ~onCancel: unit => unit) => Promise.t<unit>,
  ~onTeaser: (
    ~format: string,
    ~signal: BrowserBindings.AbortSignal.t,
    ~onCancel: unit => unit,
  ) => Promise.t<unit>,
  ~exportReady: bool,
  ~teaserReady: bool,
  ~isLinking: bool,
) => {
  let isPermitted = Hooks.useIsInteractionPermitted()
  let (showTeaserDialog, setShowTeaserDialog) = React.useState(_ => false)
  let (teaserFormat, setTeaserFormat) = React.useState(_ => "mp4")

  let saveAbortRef = React.useRef(None)
  let (saveExecute, savePending, _saveThrottled) = UseInteraction.useInteraction(
    ~id="project_save",
    ~policy=InteractionPolicies.projectMutation,
    ~action=async () => {
      let ctrl = BrowserBindings.AbortController.make()
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
      let ctrl = BrowserBindings.AbortController.make()
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
      let ctrl = BrowserBindings.AbortController.make()
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

  let teaserAbortRef = React.useRef(None)
  let (
    teaserExecute,
    teaserPending,
    _teaserThrottled,
  ) = UseInteraction.useInteraction(
    ~id="project_teaser",
    ~policy=InteractionPolicies.projectMutation,
    ~action=async () => {
      let ctrl = BrowserBindings.AbortController.make()
      teaserAbortRef.current = Some(ctrl)
      let signal = BrowserBindings.AbortController.signal(ctrl)
      let onCancel = () => {
        switch teaserAbortRef.current {
        | Some(c) => BrowserBindings.AbortController.abort(c)
        | None => ()
        }
      }
      await onTeaser(~format=teaserFormat, ~signal, ~onCancel)
      teaserAbortRef.current = None
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
        className={`sidebar-action-btn-wide hover-lift active-push group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/50 disabled:opacity-50 disabled:cursor-not-allowed ${teaserPending
            ? "btn-loading"
            : ""}`}
        disabled={!teaserReady || !isPermitted || isLinking || teaserPending}
        onClick={_ => {
          setTeaserFormat(_ => "mp4")
          setShowTeaserDialog(_ => true)
        }}
        ariaLabel="Create Teaser"
      >
        <LucideIcons.Film
          className="text-white transition-all duration-300" size=20 strokeWidth=1.0
        />
        <span> {React.string(teaserPending ? "Teasing" : "Teaser")} </span>
      </button>
    </div>

    {if showTeaserDialog {
      <div className="fixed inset-0 z-[17050] flex items-center justify-center bg-black/45 p-4">
        <div className="w-[320px] rounded-xl border border-white/20 bg-slate-900 text-white shadow-2xl p-4">
          <div className="text-sm font-semibold uppercase tracking-wide mb-3"> {React.string("Teaser Format")} </div>
          <div className="grid grid-cols-2 gap-2 mb-4">
            <button
              className="rounded-lg border border-white/10 bg-slate-800/40 px-3 py-3 text-sm font-semibold text-white/45 cursor-not-allowed"
              disabled=true
            >
              {React.string("WebM (Later)")}
            </button>
            <button
              className={`rounded-lg border px-3 py-3 text-sm font-semibold transition-colors ${teaserFormat == "mp4"
                  ? "border-emerald-400 bg-emerald-600/30"
                  : "border-white/20 bg-slate-800/80 hover:bg-slate-700/80"}`}
              onClick={_ => setTeaserFormat(_ => "mp4")}
            >
              {React.string("MP4")}
            </button>
          </div>

          <div className="grid grid-cols-2 gap-2">
            <button
              className="rounded-lg border border-white/20 bg-slate-800/80 px-3 py-2.5 text-sm font-medium hover:bg-slate-700/80"
              onClick={_ => setShowTeaserDialog(_ => false)}
            >
              {React.string("Cancel")}
            </button>
            <button
              className="rounded-lg border border-emerald-400/50 bg-emerald-600/30 px-3 py-2.5 text-sm font-semibold hover:bg-emerald-500/35"
              onClick={_ => {
                setShowTeaserDialog(_ => false)
                let _ = teaserExecute()
              }}
            >
              {React.string("Generate")}
            </button>
          </div>
        </div>
      </div>
    } else {
      React.null
    }}
  </div>
})
