// @efficiency-role: ui-component
open PortalAppCore
open PortalAppUI

type props = {
  data: adminData,
  assignmentMode: assignmentMode,
  selectedCustomerId: option<string>,
  setSelectedCustomerId: (option<string> => option<string>) => unit,
  selectedBulkCustomerIds: Belt.Set.String.t,
  toggleBulkCustomerSelection: string => unit,
  recipientSearch: string,
  setRecipientSearch: (string => string) => unit,
  recipientFilter: recipientStatusFilter,
  setRecipientFilter: (recipientStatusFilter => recipientStatusFilter) => unit,
  recipientTypeFilter: recipientTypeFilter,
  setRecipientTypeFilter: (recipientTypeFilter => recipientTypeFilter) => unit,
  recipientPage: int,
  setRecipientPage: (int => int) => unit,
  selectedBulkTourIds: Belt.Set.String.t,
  toggleBulkTourSelection: string => unit,
  tourSearch: string,
  setTourSearch: (string => string) => unit,
  tourFilter: tourStatusFilter,
  setTourFilter: (tourStatusFilter => tourStatusFilter) => unit,
  tourPage: int,
  setTourPage: (int => int) => unit,
  onTourStatus: (~tourId: string, ~status: string) => promise<unit>,
  onDeleteTour: (~tourId: string, ~title: string) => promise<unit>,
}

let renderRecipientRow = (~props: props, ~customerOverview: PortalTypes.customerOverview) => {
  let isSelected =
    props.selectedCustomerId
    ->Option.map(id => id == customerOverview.customer.id)
    ->Option.getOr(false)
  let isBulkSelected =
    props.selectedBulkCustomerIds->Belt.Set.String.has(customerOverview.customer.id)
  let expiryText =
    customerOverview.accessLink
    ->Option.map(link => isoToLocalDateTime(link.expiresAt))
    ->Option.getOr("Not generated")
  let lastOpenedText =
    customerOverview.accessLink
    ->Option.flatMap(link => link.lastOpenedAt)
    ->Option.map(isoToLocalDateTime)
    ->Option.getOr("Never")
  let (accessLabel, accessClass) = recipientAccessLabel(customerOverview)
  <button
    key={customerOverview.customer.id}
    className={"portal-recipient-row " ++ (
      props.assignmentMode == BulkAssignMode
        ? isBulkSelected ? "is-selected" : ""
        : isSelected
        ? "is-selected"
        : ""
    )}
    ariaLabel={(props.assignmentMode == BulkAssignMode ? "Select recipient " : "Open recipient ") ++
    customerOverview.customer.displayName}
    onClick={_ =>
      props.assignmentMode == BulkAssignMode
        ? props.toggleBulkCustomerSelection(customerOverview.customer.id)
        : props.setSelectedCustomerId(_ => Some(customerOverview.customer.id))}
  >
    <span className="portal-table-cell portal-table-cell-primary">
      {mobileLabel("Recipient")}
      <span className="portal-row-primary">
        <span className="portal-row-primary-title">
          {props.assignmentMode == BulkAssignMode
            ? <input type_="checkbox" checked={isBulkSelected} readOnly=true />
            : React.null}
          <strong> {React.string(customerOverview.customer.displayName)} </strong>
        </span>
        <span className="portal-chip-row portal-chip-row-compact">
          <span className="portal-chip portal-chip-subtle">
            {React.string(customerOverview.customer.recipientType->recipientTypeLabel)}
          </span>
          <small> {React.string(customerOverview.customer.slug)} </small>
        </span>
      </span>
    </span>
    <span className="portal-table-cell portal-table-cell-number">
      {mobileLabel("Tours")}
      <strong className="portal-row-number">
        {React.string(Belt.Int.toString(customerOverview.tourCount))}
      </strong>
    </span>
    <span className="portal-table-cell">
      {mobileLabel("Access")}
      <span className={"portal-chip " ++ accessClass}> {React.string(accessLabel)} </span>
    </span>
    <span className="portal-table-cell">
      {mobileLabel("Expiry")}
      <span className="portal-row-muted"> {React.string(expiryText)} </span>
    </span>
    <span className="portal-table-cell">
      {mobileLabel("Last opened")}
      <span className="portal-row-muted"> {React.string(lastOpenedText)} </span>
    </span>
    <span className="portal-table-cell portal-table-cell-action">
      {mobileLabel(props.assignmentMode == BulkAssignMode ? "Select" : "Open")}
      <span className="portal-table-action-chip">
        {actionLabel(
          ~icon=props.assignmentMode == BulkAssignMode
            ? isBulkSelected ? CheckIcon : AddIcon
            : DetailIcon,
          ~label=props.assignmentMode == BulkAssignMode
            ? isBulkSelected ? "Selected" : "Select"
            : "Details",
        )}
      </span>
    </span>
  </button>
}

