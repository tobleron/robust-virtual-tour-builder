// @efficiency-role: ui-component
open PortalAppCore

type props = {
  assignmentMode: assignmentMode,
  data: adminData,
  selectedBulkCustomerIds: Belt.Set.String.t,
  selectedBulkTourIds: Belt.Set.String.t,
  setSelectedBulkCustomerIds: (Belt.Set.String.t => Belt.Set.String.t) => unit,
  setSelectedBulkTourIds: (Belt.Set.String.t => Belt.Set.String.t) => unit,
  clearBulkSelections: unit => unit,
  onBulkAssign: unit => promise<unit>,
}

let make = (~props: props) =>
  switch props.assignmentMode {
  | BulkAssignMode =>
    let bulkCustomerIds = props.selectedBulkCustomerIds->Belt.Set.String.toArray
    let bulkTourIds = props.selectedBulkTourIds->Belt.Set.String.toArray
    let bulkSelectionCount = bulkCustomerIds->Belt.Array.length
    let bulkTourSelectionCount = bulkTourIds->Belt.Array.length
    let bulkRequestedAssignments = bulkSelectionCount * bulkTourSelectionCount
    let selectedBulkRecipients =
      props.data.customers->Belt.Array.keep(overview =>
        props.selectedBulkCustomerIds->Belt.Set.String.has(overview.customer.id)
      )
    let selectedBulkTours =
      props.data.tours->Belt.Array.keep(overview =>
        props.selectedBulkTourIds->Belt.Set.String.has(overview.tour.id)
      )
    <article className="portal-card portal-bulk-inspector-card">
      <div className="portal-section-head">
        <div>
          <h2> {React.string("Bulk assignment")} </h2>
          <p className="portal-card-muted">
            {React.string(
              "Select recipients on the left and tours below, then assign that full combination in one action.",
            )}
          </p>
        </div>
        <div className="portal-chip-row">
          <span className="portal-chip is-active">
            {React.string(Belt.Int.toString(bulkSelectionCount) ++ " recipients")}
          </span>
          <span className="portal-chip is-active">
            {React.string(Belt.Int.toString(bulkTourSelectionCount) ++ " tours")}
          </span>
          <span className="portal-chip">
            {React.string(Belt.Int.toString(bulkRequestedAssignments) ++ " assignments")}
          </span>
        </div>
      </div>
      <div className="portal-bulk-inspector-grid">
        <div className="portal-detail-card">
          <span className="portal-link-label"> {React.string("Recipients selected")} </span>
          {switch selectedBulkRecipients->Belt.Array.length {
          | 0 =>
            <div className="portal-empty-inline">
              {React.string(
                "Pick one or more recipients from the directory to start the assignment set.",
              )}
            </div>
          | _ =>
            <div className="portal-selection-chip-list">
              {selectedBulkRecipients
              ->Belt.Array.map(overview =>
                <span key={overview.customer.id} className="portal-selection-chip">
                  {React.string(
                    overview.customer.displayName ++
                    " · " ++
                    overview.customer.recipientType->recipientTypeLabel,
                  )}
                </span>
              )
              ->React.array}
            </div>
          }}
        </div>
        <div className="portal-detail-card">
          <span className="portal-link-label"> {React.string("Tours selected")} </span>
          {switch selectedBulkTours->Belt.Array.length {
          | 0 =>
            <div className="portal-empty-inline">
              {React.string("Pick one or more tours from the library to build the assignment set.")}
            </div>
          | _ =>
            <div className="portal-selection-chip-list">
              {selectedBulkTours
              ->Belt.Array.map(overview =>
                <span key={overview.tour.id} className="portal-selection-chip">
                  {React.string(overview.tour.title)}
                </span>
              )
              ->React.array}
            </div>
          }}
        </div>
      </div>
      <div className="portal-bulk-inspector-preview">
        <span className="portal-link-label"> {React.string("Preview")} </span>
        <p className="portal-card-muted">
          {React.string(
            "Existing assignments are left untouched and skipped automatically. Only missing links are created.",
          )}
        </p>
      </div>
      <div className="portal-bulk-bar">
        <div className="portal-bulk-bar-copy">
          <strong>
            {React.string(
              Belt.Int.toString(bulkSelectionCount) ++
              " recipients x " ++
              Belt.Int.toString(bulkTourSelectionCount) ++ " tours",
            )}
          </strong>
          <span className="portal-row-muted">
            {React.string(
              Belt.Int.toString(
                bulkRequestedAssignments,
              ) ++ " assignments will be created or skipped if they already exist.",
            )}
          </span>
        </div>
        <div className="portal-inline-actions portal-inline-actions-compact">
          <button
            className="site-btn site-btn-ghost portal-toolbar-btn"
            onClick={_ => props.setSelectedBulkCustomerIds(_ => Belt.Set.String.empty)}
          >
            {React.string("Clear recipients")}
          </button>
          <button
            className="site-btn site-btn-ghost portal-toolbar-btn"
            onClick={_ => props.setSelectedBulkTourIds(_ => Belt.Set.String.empty)}
          >
            {React.string("Clear tours")}
          </button>
          <button
            className="site-btn site-btn-ghost portal-toolbar-btn"
            onClick={_ => props.clearBulkSelections()}
          >
            {React.string("Clear all")}
          </button>
          <button
            className="site-btn site-btn-primary portal-toolbar-btn"
            disabled={bulkRequestedAssignments == 0}
            onClick={_ => ignore(props.onBulkAssign())}
          >
            {React.string("Assign selected")}
          </button>
        </div>
      </div>
    </article>
  | _ => React.null
  }
