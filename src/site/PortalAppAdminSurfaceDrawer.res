// @efficiency-role: ui-component
open PortalAppCore
open ReBindings

type props = {
  activeDrawer: adminDrawer,
  setActiveDrawer: (adminDrawer => adminDrawer) => unit,
  createDraft: createCustomerDraft,
  setCreateDraft: (createCustomerDraft => createCustomerDraft) => unit,
  uploadTitle: string,
  setUploadTitle: (string => string) => unit,
  setSelectedUploadFile: (option<File.t> => option<File.t>) => unit,
  settingsDraft: settingsDraft,
  setSettingsEdit: (option<settingsDraft> => option<settingsDraft>) => unit,
  onCreateCustomer: unit => promise<unit>,
  onUploadTour: unit => promise<unit>,
  onSaveSettings: unit => promise<unit>,
}

let make = (props: props) =>
  switch props.activeDrawer {
  | NoDrawer => React.null
  | RecipientDrawer =>
    <div className="portal-drawer-backdrop" onClick={_ => props.setActiveDrawer(_ => NoDrawer)}>
      <aside className="portal-drawer" onClick={event => ReactEvent.Mouse.stopPropagation(event)}>
        <div className="portal-drawer-head">
          <div>
            <h2> {React.string("New recipient")} </h2>
            <p className="portal-card-muted">
              {React.string("Create a private gallery link without re-uploading tours.")}
            </p>
          </div>
          <button
            className="site-btn site-btn-ghost" onClick={_ => props.setActiveDrawer(_ => NoDrawer)}
          >
            {React.string("Close")}
          </button>
        </div>
        <div className="portal-form-grid">
          <label>
            {React.string("Slug")}
            <input
              value=props.createDraft.slug
              onChange={e =>
                props.setCreateDraft(prev => {...prev, slug: ReactEvent.Form.target(e)["value"]})}
            />
          </label>
          <label>
            {React.string("Display name")}
            <input
              value=props.createDraft.displayName
              onChange={e =>
                props.setCreateDraft(prev => {
                  ...prev,
                  displayName: ReactEvent.Form.target(e)["value"],
                })}
            />
          </label>
          <label>
            {React.string("Recipient type")}
            <select
              value={props.createDraft.recipientType->recipientTypeValue}
              onChange={e =>
                props.setCreateDraft(prev => {
                  ...prev,
                  recipientType: ReactEvent.Form.target(e)["value"]->recipientTypeFromValue,
                })}
            >
              <option value="property_owner"> {React.string("Property owner")} </option>
              <option value="broker"> {React.string("Broker")} </option>
              <option value="property_owner_broker">
                {React.string("Property owner & broker")}
              </option>
            </select>
          </label>
          <label>
            {React.string("Access expiry")}
            <input
              type_="datetime-local"
              value=props.createDraft.expiresAt
              onChange={e =>
                props.setCreateDraft(prev => {
                  ...prev,
                  expiresAt: ReactEvent.Form.target(e)["value"],
                })}
            />
          </label>
        </div>
        <div className="portal-form-actions">
          <button
            className="site-btn site-btn-primary" onClick={_ => ignore(props.onCreateCustomer())}
          >
            {React.string("Create Recipient")}
          </button>
        </div>
      </aside>
    </div>
  | UploadDrawer =>
    <div className="portal-drawer-backdrop" onClick={_ => props.setActiveDrawer(_ => NoDrawer)}>
      <aside className="portal-drawer" onClick={event => ReactEvent.Mouse.stopPropagation(event)}>
        <div className="portal-drawer-head">
          <div>
            <h2> {React.string("Upload tour")} </h2>
            <p className="portal-card-muted">
              {React.string("Add one reusable web_only ZIP containing 4K and 2K tours.")}
            </p>
          </div>
          <button
            className="site-btn site-btn-ghost" onClick={_ => props.setActiveDrawer(_ => NoDrawer)}
          >
            {React.string("Close")}
          </button>
        </div>
        <div className="portal-form-grid">
          <label>
            {React.string("Tour title")}
            <input
              value=props.uploadTitle
              onChange={e => props.setUploadTitle(_ => ReactEvent.Form.target(e)["value"])}
            />
          </label>
          <label>
            {React.string("web_only ZIP")}
            <input
              type_="file"
              accept=".zip"
              onChange={e => {
                let fileOpt = switch filesFromInputTarget(ReactEvent.Form.target(e)) {
                | Some(files) => FileList.item(files, 0)
                | None => None
                }
                props.setSelectedUploadFile(_ => fileOpt)
              }}
            />
          </label>
        </div>
        <div className="portal-form-actions">
          <button className="site-btn site-btn-primary" onClick={_ => ignore(props.onUploadTour())}>
            {React.string("Upload To Library")}
          </button>
        </div>
      </aside>
    </div>
  | SettingsDrawer =>
    <div className="portal-drawer-backdrop" onClick={_ => props.setActiveDrawer(_ => NoDrawer)}>
      <aside className="portal-drawer" onClick={event => ReactEvent.Mouse.stopPropagation(event)}>
        <div className="portal-drawer-head">
          <div>
            <h2> {React.string("Renewal settings")} </h2>
            <p className="portal-card-muted">
              {React.string("This renewal message is shared by all expired links.")}
            </p>
          </div>
          <button
            className="site-btn site-btn-ghost" onClick={_ => props.setActiveDrawer(_ => NoDrawer)}
          >
            {React.string("Close")}
          </button>
        </div>
        <div className="portal-form-grid">
          <label>
            {React.string("Heading")}
            <input
              value=props.settingsDraft.renewalHeading
              onChange={e =>
                props.setSettingsEdit(_ => Some({
                  ...props.settingsDraft,
                  renewalHeading: ReactEvent.Form.target(e)["value"],
                }))}
            />
          </label>
          <label>
            {React.string("Email")}
            <input
              value=props.settingsDraft.contactEmail
              onChange={e =>
                props.setSettingsEdit(_ => Some({
                  ...props.settingsDraft,
                  contactEmail: ReactEvent.Form.target(e)["value"],
                }))}
            />
          </label>
          <label>
            {React.string("Phone")}
            <input
              value=props.settingsDraft.contactPhone
              onChange={e =>
                props.setSettingsEdit(_ => Some({
                  ...props.settingsDraft,
                  contactPhone: ReactEvent.Form.target(e)["value"],
                }))}
            />
          </label>
          <label>
            {React.string("WhatsApp")}
            <input
              value=props.settingsDraft.whatsappNumber
              onChange={e =>
                props.setSettingsEdit(_ => Some({
                  ...props.settingsDraft,
                  whatsappNumber: ReactEvent.Form.target(e)["value"],
                }))}
            />
          </label>
        </div>
        <label className="portal-form-field">
          <span> {React.string("Message")} </span>
          <textarea
            value=props.settingsDraft.renewalMessage
            onChange={e =>
              props.setSettingsEdit(_ => Some({
                ...props.settingsDraft,
                renewalMessage: ReactEvent.Form.target(e)["value"],
              }))}
          />
        </label>
        <div className="portal-form-actions">
          <button
            className="site-btn site-btn-primary" onClick={_ => ignore(props.onSaveSettings())}
          >
            {React.string("Save Renewal Settings")}
          </button>
        </div>
      </aside>
    </div>
  }
