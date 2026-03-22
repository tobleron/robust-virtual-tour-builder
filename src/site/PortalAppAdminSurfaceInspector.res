// @efficiency-role: ui-component
open PortalAppCore
open PortalAppUI
open ReBindings

type props = {
  data: adminData,
  selectedOverview: option<PortalTypes.customerOverview>,
  customerDrafts: Belt.Map.String.t<customerDraft>,
  expiryDrafts: Belt.Map.String.t<string>,
  lastGeneratedLinks: Belt.Map.String.t<string>,
  updateCustomerDraft: (string, customerDraft => customerDraft) => unit,
  updateExpiryDraft: (string, string) => unit,
  onUpdateCustomer: (string, customerDraft) => promise<unit>,
  onGenerateLink: (string, string) => promise<unit>,
  onRevokeLink: string => promise<unit>,
  onDeleteAccessLinks: string => promise<unit>,
  onDeleteCustomer: string => promise<unit>,
  onAssignToggle: (~customerId: string, ~tourId: string, ~assigned: bool) => promise<unit>,
  setFlash: (flash => flash) => unit,
}

let make = (~props: props) =>
  switch props.selectedOverview {
  | None =>
    <article className="portal-card portal-empty-state">
      <h2> {React.string("No recipient selected")} </h2>
      <p className="portal-card-muted">
        {React.string(
          "Select a recipient from the directory to manage links, status, and assignments.",
        )}
      </p>
    </article>
  | Some(customerOverview) =>
    let customerId = customerOverview.customer.id
    let customerDraft =
      props.customerDrafts
      ->Belt.Map.String.get(customerId)
      ->Option.getOr(customerDraftFromOverview(customerOverview))
    let expiryDraft =
      props.expiryDrafts
      ->Belt.Map.String.get(customerId)
      ->Option.getOr(
        customerOverview.accessLink
        ->Option.map(link => isoToLocalDateTime(link.expiresAt))
        ->Option.getOr(nowPlusDaysIsoLocal(30)),
      )
    let lastLink = props.lastGeneratedLinks->Belt.Map.String.get(customerId)
    let activeAccessUrl =
      lastLink->Option.orElse(customerOverview.accessLink->Option.flatMap(link => link.accessUrl))
    let galleryExpiryLabel = if expiryDraft == "" {
      "Set an expiry before sharing."
    } else {
      "Expires " ++ expiryDraft
    }
    <article className="portal-card portal-recipient-detail-card">
      <div className="portal-section-head">
        <div>
          <h2> {React.string("Recipient detail")} </h2>
          <p className="portal-card-muted"> {React.string("Recipient ID: " ++ customerId)} </p>
        </div>
        <div className="portal-chip-row">
          <span className={"portal-chip " ++ (customerDraft.isActive ? "is-active" : "is-expired")}>
            {React.string(
              if customerDraft.isActive {
                "Active"
              } else {
                "Inactive"
              },
            )}
          </span>
          <span className="portal-chip portal-chip-subtle">
            {React.string(customerDraft.recipientType->recipientTypeLabel)}
          </span>
          <span className="portal-chip">
            {React.string(Belt.Int.toString(customerOverview.tourCount) ++ " tours")}
          </span>
        </div>
      </div>
      <div className="portal-detail-grid">
        <div className="portal-detail-card">
          <div className="portal-form-grid">
            <label>
              {React.string("Display name")}
              <input
                value=customerDraft.displayName
                onChange={e =>
                  props.updateCustomerDraft(customerId, draft => {
                    ...draft,
                    displayName: ReactEvent.Form.target(e)["value"],
                  })}
              />
            </label>
            <label>
              {React.string("Recipient type")}
              <select
                value={customerDraft.recipientType->recipientTypeValue}
                onChange={e =>
                  props.updateCustomerDraft(customerId, draft => {
                    ...draft,
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
              {React.string("Slug")}
              <input readOnly=true value={customerOverview.customer.slug} />
            </label>
            <label>
              {React.string("Access expiry")}
              <input
                type_="datetime-local"
                value=expiryDraft
                onChange={e =>
                  props.updateExpiryDraft(customerId, ReactEvent.Form.target(e)["value"])}
              />
            </label>
            <label className="portal-toggle-field">
              <span> {React.string("Recipient status")} </span>
              <span className="portal-toggle-control">
                <input
                  type_="checkbox"
                  checked=customerDraft.isActive
                  onChange={_ =>
                    props.updateCustomerDraft(customerId, draft => {
                      ...draft,
                      isActive: !draft.isActive,
                    })}
                />
                <strong>
                  {React.string(
                    if customerDraft.isActive {
                      "Recipient active"
                    } else {
                      "Recipient inactive"
                    },
                  )}
                </strong>
              </span>
            </label>
          </div>
          <div className="portal-inline-actions portal-inline-actions-compact">
            <button
              className="site-btn site-btn-ghost portal-compact-btn"
              onClick={_ => ignore(props.onUpdateCustomer(customerId, customerDraft))}
            >
              {actionLabel(~icon=SaveIcon, ~label="Save")}
            </button>
            <button
              className="site-btn site-btn-primary portal-compact-btn"
              onClick={_ => ignore(props.onGenerateLink(customerId, expiryDraft))}
            >
              {actionLabel(~icon=LinkIcon, ~label="Generate")}
            </button>
            <button
              className="site-btn site-btn-ghost portal-compact-btn"
              onClick={_ => ignore(props.onRevokeLink(customerId))}
            >
              {actionLabel(~icon=RevokeIcon, ~label="Revoke")}
            </button>
          </div>
        </div>
        <div className="portal-detail-card portal-detail-card-danger">
          <span className="portal-link-label"> {React.string("Danger zone")} </span>
          <p className="portal-card-muted">
            {React.string(
              "Remove links or recipients only when cleaning invalid data or test records.",
            )}
          </p>
          <div className="portal-inline-actions portal-inline-actions-compact">
            <button
              className="site-btn site-btn-ghost portal-compact-btn is-destructive"
              onClick={_ => ignore(props.onDeleteAccessLinks(customerId))}
            >
              {actionLabel(~icon=DeleteIcon, ~label="Delete link")}
            </button>
            <button
              className="site-btn site-btn-ghost portal-compact-btn is-destructive"
              onClick={_ => ignore(props.onDeleteCustomer(customerId))}
            >
              {actionLabel(~icon=DeleteIcon, ~label="Delete recipient")}
            </button>
          </div>
        </div>
      </div>
      <div className="portal-section-head portal-section-head-tight">
        <div>
          <h3> {React.string("Access delivery")} </h3>
          <p className="portal-card-muted">
            {React.string(
              "Share the gallery with the client, or use direct broker links for assigned tours.",
            )}
          </p>
        </div>
      </div>
      {switch activeAccessUrl {
      | Some(url) =>
        <div className="portal-link-panel">
          <div className="portal-link-card">
            <div className="portal-link-copy">
              <span className="portal-link-label"> {React.string("Gallery access")} </span>
              <a className="portal-link-anchor" href={url} target="_blank" rel="noreferrer">
                {React.string("Open secure gallery")}
              </a>
              <span className="portal-link-meta"> {React.string(galleryExpiryLabel)} </span>
              <span className="portal-link-value">
                {React.string(
                  "Copy to share the private gallery URL, or open it to verify the experience first.",
                )}
              </span>
            </div>
            <div className="portal-inline-actions portal-inline-actions-compact">
              <CopyActionButton
                className="site-btn site-btn-ghost portal-compact-btn portal-copy-btn"
                url
                label="Copy"
                copiedLabel="Copied"
                ariaLabel="Copy gallery link"
                title="Copy gallery link"
                onCopyError={message => props.setFlash(_ => {error: Some(message), success: None})}
              />
              <button
                className="site-btn site-btn-ghost portal-compact-btn"
                onClick={_ => Window.openWindow(url, "_blank")}
              >
                {actionLabel(~icon=OpenIcon, ~label="Open")}
              </button>
            </div>
          </div>
        </div>
      | None =>
        <div className="portal-empty-inline">
          {React.string("Generate an access link to start sharing this recipient gallery.")}
        </div>
      }}
      <div className="portal-section-head">
        <div>
          <h3> {React.string("Tour assignments")} </h3>
          <p className="portal-card-muted">
            {React.string(
              "Assign tours here, then use copy/open actions once a gallery link is active.",
            )}
          </p>
        </div>
      </div>
      <div className="portal-table-scroll">
        <div className="portal-assignment-table">
          <div className="portal-table-head portal-assignment-table-head">
            <span> {React.string("Tour")} </span>
            <span> {React.string("Status")} </span>
            <span> {React.string("Direct link")} </span>
            <span> {React.string("Action")} </span>
          </div>
          {props.data.tours
          ->Belt.Array.map(tourOverview => {
            let assigned =
              customerOverview.assignedTourIds->Belt.Array.some(id => id == tourOverview.tour.id)
            <div key={tourOverview.tour.id} className="portal-assignment-row">
              <span className="portal-table-cell portal-table-cell-primary">
                {mobileLabel("Tour")}
                <span className="portal-row-primary">
                  <strong> {React.string(tourOverview.tour.title)} </strong>
                  <small> {React.string("ID: " ++ tourOverview.tour.id)} </small>
                </span>
              </span>
              <span className="portal-table-cell">
                {mobileLabel("Status")}
                <span
                  className={"portal-chip " ++ (
                    tourOverview.tour.status == "published" ? "is-published" : ""
                  )}
                >
                  {React.string(tourOverview.tour.status)}
                </span>
              </span>
              <span className="portal-table-cell">
                {mobileLabel("Direct link")}
                {switch activeAccessUrl {
                | Some(accessUrl) if assigned => {
                    let directUrl = directTourAccessUrl(
                      ~accessUrl,
                      ~tourSlug=tourOverview.tour.slug,
                    )
                    <div className="portal-link-summary">
                      <a
                        className="portal-link-anchor is-inline"
                        href={directUrl}
                        target="_blank"
                        rel="noreferrer"
                      >
                        {React.string("Open direct access link")}
                      </a>
                      <small className="portal-row-muted">
                        {React.string(
                          "Bypasses the gallery and opens this assigned tour immediately.",
                        )}
                      </small>
                      <div className="portal-inline-actions portal-inline-actions-compact">
                        <CopyActionButton
                          className="site-btn site-btn-ghost portal-compact-btn portal-copy-btn"
                          url={directUrl}
                          label="Copy"
                          copiedLabel="Copied"
                          ariaLabel={"Copy direct tour link for " ++ tourOverview.tour.title}
                          title={"Copy direct tour link for " ++ tourOverview.tour.title}
                          onCopyError={message =>
                            props.setFlash(_ => {error: Some(message), success: None})}
                        />
                        <button
                          className="site-btn site-btn-ghost portal-compact-btn"
                          onClick={_ => Window.openWindow(directUrl, "_blank")}
                        >
                          {actionLabel(~icon=OpenIcon, ~label="Open")}
                        </button>
                      </div>
                    </div>
                  }
                | _ =>
                  <span className="portal-row-muted">
                    {React.string(
                      if assigned {
                        "Generate link first"
                      } else {
                        "Assign to enable"
                      },
                    )}
                  </span>
                }}
              </span>
              <span className="portal-table-cell portal-table-cell-action">
                {mobileLabel("Action")}
                <div className="portal-table-action-cluster">
                  <button
                    className={"site-btn site-btn-ghost portal-compact-btn " ++ (
                      assigned ? "is-active-state" : ""
                    )}
                    onClick={_ =>
                      ignore(
                        props.onAssignToggle(~customerId, ~tourId=tourOverview.tour.id, ~assigned),
                      )}
                  >
                    {actionLabel(
                      ~icon=assigned ? RevokeIcon : AddIcon,
                      ~label=assigned ? "Remove" : "Assign",
                    )}
                  </button>
                </div>
              </span>
            </div>
          })
          ->React.array}
        </div>
      </div>
    </article>
  }
