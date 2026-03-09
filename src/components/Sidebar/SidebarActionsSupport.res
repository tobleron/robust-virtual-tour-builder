open SidebarBase

type teaserRequest = {
  format: string,
  styleId: string,
}

let saveTargetLabel = target =>
  switch target {
  | PersistencePreferences.Offline => "Save Offline"
  | PersistencePreferences.Server => "Save to Server"
  | PersistencePreferences.Both => "Save Both"
  }

let saveModalConfig = (
  ~preferredSaveTarget,
  ~runSaveForTarget: PersistencePreferences.saveTarget => unit,
): EventBus.modalConfig => {
  let preferredLabel = (target, activeLabel, fallbackLabel) =>
    if preferredSaveTarget == target {
      activeLabel
    } else {
      fallbackLabel
    }

  {
    title: "Save Project",
    description: Some(
      "Choose where this save should go. Server saves create snapshot history, offline saves create a .vt.zip package.",
    ),
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
        label: preferredLabel(
          PersistencePreferences.Server,
          "Save to Server (Default)",
          "Save to Server",
        ),
        class_: "bg-blue-500/20 text-white hover:bg-blue-500/35",
        onClick: () => runSaveForTarget(PersistencePreferences.Server),
        autoClose: Some(true),
      },
      {
        label: preferredLabel(
          PersistencePreferences.Offline,
          "Save Offline (Default)",
          "Save Offline (.vt.zip)",
        ),
        class_: "bg-white/10 text-white hover:bg-white/20",
        onClick: () => runSaveForTarget(PersistencePreferences.Offline),
        autoClose: Some(true),
      },
      {
        label: preferredLabel(
          PersistencePreferences.Both,
          "Save Both (Default)",
          "Save Both",
        ),
        class_: "bg-emerald-500/20 text-white hover:bg-emerald-500/35",
        onClick: () => runSaveForTarget(PersistencePreferences.Both),
        autoClose: Some(true),
      },
    ],
  }
}

let resetPublishOptions = (): SidebarTypes.publishOptions => {
  selectedProfiles: [#hd, #k2, #k4, #standalone2k],
  includeLogo: true,
  includeMarketing: true,
}

let publishModalConfig = (
  ~onOptionsChanged: SidebarTypes.publishOptions => unit,
  ~onPublish: unit => unit,
): EventBus.modalConfig => {
  title: "Publish Tour",
  description: Some("Choose what will be included in the published package."),
  icon: Some("info"),
  content: Some(<SidebarPublishOptionsContent onOptionsChanged />),
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
      onClick: onPublish,
      autoClose: Some(true),
    },
  ],
}

let teaserUnavailableButton = (opt: TeaserStyleCatalog.styleOption): EventBus.button => {
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
}

let teaserAvailableButton = (
  opt: TeaserStyleCatalog.styleOption,
  ~teaserStyleRequestRef: React.ref<teaserRequest>,
  ~onSelect: unit => unit,
): EventBus.button => {
  label: opt.label ++ " (WebM)",
  class_: "bg-blue-500/20 text-white hover:bg-blue-500/35",
  onClick: () => {
    teaserStyleRequestRef.current = {format: "webm", styleId: opt.id}
    onSelect()
  },
  autoClose: Some(true),
}

let teaserModalConfig = (
  ~teaserStyleRequestRef: React.ref<teaserRequest>,
  ~onSelect: unit => unit,
): EventBus.modalConfig => {
  let styleButtons =
    TeaserStyleCatalog.options->Belt.Array.map(opt =>
      if opt.available {
        teaserAvailableButton(opt, ~teaserStyleRequestRef, ~onSelect)
      } else {
        teaserUnavailableButton(opt)
      }
    )

  {
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
  }
}
