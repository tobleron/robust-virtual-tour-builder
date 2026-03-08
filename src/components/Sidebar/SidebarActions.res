// @efficiency-role: ui-component

type teaserRequest = {
  format: string,
  styleId: string,
}

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
  let teaserStyleRequestRef: React.ref<teaserRequest> = React.useRef({
    format: "webm",
    styleId: TeaserStyleCatalog.toString(TeaserStyleCatalog.defaultStyle),
  })
  let initialPublishOptions: SidebarBase.SidebarTypes.publishOptions = {
    selectedProfiles: [#hd, #k2, #k4, #standalone2k],
    includeLogo: true,
    includeMarketing: true,
  }
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

  let saveTargetLabel = target =>
    switch target {
    | PersistencePreferences.Offline => "Save Offline"
    | PersistencePreferences.Server => "Save to Server"
    | PersistencePreferences.Both => "Save Both"
    }

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
            ShowModal({
              title: "Save Project",
              description: Some("Choose where this save should go. Server saves create snapshot history, offline saves create a .vt.zip package."),
              icon: Some("info"),
              content: None,
              onClose: None,
              allowClose: Some(true),
              className: Some("modal-blue modal-publish-options"),
              buttons: [
                {
                  label: "Cancel",
                  class_: "bg-slate-100/10 text-white hover:bg-white/20",
                  onClick: () => (),
                  autoClose: Some(true),
                },
                {
                  label: if preferredSaveTarget == PersistencePreferences.Server {
                    "Save to Server (Default)"
                  } else {
                    "Save to Server"
                  },
                  class_: "bg-blue-500/20 text-white hover:bg-blue-500/35",
                  onClick: () => runSaveForTarget(PersistencePreferences.Server),
                  autoClose: Some(true),
                },
                {
                  label: if preferredSaveTarget == PersistencePreferences.Offline {
                    "Save Offline (Default)"
                  } else {
                    "Save Offline (.vt.zip)"
                  },
                  class_: "bg-white/10 text-white hover:bg-white/20",
                  onClick: () => runSaveForTarget(PersistencePreferences.Offline),
                  autoClose: Some(true),
                },
                {
                  label: if preferredSaveTarget == PersistencePreferences.Both {
                    "Save Both (Default)"
                  } else {
                    "Save Both"
                  },
                  class_: "bg-emerald-500/20 text-white hover:bg-emerald-500/35",
                  onClick: () => runSaveForTarget(PersistencePreferences.Both),
                  autoClose: Some(true),
                },
              ],
            }),
          )
        }}
        disabled={!isPermitted || savePending}
        ariaLabel={saveTargetLabel(preferredSaveTarget)}
        title={saveTargetLabel(preferredSaveTarget)}
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
          let nextOptions: SidebarBase.SidebarTypes.publishOptions = {
            selectedProfiles: [#hd, #k2, #k4, #standalone2k],
            includeLogo: true,
            includeMarketing: true,
          }
          publishOptionsRef.current = nextOptions
          EventBus.dispatch(
            ShowModal({
              title: "Publish Tour",
              description: Some("Choose what will be included in the published package."),
              icon: Some("info"),
              content: Some(
                <SidebarPublishOptionsContent
                  onOptionsChanged={opts => publishOptionsRef.current = opts}
                />,
              ),
              onClose: None,
              allowClose: Some(true),
              className: Some("modal-blue modal-publish-options"),
              buttons: [
                {
                  label: "Cancel",
                  class_: "bg-slate-100/10 text-white hover:bg-white/20",
                  onClick: () => (),
                  autoClose: Some(true),
                },
                {
                  label: "Publish",
                  class_: "bg-blue-500/20 text-white hover:bg-blue-500/40",
                  onClick: () => {
                    let _ = exportExecute()
                  },
                  autoClose: Some(true),
                },
              ],
            }),
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
          let styleButtons: array<
            EventBus.button,
          > = TeaserStyleCatalog.options->Belt.Array.map(opt => {
            if opt.available {
              (
                {
                  label: opt.label ++ " (WebM)",
                  class_: "bg-blue-500/20 text-white hover:bg-blue-500/35",
                  onClick: () => {
                    teaserStyleRequestRef.current = {format: "webm", styleId: opt.id}
                    let _ = teaserExecute()
                  },
                  autoClose: Some(true),
                }: EventBus.button
              )
            } else {
              (
                {
                  label: opt.label ++ " (Soon)",
                  class_: "bg-slate-100/10 text-white/55 cursor-not-allowed",
                  onClick: () => {
                    NotificationManager.dispatch({
                      id: "",
                      importance: Info,
                      context: Operation("teaser"),
                      message: opt.label ++ " style unavailable.",
                      details: Some(opt.description),
                      action: None,
                      duration: NotificationTypes.defaultTimeoutMs(Info),
                      dismissible: true,
                      createdAt: Date.now(),
                    })
                  },
                  autoClose: Some(false),
                }: EventBus.button
              )
            }
          })

          EventBus.dispatch(
            ShowModal({
              title: "Choose Teaser Style",
              description: Some(
                "Select the teaser rendering style. Only Cinematic is currently available.",
              ),
              icon: Some("info"),
              content: None,
              onClose: None,
              allowClose: Some(true),
              className: Some("modal-blue modal-teaser-style"),
              buttons: Belt.Array.concat(
                styleButtons,
                [
                  {
                    label: "Cancel",
                    class_: "bg-slate-100/10 text-white hover:bg-white/20",
                    onClick: () => (),
                    autoClose: Some(true),
                  },
                ],
              ),
            }),
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
