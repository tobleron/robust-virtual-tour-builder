type tab =
  | Marketing
  | Persistence
  | Viewer
  | About
  | SystemHealth

@react.component
let make = () => {
  let state = AppContext.useAppState()
  let dispatch = AppContext.useAppDispatch()
  let (activeTab, setActiveTab) = React.useState(_ => Marketing)
  let initialPrefs = PersistencePreferences.get()
  let (comment, setComment) = React.useState(_ => state.marketingComment)
  let (phone1, setPhone1) = React.useState(_ => state.marketingPhone1)
  let (phone2, setPhone2) = React.useState(_ => state.marketingPhone2)
  let (forRent, setForRent) = React.useState(_ => state.marketingForRent)
  let (forSale, setForSale) = React.useState(_ => state.marketingForSale)
  let (tripodDeadZoneEnabled, setTripodDeadZoneEnabled) =
    React.useState(_ => state.tripodDeadZoneEnabled)
  let (autosaveMode, setAutosaveMode) = React.useState(_ => initialPrefs.autosaveMode)
  let (snapshotCadence, setSnapshotCadence) = React.useState(_ => initialPrefs.snapshotCadence)

  let preview = MarketingText.compose(~comment, ~phone1, ~phone2, ~forRent, ~forSale)
  let charCount = preview.full->String.length
  let overLimit = charCount > MarketingText.maxLen

  let tabClass = (isActive: bool) =>
    "w-full text-left rounded-md px-3 py-2 text-[12px] font-semibold tracking-wide transition-all " ++ if (
      isActive
    ) {
      "bg-white/20 text-white border border-white/20"
    } else {
      "bg-white/5 text-white/70 border border-transparent hover:bg-white/10 hover:text-white"
    }

  let onCancel = () => EventBus.dispatch(CloseModal)
  let onSave = () => {
    switch activeTab {
    | Marketing if !overLimit =>
      dispatch(Actions.SetMarketingSettings(comment, phone1, phone2, forRent, forSale))
      EventBus.dispatch(CloseModal)
    | Persistence =>
      PersistencePreferences.setAutosave(~autosaveMode, ~snapshotCadence)->ignore
      EventBus.dispatch(CloseModal)
    | Viewer =>
      dispatch(Actions.SetTripodDeadZoneEnabled(tripodDeadZoneEnabled))
      EventBus.dispatch(CloseModal)
    | _ => ()
    }
  }

  <div className="settings-modal-layout">
    <div className="settings-modal-tabs">
      <button
        className={tabClass(activeTab == Marketing)} onClick={_ => setActiveTab(_ => Marketing)}
      >
        {React.string("Marketing")}
      </button>
      <button
        className={tabClass(activeTab == Persistence)} onClick={_ => setActiveTab(_ => Persistence)}
      >
        {React.string("Persistence")}
      </button>
      <button className={tabClass(activeTab == Viewer)} onClick={_ => setActiveTab(_ => Viewer)}>
        {React.string("Viewer")}
      </button>
      <button className={tabClass(activeTab == About)} onClick={_ => setActiveTab(_ => About)}>
        {React.string("About")}
      </button>
      <button
        className={tabClass(activeTab == SystemHealth)}
        onClick={_ => setActiveTab(_ => SystemHealth)}
      >
        {React.string("System")}
      </button>
    </div>

    <div className="settings-modal-content">
      {switch activeTab {
      | Marketing =>
        <div className="w-full h-full flex flex-col gap-3">
          <label className="settings-field-label"> {React.string("Comment")} </label>
          <textarea
            className="settings-field-input settings-field-textarea"
            value={comment}
            placeholder="Enter marketing comment..."
            onChange={e => setComment(_ => ReactEvent.Form.target(e)["value"])}
          />

          <label className="settings-field-label"> {React.string("Phone Number 1")} </label>
          <input
            className="settings-field-input"
            value={phone1}
            placeholder="+1 ..."
            onChange={e => setPhone1(_ => ReactEvent.Form.target(e)["value"])}
          />

          <label className="settings-field-label"> {React.string("Phone Number 2")} </label>
          <input
            className="settings-field-input"
            value={phone2}
            placeholder="+1 ..."
            onChange={e => setPhone2(_ => ReactEvent.Form.target(e)["value"])}
          />

          <div className="flex items-center gap-5 mt-1">
            <label className="settings-check-label">
              <input type_="checkbox" checked={forRent} onChange={_ => setForRent(prev => !prev)} />
              <span> {React.string("For Rent")} </span>
            </label>
            <label className="settings-check-label">
              <input type_="checkbox" checked={forSale} onChange={_ => setForSale(prev => !prev)} />
              <span> {React.string("For Sale")} </span>
            </label>
          </div>

          <div className="settings-preview-wrap">
            <div className="settings-preview-header">
              <span className="settings-field-label">
                {React.string("Bottom Banner Preview")}
              </span>
              <span
                className={`text-[11px] font-semibold ${overLimit
                    ? "text-red-300"
                    : "text-white/75"}`}
              >
                {React.string(
                  Belt.Int.toString(charCount) ++ "/" ++ Belt.Int.toString(MarketingText.maxLen),
                )}
              </span>
            </div>
            <div className="settings-preview-banner">
              <span className="settings-preview-text">
                {React.string(preview.full == "" ? "No marketing text saved." : preview.full)}
              </span>
            </div>
          </div>
        </div>
      | Persistence =>
        <div className="w-full h-full flex flex-col gap-4">
          <div className="flex flex-col gap-2">
            <label className="settings-field-label"> {React.string("Autosave Mode")} </label>
            <div className="grid grid-cols-1 gap-2">
              <button
                className={tabClass(autosaveMode == PersistencePreferences.Off)}
                onClick={_ => setAutosaveMode(_ => PersistencePreferences.Off)}
              >
                {React.string("Off")}
              </button>
              <button
                className={tabClass(autosaveMode == PersistencePreferences.LocalOnly)}
                onClick={_ => setAutosaveMode(_ => PersistencePreferences.LocalOnly)}
              >
                {React.string("Local Only")}
              </button>
              <button
                className={tabClass(autosaveMode == PersistencePreferences.Hybrid)}
                onClick={_ => setAutosaveMode(_ => PersistencePreferences.Hybrid)}
              >
                {React.string("Hybrid (local + server)")}
              </button>
            </div>
          </div>

          <div className="flex flex-col gap-2">
            <label className="settings-field-label"> {React.string("Snapshot Cadence")} </label>
            <div className="grid grid-cols-1 gap-2">
              <button
                className={tabClass(snapshotCadence == PersistencePreferences.Conservative)}
                onClick={_ => setSnapshotCadence(_ => PersistencePreferences.Conservative)}
              >
                {React.string("Conservative")}
              </button>
              <button
                className={tabClass(snapshotCadence == PersistencePreferences.Balanced)}
                onClick={_ => setSnapshotCadence(_ => PersistencePreferences.Balanced)}
              >
                {React.string("Balanced")}
              </button>
              <button
                className={tabClass(snapshotCadence == PersistencePreferences.Frequent)}
                onClick={_ => setSnapshotCadence(_ => PersistencePreferences.Frequent)}
              >
                {React.string("Frequent")}
              </button>
            </div>
          </div>

          <div className="settings-preview-wrap">
            <div className="settings-preview-header">
              <span className="settings-field-label"> {React.string("Behavior")} </span>
            </div>
            <div className="settings-preview-banner">
              <span className="settings-preview-text">
                {React.string(
                  switch autosaveMode {
                  | PersistencePreferences.Off => "Autosave disabled. Use the Save menu to persist your work."
                  | PersistencePreferences.LocalOnly => "Autosave writes only to this browser for recovery. Server history is manual."
                  | PersistencePreferences.Hybrid => "Autosave writes locally and creates server snapshots when online and signed in."
                  },
                )}
              </span>
            </div>
          </div>
        </div>
      | Viewer =>
        <div className="w-full h-full flex flex-col gap-4">
          <div className="flex flex-col gap-2">
            <label className="settings-field-label"> {React.string("Tripod Dead-Zone")} </label>
            <label className="settings-check-label">
              <input
                type_="checkbox"
                checked={tripodDeadZoneEnabled}
                onChange={_ => setTripodDeadZoneEnabled(prev => !prev)}
              />
              <span> {React.string("Enable for builder and exported tours")} </span>
            </label>
          </div>

          <div className="settings-preview-wrap">
            <div className="settings-preview-header">
              <span className="settings-field-label"> {React.string("Behavior")} </span>
            </div>
            <div className="settings-preview-banner">
              <span className="settings-preview-text">
                {React.string(
                  tripodDeadZoneEnabled
                    ? "Builder and exported tours will clamp the camera to a tripod-safe floor."
                    : "Builder and exported tours will allow the full pitch range.",
                )}
              </span>
            </div>
          </div>
        </div>
      | About => <SidebarAbout />
      | SystemHealth => <SidebarSystemHealth />
      }}

      <div className="settings-actions">
        <button className="modal-btn-premium modal-btn-full" onClick={_ => onCancel()}>
          <span> {React.string("Cancel")} </span>
        </button>
        {switch activeTab {
        | Marketing =>
          <button
            className="modal-btn-premium modal-btn-full bg-white/20 disabled:opacity-50 disabled:cursor-not-allowed"
            disabled={overLimit}
            onClick={_ => onSave()}
          >
            <span> {React.string("Save")} </span>
          </button>
        | Persistence =>
          <button className="modal-btn-premium modal-btn-full bg-white/20" onClick={_ => onSave()}>
            <span> {React.string("Save")} </span>
          </button>
        | Viewer =>
          <button className="modal-btn-premium modal-btn-full bg-white/20" onClick={_ => onSave()}>
            <span> {React.string("Save")} </span>
          </button>
        | About | SystemHealth => React.null
        }}
      </div>
    </div>
  </div>
}