let renderTourRow = (~props: props, ~tourOverview: PortalTypes.libraryTourOverview) => {
  let isPublished = tourOverview.tour.status == "published"
  let isDraft = tourOverview.tour.status == "draft"
  let isArchived = tourOverview.tour.status == "archived"
  let isBulkSelected = props.selectedBulkTourIds->Belt.Set.String.has(tourOverview.tour.id)
  <div key={tourOverview.tour.id} className="portal-library-row">
    <span className="portal-table-cell portal-table-cell-primary">
      {mobileLabel("Tour")}
      <span className="portal-row-primary">
        <span className="portal-row-primary-title">
          {props.assignmentMode == BulkAssignMode
            ? <input type_="checkbox" checked={isBulkSelected} readOnly=true />
            : React.null}
          <strong> {React.string(tourOverview.tour.title)} </strong>
        </span>
        <small>
          {React.string("ID: " ++ tourOverview.tour.id ++ " · " ++ tourOverview.tour.slug)}
        </small>
      </span>
    </span>
    <span className="portal-table-cell">
      {mobileLabel("Status")}
      <span className={"portal-chip " ++ (isPublished ? "is-published" : "")}>
        {React.string(tourOverview.tour.status)}
      </span>
    </span>
    <span className="portal-table-cell portal-table-cell-number">
      {mobileLabel("Assignments")}
      <strong className="portal-row-number">
        {React.string(Belt.Int.toString(tourOverview.assignmentCount))}
      </strong>
    </span>
    <span className="portal-table-cell portal-table-cell-action">
      {mobileLabel(props.assignmentMode == BulkAssignMode ? "Select" : "Actions")}
      {props.assignmentMode == BulkAssignMode
        ? <button
            className={"site-btn site-btn-ghost portal-compact-btn " ++ (
              isBulkSelected ? "is-active-state" : ""
            )}
            onClick={_ => props.toggleBulkTourSelection(tourOverview.tour.id)}
          >
            {actionLabel(
              ~icon=isBulkSelected ? CheckIcon : AddIcon,
              ~label=isBulkSelected ? "Selected" : "Select",
            )}
          </button>
        : <div className="portal-table-action-cluster">
            <button
              className={"site-btn site-btn-ghost portal-compact-btn " ++ (
                isPublished ? "is-current-status" : ""
              )}
              disabled=isPublished
              onClick={_ =>
                ignore(props.onTourStatus(~tourId=tourOverview.tour.id, ~status="published"))}
            >
              {actionLabel(~icon=PublishIcon, ~label="Pub")}
            </button>
            <button
              className={"site-btn site-btn-ghost portal-compact-btn " ++ (
                isDraft ? "is-current-status" : ""
              )}
              disabled=isDraft
              onClick={_ =>
                ignore(props.onTourStatus(~tourId=tourOverview.tour.id, ~status="draft"))}
            >
              {actionLabel(~icon=DraftIcon, ~label="Draft")}
            </button>
            <button
              className={"site-btn site-btn-ghost portal-compact-btn " ++ (
                isArchived ? "is-current-status" : ""
              )}
              disabled=isArchived
              onClick={_ =>
                ignore(props.onTourStatus(~tourId=tourOverview.tour.id, ~status="archived"))}
            >
              {actionLabel(~icon=ArchiveIcon, ~label="Arch")}
            </button>
            <button
              className="site-btn site-btn-ghost portal-compact-btn is-destructive"
              ariaLabel={"Delete tour " ++ tourOverview.tour.title}
              onClick={_ =>
                ignore(
                  props.onDeleteTour(~tourId=tourOverview.tour.id, ~title=tourOverview.tour.title),
                )}
            >
              {actionLabel(~icon=DeleteIcon, ~label="Delete")}
            </button>
          </div>}
    </span>
  </div>
}

