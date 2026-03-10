open SidebarBase

type teaserRequest = {
  format: string,
  styleId: string,
  panSpeedId: string,
}

let defaultTeaserRequest = (): teaserRequest => {
  format: "webm",
  styleId: TeaserStyleCatalog.toString(TeaserStyleCatalog.defaultStyle),
  panSpeedId: TeaserStyleConfig.defaultPanSpeedId,
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

module TeaserOptionsContent = {
  @react.component
  let make = (~teaserStyleRequestRef: React.ref<teaserRequest>) => {
    let initialRequest = teaserStyleRequestRef.current
    let (selectedStyleId, setSelectedStyleId) = React.useState(_ => initialRequest.styleId)
    let (selectedPanSpeedId, setSelectedPanSpeedId) = React.useState(_ => initialRequest.panSpeedId)
    let isCinematicSelected =
      selectedStyleId == TeaserStyleCatalog.toString(TeaserStyleCatalog.defaultStyle)
    let defaultSpeedMeta =
      Belt.Int.toString(Belt.Float.toInt(Constants.panningVelocity)) ++ " deg/s default"

    let selectStyle = (styleId: string) => {
      setSelectedStyleId(_ => styleId)
      teaserStyleRequestRef.current = {...teaserStyleRequestRef.current, styleId}
    }

    let selectPanSpeed = (panSpeedId: string) => {
      setSelectedPanSpeedId(_ => panSpeedId)
      teaserStyleRequestRef.current = {...teaserStyleRequestRef.current, panSpeedId}
    }

    <div className="teaser-settings-panel">
      <div className="teaser-settings-section">
        <div className="teaser-settings-section-header">
          <div className="teaser-settings-heading">
            {React.string("Style")}
          </div>
          <div className="teaser-settings-section-note">
            {React.string("Pick the teaser look")}
          </div>
        </div>
        {TeaserStyleCatalog.options
         ->Belt.Array.map(opt => {
              let isSelected = selectedStyleId == opt.id
              let cardClasses =
                if opt.available {
                  if isSelected {
                    "teaser-settings-option--selected"
                  } else {
                    ""
                  }
                } else {
                  "teaser-settings-option--unavailable"
                }

              <label
                key={opt.id}
                className={"teaser-settings-option " ++ cardClasses}
              >
                <input
                  type_="radio"
                  name="teaser-style"
                  checked={isSelected}
                  disabled={!opt.available}
                  onChange={_ => if opt.available { selectStyle(opt.id) }}
                  className="teaser-settings-radio"
                />
                <span className="teaser-settings-option-copy">
                  <span className="teaser-settings-option-topline">
                    <span className="teaser-settings-option-label">
                      {React.string(opt.label)}
                    </span>
                    {if isSelected {
                      <span className="teaser-settings-status">
                        {React.string("Selected")}
                      </span>
                    } else if opt.available {
                      React.null
                    } else {
                      <span className="teaser-settings-badge">
                        {React.string("Soon")}
                      </span>
                    }}
                  </span>
                  <span className="teaser-settings-option-description">
                    {React.string(opt.description)}
                  </span>
                </span>
              </label>
            })
         ->React.array}
      </div>

      {if isCinematicSelected {
        <React.fragment>
          <div className="teaser-settings-divider" />

          <div className="teaser-settings-section">
            <div className="teaser-settings-section-header">
              <div className="teaser-settings-heading">
                {React.string("Cinematic Pan Speed")}
              </div>
              <div className="teaser-settings-section-note">
                {React.string(defaultSpeedMeta)}
              </div>
            </div>
            <div className="teaser-speed-grid">
              {TeaserStyleConfig.panSpeedOptions
               ->Belt.Array.map(opt => {
                    let isSelected = selectedPanSpeedId == opt.id
                    let cardClasses = if isSelected {
                      "teaser-speed-option--selected"
                    } else {
                      ""
                    }
                    let speedMeta =
                      Belt.Int.toString(Belt.Float.toInt(opt.speedDegPerSec)) ++ " deg/s"

                    <label
                      key={opt.id}
                      className={"teaser-speed-option " ++ cardClasses}
                    >
                      <input
                        type_="radio"
                        name="teaser-pan-speed"
                        checked={isSelected}
                        onChange={_ => selectPanSpeed(opt.id)}
                        className="teaser-settings-radio"
                      />
                      <span className="teaser-speed-option-copy">
                        <span className="teaser-speed-option-label">
                          {React.string(opt.label)}
                        </span>
                        <span className="teaser-speed-option-meta">
                          {React.string(speedMeta)}
                        </span>
                      </span>
                    </label>
                  })
               ->React.array}
            </div>
            <div className="teaser-settings-note">
              {React.string(
                "Applies only to the Cinematic camera pan. Transitions and cuts stay deterministic.",
              )}
            </div>
          </div>
        </React.fragment>
      } else {
        <div className="teaser-settings-note">
          {React.string(
            "Pan speed calibration is available for Cinematic only. Fast Shots and Simple Crossfade keep their fixed pacing.",
          )}
        </div>
      }}
    </div>
  }
}

let teaserModalConfig = (
  ~teaserStyleRequestRef: React.ref<teaserRequest>,
  ~onSelect: unit => unit,
): EventBus.modalConfig => {
  {
    title: "Teaser Settings",
    description: Some(
      "Choose the teaser style before generation. Pan speed calibration is available for Cinematic only.",
    ),
    icon: Some("info"),
    content: Some(<TeaserOptionsContent teaserStyleRequestRef />),
    onClose: None,
    allowClose: Some(true),
    className: Some("modal-blue modal-teaser-style"),
    buttons: [
      {
        label: "Generate Teaser",
        class_: "bg-blue-500/20 text-white hover:bg-blue-500/35",
        onClick: onSelect,
        autoClose: Some(true),
      },
      {
        label: "Cancel",
        class_: "bg-slate-100/10 text-white hover:bg-white/20",
        onClick: () => (),
        autoClose: Some(true),
      },
    ],
  }
}
