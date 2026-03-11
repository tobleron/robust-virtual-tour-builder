// @efficiency-role: ui-component

@react.component
let make = React.memo((
  ~onNew: unit => unit,
  ~onSave: (
    ~mode: PersistencePreferences.saveTarget,
    ~signal: BrowserBindings.AbortSignal.t,
    ~onCancel: unit => unit,
  ) => Promise.t<unit>,
  ~onLoad: (~signal: BrowserBindings.AbortSignal.t, ~onCancel: unit => unit) => Promise.t<unit>,
  ~onSettings: unit => unit,
  ~onExport: (
    ~options: SidebarBase.SidebarTypes.publishOptions,
    ~signal: BrowserBindings.AbortSignal.t,
    ~onCancel: unit => unit,
  ) => Promise.t<unit>,
  ~onTeaser: (
    ~format: string,
    ~styleId: string,
    ~panSpeedId: string,
    ~signal: BrowserBindings.AbortSignal.t,
    ~onCancel: unit => unit,
  ) => Promise.t<unit>,
  ~exportReady: bool,
  ~teaserReady: bool,
  ~isLinking: bool,
) => {
  let isPermitted = Hooks.useIsInteractionPermitted()
  let (preferredSaveTarget, setPreferredSaveTarget) = React.useState(_ =>
    PersistencePreferences.get().preferredSaveTarget
  )
  let teaserStyleRequestRef: React.ref<SidebarActionsSupport.teaserRequest> = React.useRef(
    (SidebarActionsSupport.defaultTeaserRequest(): SidebarActionsSupport.teaserRequest),
  )
  let initialPublishOptions = SidebarActionsSupport.resetPublishOptions()
  let publishOptionsRef: React.ref<SidebarBase.SidebarTypes.publishOptions> = React.useRef(
    initialPublishOptions,
  )

  let saveAbortRef = React.useRef(None)
  let saveTargetRef = React.useRef(preferredSaveTarget)
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
      await onSave(~mode=saveTargetRef.current, ~signal, ~onCancel)
      saveAbortRef.current = None
    },
  )

  React.useEffect1(() => {
    saveTargetRef.current = preferredSaveTarget
    None
  }, [preferredSaveTarget])

  let runSaveForTarget = target => {
    setPreferredSaveTarget(_ => target)
    saveTargetRef.current = target
    PersistencePreferences.setPreferredSaveTarget(target)->ignore
    let _ = saveExecute()
  }

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
      await onExport(~options=publishOptionsRef.current, ~signal, ~onCancel)
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
      await onTeaser(
        ~format=teaserStyleRequestRef.current.format,
        ~styleId=teaserStyleRequestRef.current.styleId,
        ~panSpeedId=teaserStyleRequestRef.current.panSpeedId,
        ~signal,
        ~onCancel,
      )
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
        className="sidebar-action-btn-square hover-lift active-push group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/50 disabled:opacity-50 disabled:cursor-not-allowed"
        onClick={_ => {
          EventBus.dispatch(
            ShowModal(
              SidebarActionsSupport.saveModalConfig(~preferredSaveTarget, ~runSaveForTarget),
            ),
          )
        }}
        disabled={!isPermitted || savePending}
        ariaLabel={SidebarActionsSupport.saveTargetLabel(preferredSaveTarget)}
        title={SidebarActionsSupport.saveTargetLabel(preferredSaveTarget)}
      >
        <LucideIcons.Save size=20 strokeWidth=1.0 />
        <span> {React.string("Save")} </span>
      </button>

      <button
        className="sidebar-action-btn-square hover-lift active-push group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/50 disabled:opacity-50 disabled:cursor-not-allowed"
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
        onClick={_ => onSettings()}
        disabled={!isPermitted}
        ariaLabel="Settings"
      >
        <LucideIcons.Settings size=20 strokeWidth=1.0 />
        <span> {React.string("Settings")} </span>
      </button>
    </div>

    <div className="grid grid-cols-2 gap-2">
      <button
        className="sidebar-action-btn-wide hover-lift active-push group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/50 disabled:opacity-50 disabled:cursor-not-allowed"
        disabled={!exportReady || !isPermitted || exportPending}
        onMouseEnter={_ => {
          ChunkPrefetch.warmExporter()
          ChunkPrefetch.warmExif()
        }}
        onClick={_ => {
          let nextOptions = SidebarActionsSupport.resetPublishOptions()
          publishOptionsRef.current = nextOptions
          EventBus.dispatch(
            ShowModal(
              SidebarActionsSupport.publishModalConfig(
                ~onOptionsChanged={opts => publishOptionsRef.current = opts},
                ~onPublish={
                  () => {
                    let _ = exportExecute()
                  }
                },
              ),
            ),
          )
        }}
        ariaLabel="Publish Tour"
      >
        <LucideIcons.Download
          className="text-white transition-all duration-300" size=20 strokeWidth=1.0
        />
        <span> {React.string("Publish")} </span>
      </button>

      <button
        className="sidebar-action-btn-wide hover-lift active-push group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/50 disabled:opacity-50 disabled:cursor-not-allowed"
        disabled={!teaserReady || !isPermitted || isLinking || teaserPending}
        onMouseEnter={_ => {
          ChunkPrefetch.warmTeaser()
        }}
        onClick={_ => {
          EventBus.dispatch(
            ShowModal(
              SidebarActionsSupport.teaserModalConfig(~teaserStyleRequestRef, ~onSelect=() => {
                let _ = teaserExecute()
              }),
            ),
          )
        }}
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
