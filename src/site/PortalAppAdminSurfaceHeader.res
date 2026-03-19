// @efficiency-role: ui-component
open PortalAppCore
open PortalAppUI

type props = {
  data: adminData,
  flash: flash,
  isRefreshing: bool,
  showPasswordPanel: bool,
  currentPassword: string,
  nextPassword: string,
  confirmNextPassword: string,
  setShowPasswordPanel: (bool => bool) => unit,
  setCurrentPassword: (string => string) => unit,
  setNextPassword: (string => string) => unit,
  setConfirmNextPassword: (string => string) => unit,
  onChangePassword: unit => promise<unit>,
  onSignOut: unit => promise<unit>,
  assignmentMode: assignmentMode,
  setAssignmentMode: (assignmentMode => assignmentMode) => unit,
  setActiveDrawer: (adminDrawer => adminDrawer) => unit,
  exitBulkMode: unit => unit,
}

let make = (~props: props) =>
  <section className="portal-hero">
    <div className="portal-hero-topbar">
      <div className="portal-hero-copy">
        {brandLockup()}
        <h1 className="portal-title"> {React.string("Customer Tour Portal Administration")} </h1>
        <p className="portal-subtitle">
          {React.string(
            "Manage recipients, shared tours, and expiring access links from one branded workspace.",
          )}
        </p>
      </div>
      <div className="portal-inline-actions">
        <span className="portal-chip is-active">
          {React.string(props.data.session.email->Option.getOr("portal-admin"))}
        </span>
        <button
          className="site-btn site-btn-ghost"
          onClick={_ => props.setShowPasswordPanel(isOpen => !isOpen)}
        >
          {React.string(props.showPasswordPanel ? "Close Password" : "Change Password")}
        </button>
        <button className="site-btn site-btn-ghost" onClick={_ => ignore(props.onSignOut())}>
          {React.string("Sign Out")}
        </button>
      </div>
    </div>
    <div className="portal-hero-status">
      {messageNode(~flash=props.flash)}
      {props.isRefreshing
        ? <span className="portal-chip portal-refresh-indicator"> {React.string("Updating")} </span>
        : React.null}
    </div>
    {props.showPasswordPanel
      ? <div className="portal-password-panel">
          <div className="portal-form-grid">
            <label>
              {React.string("Current Password")}
              <input
                type_="password"
                value=props.currentPassword
                onChange={e => props.setCurrentPassword(_ => ReactEvent.Form.target(e)["value"])}
              />
            </label>
            <label>
              {React.string("New Password")}
              <input
                type_="password"
                value=props.nextPassword
                onChange={e => props.setNextPassword(_ => ReactEvent.Form.target(e)["value"])}
              />
            </label>
            <label>
              {React.string("Confirm New Password")}
              <input
                type_="password"
                value=props.confirmNextPassword
                onChange={e =>
                  props.setConfirmNextPassword(_ => ReactEvent.Form.target(e)["value"])}
              />
            </label>
          </div>
          <div className="portal-form-actions">
            <button className="site-btn site-btn-primary" onClick={_ => ignore(props.onChangePassword())}>
              {React.string("Update Password")}
            </button>
          </div>
        </div>
      : React.null}
    <div className="portal-stat-grid">
      <article className="portal-stat-card">
        <span className="portal-stat-label"> {React.string("Recipients")} </span>
        <strong className="portal-stat-value">
          {React.string(Belt.Int.toString(props.data.customers->Belt.Array.length))}
        </strong>
      </article>
      <article className="portal-stat-card">
        <span className="portal-stat-label"> {React.string("Active")} </span>
        <strong className="portal-stat-value">
          {React.string(Belt.Int.toString(props.data.customers->Belt.Array.keep(customer => customer.customer.isActive)->Belt.Array.length))}
        </strong>
      </article>
      <article className="portal-stat-card">
        <span className="portal-stat-label"> {React.string("Published tours")} </span>
        <strong className="portal-stat-value">
          {React.string(Belt.Int.toString(props.data.tours->Belt.Array.keep(tour => tour.tour.status == "published")->Belt.Array.length))}
        </strong>
      </article>
      <article className="portal-stat-card">
        <span className="portal-stat-label"> {React.string("Assignments")} </span>
        <strong className="portal-stat-value">
          {React.string(
            Belt.Int.toString(props.data.tours->Belt.Array.reduce(0, (count, tour) => count + tour.assignmentCount)),
          )}
        </strong>
      </article>
    </div>
    <div className="portal-admin-dashboard">
      <article className="portal-card portal-admin-toolbar-card">
        <div className="portal-toolbar-head">
          <div>
            <h2> {React.string("Workspace tools")} </h2>
            <p className="portal-card-muted">
              {React.string(
                "Use quick actions to create recipients, upload tours, and manage renewals without leaving the directory workspace.",
              )}
            </p>
          </div>
        </div>
        <div className="portal-admin-toolbar">
          <div className="portal-toolbar-actions">
            <button
              className="site-btn site-btn-primary portal-toolbar-btn"
              onClick={_ => props.setActiveDrawer(_ => RecipientDrawer)}
            >
              {actionLabel(~icon=AddIcon, ~label="New recipient")}
            </button>
            <button
              className="site-btn site-btn-ghost portal-toolbar-btn"
              onClick={_ => props.setActiveDrawer(_ => UploadDrawer)}
            >
              {actionLabel(~icon=UploadIcon, ~label="Upload tour")}
            </button>
            <button
              className="site-btn site-btn-ghost portal-toolbar-btn"
              onClick={_ => props.setActiveDrawer(_ => SettingsDrawer)}
            >
              {actionLabel(~icon=SettingsIcon, ~label="Renewals")}
            </button>
            <button
              className={"site-btn portal-toolbar-btn " ++ (
                props.assignmentMode == BulkAssignMode ? "site-btn-primary" : "site-btn-ghost"
              )}
              onClick={_ =>
                props.assignmentMode == BulkAssignMode
                  ? props.exitBulkMode()
                  : props.setAssignmentMode(_ => BulkAssignMode)}
            >
              {actionLabel(
                ~icon=props.assignmentMode == BulkAssignMode ? RevokeIcon : AddIcon,
                ~label=props.assignmentMode == BulkAssignMode ? "Exit bulk mode" : "Bulk assign",
              )}
            </button>
          </div>
        </div>
      </article>
    </div>
  </section>