let make = (props: props) => {
  let filteredRecipients =
    props.data.customers->Belt.Array.keep(customerOverview =>
      matchesRecipientSearch(customerOverview, props.recipientSearch) &&
      matchesRecipientFilter(customerOverview, props.recipientFilter) &&
      matchesRecipientTypeFilter(customerOverview, props.recipientTypeFilter)
    )
  let (visibleRecipients, recipientTotal, recipientHasPrev, recipientHasNext) = paginateArray(
    filteredRecipients,
    props.recipientPage,
  )
  let filteredTours =
    props.data.tours->Belt.Array.keep(tourOverview =>
      matchesTourSearch(tourOverview, props.tourSearch) &&
      matchesTourFilter(tourOverview, props.tourFilter)
    )
  let (visibleTours, tourTotal, tourHasPrev, tourHasNext) = paginateArray(
    filteredTours,
    props.tourPage,
  )
  let recipientPageCount = totalPages(recipientTotal)
  let tourPageCount = totalPages(tourTotal)

  <section className="portal-admin-dashboard">
    <article className="portal-card">
      <div className="portal-section-head">
        <div>
          <h2> {React.string("Recipient directory")} </h2>
          <p className="portal-card-muted">
            {React.string(
              "Scan status, expiry, and recent activity in one full-width workspace table.",
            )}
          </p>
        </div>
        <div className="portal-inline-actions">
          <span className="portal-chip">
            {React.string(
              "Showing " ++
              Belt.Int.toString(visibleRecipients->Belt.Array.length) ++
              " of " ++
              Belt.Int.toString(recipientTotal),
            )}
          </span>
          {props.assignmentMode == BulkAssignMode &&
            props.selectedBulkCustomerIds->Belt.Set.String.size > 0
            ? <span className="portal-chip is-active">
                {React.string(
                  Belt.Int.toString(
                    props.selectedBulkCustomerIds->Belt.Set.String.size,
                  ) ++ " selected",
                )}
              </span>
            : React.null}
        </div>
      </div>
      <div className="portal-table-scroll">
        <div className="portal-recipient-table">
          <div className="portal-table-head portal-recipient-table-head">
            <span> {React.string("Recipient")} </span>
            <span> {React.string("Tours")} </span>
            <span> {React.string("Access")} </span>
            <span> {React.string("Expiry")} </span>
            <span> {React.string("Last opened")} </span>
            <span>
              {React.string(props.assignmentMode == BulkAssignMode ? "Select" : "Open")}
            </span>
          </div>
          {switch recipientTotal {
          | 0 =>
            <div className="portal-empty-inline">
              {React.string("No recipients match the current filters.")}
            </div>
          | _ =>
            visibleRecipients
            ->Belt.Array.map(customerOverview => renderRecipientRow(~props, ~customerOverview))
            ->React.array
          }}
        </div>
      </div>
      <div className="portal-pagination">
        <button
          className="site-btn site-btn-ghost"
          disabled={!recipientHasPrev}
          onClick={_ => recipientHasPrev ? props.setRecipientPage(prev => prev - 1) : ()}
        >
          {React.string("Previous")}
        </button>
        <span className="portal-row-muted">
          {React.string(
            "Page " ++
            Belt.Int.toString(props.recipientPage + 1) ++
            " of " ++
            Belt.Int.toString(recipientPageCount),
          )}
        </span>
        <button
          className="site-btn site-btn-ghost"
          disabled={!recipientHasNext}
          onClick={_ => recipientHasNext ? props.setRecipientPage(prev => prev + 1) : ()}
        >
          {React.string("Next")}
        </button>
      </div>
    </article>

    <article className="portal-card">
      <div className="portal-section-head">
        <div>
          <h2> {React.string("Tour library")} </h2>
          <p className="portal-card-muted">
            {React.string(
              "Review publish state, assignment counts, and direct actions for each stored tour.",
            )}
          </p>
        </div>
        <div className="portal-inline-actions">
          <span className="portal-chip">
            {React.string(
              "Showing " ++
              Belt.Int.toString(visibleTours->Belt.Array.length) ++
              " of " ++
              Belt.Int.toString(tourTotal),
            )}
          </span>
        </div>
      </div>
      <div className="portal-table-scroll">
        <div className="portal-library-table">
          <div className="portal-table-head portal-library-table-head">
            <span> {React.string("Tour")} </span>
            <span> {React.string("Status")} </span>
            <span> {React.string("Assignments")} </span>
            <span>
              {React.string(props.assignmentMode == BulkAssignMode ? "Select" : "Actions")}
            </span>
          </div>
          {visibleTours
          ->Belt.Array.map(tourOverview => renderTourRow(~props, ~tourOverview))
          ->React.array}
        </div>
      </div>
      <div className="portal-pagination">
        <button
          className="site-btn site-btn-ghost"
          disabled={!tourHasPrev}
          onClick={_ => tourHasPrev ? props.setTourPage(prev => prev - 1) : ()}
        >
          {React.string("Previous")}
        </button>
        <span className="portal-row-muted">
          {React.string(
            "Page " ++
            Belt.Int.toString(props.tourPage + 1) ++
            " of " ++
            Belt.Int.toString(tourPageCount) ++
            " · " ++
            Belt.Int.toString(visibleTours->Belt.Array.length) ++ " visible",
          )}
        </span>
        <button
          className="site-btn site-btn-ghost"
          disabled={!tourHasNext}
          onClick={_ => tourHasNext ? props.setTourPage(prev => prev + 1) : ()}
        >
          {React.string("Next")}
        </button>
      </div>
    </article>
  </section>
}
