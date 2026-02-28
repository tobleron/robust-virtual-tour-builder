type tab =
  | Marketing
  | About

@react.component
let make = () => {
  let state = AppContext.useAppState()
  let dispatch = AppContext.useAppDispatch()
  let (activeTab, setActiveTab) = React.useState(_ => Marketing)
  let (comment, setComment) = React.useState(_ => state.marketingComment)
  let (phone1, setPhone1) = React.useState(_ => state.marketingPhone1)
  let (phone2, setPhone2) = React.useState(_ => state.marketingPhone2)
  let (forRent, setForRent) = React.useState(_ => state.marketingForRent)
  let (forSale, setForSale) = React.useState(_ => state.marketingForSale)

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
    if !overLimit {
      dispatch(Actions.SetMarketingSettings(comment, phone1, phone2, forRent, forSale))
      EventBus.dispatch(CloseModal)
    }
  }

  <div className="settings-modal-layout">
    <div className="settings-modal-tabs">
      <button
        className={tabClass(activeTab == Marketing)} onClick={_ => setActiveTab(_ => Marketing)}
      >
        {React.string("Marketing")}
      </button>
      <button className={tabClass(activeTab == About)} onClick={_ => setActiveTab(_ => About)}>
        {React.string("About")}
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
      | About => <SidebarAbout />
      }}

      <div className="settings-actions">
        <button className="modal-btn-premium modal-btn-full" onClick={_ => onCancel()}>
          <span> {React.string("Cancel")} </span>
        </button>
        <button
          className="modal-btn-premium modal-btn-full bg-white/20 disabled:opacity-50 disabled:cursor-not-allowed"
          disabled={overLimit}
          onClick={_ => onSave()}
        >
          <span> {React.string("Save")} </span>
        </button>
      </div>
    </div>
  </div>
}
