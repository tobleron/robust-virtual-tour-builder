// @efficiency-role: ui-component
open PortalAppCore
open PortalAppUI

let renewalLines = (settings: PortalTypes.settings) =>
  <div className="portal-chip-row">
    {switch settings.contactEmail {
    | Some(value) => <span className="portal-chip"> {React.string("Email: " ++ value)} </span>
    | None => React.null
    }}
    {switch settings.contactPhone {
    | Some(value) => <span className="portal-chip"> {React.string("Phone: " ++ value)} </span>
    | None => React.null
    }}
    {switch settings.whatsappNumber {
    | Some(value) => <span className="portal-chip"> {React.string("WhatsApp: " ++ value)} </span>
    | None => React.null
    }}
  </div>

let makeLoading = () =>
  <div className="portal-shell">
    <main className="portal-main portal-customer-main">
      <section className="portal-hero portal-customer-hero">
        {appBrandHeader()}
        <h1 className="portal-title"> {React.string("Loading portal...")} </h1>
      </section>
    </main>
  </div>

let makeError = (~message) =>
  <div className="portal-shell">
    <main className="portal-main portal-customer-main">
      <section className="portal-hero portal-customer-hero">
        {appBrandHeader()}
        <h1 className="portal-title"> {React.string("Portal unavailable")} </h1>
        <div className="portal-message is-error"> {React.string(message)} </div>
      </section>
    </main>
  </div>

let makeGate = (~publicView: PortalTypes.publicView, ~accessMessage: option<string>) =>
  <div className="portal-shell">
    <main className="portal-main portal-customer-main">
      <section className="portal-hero portal-customer-hero">
        {appBrandHeader()}
        <h1 className="portal-title"> {React.string(publicView.customer.displayName)} </h1>
        <p className="portal-subtitle"> {React.string("Private customer gallery.")} </p>
        {switch accessMessage {
        | Some(message) => <div className="portal-message is-error"> {React.string(message)} </div>
        | None =>
          <div className="portal-message">
            {React.string("Open this portal through your private access link.")}
          </div>
        }}
      </section>
      <section className="portal-card">
        <h2> {React.string(publicView.settings.renewalHeading)} </h2>
        <p className="portal-card-muted"> {React.string(publicView.settings.renewalMessage)} </p>
        {renewalLines(publicView.settings)}
      </section>
    </main>
  </div>

let makeTourViewer = (
  ~slug: string,
  ~session: PortalTypes.customerSession,
  ~tourDocumentState: remoteData<string>,
  ~onSignOut: unit => unit,
) =>
  <div className="portal-player-shell">
    <header className="portal-player-bar">
      <div className="portal-player-brand">
        {appBrandHeader()}
        <div className="portal-player-copy">
          <strong> {React.string(session.customer.displayName)} </strong>
          <span> {React.string("Private tour viewer")} </span>
        </div>
      </div>
      <div className="portal-inline-actions">
        <a className="site-btn site-btn-ghost" href={customerPortalPath(slug)}>
          {React.string("Back to gallery")}
        </a>
        <button className="site-btn site-btn-ghost" onClick={_ => onSignOut()}>
          {React.string("Sign Out")}
        </button>
      </div>
    </header>
    {switch tourDocumentState {
    | Ready(document) =>
      <iframe
        className="portal-player-frame"
        srcDoc={document}
        title={session.customer.displayName ++ " tour"}
      />
    | Failed(message) =>
      <div className="portal-player-feedback">
        <div className="portal-message is-error"> {React.string(message)} </div>
      </div>
    | Loading | Idle =>
      <div className="portal-player-feedback">
        <div className="portal-message"> {React.string("Loading tour...")} </div>
      </div>
    }}
  </div>

let makeLocked = (~session: PortalTypes.customerSession, ~slug: string) =>
  <div className="portal-lock-screen">
    <section className="portal-lock-card">
      {appBrandHeader()}
      <h1> {React.string(session.settings.renewalHeading)} </h1>
      <p> {React.string(session.settings.renewalMessage)} </p>
      {renewalLines(session.settings)}
      <div className="portal-inline-actions">
        <a className="site-btn site-btn-primary" href={customerPortalPath(slug)}>
          {React.string("Back to gallery")}
        </a>
      </div>
    </section>
  </div>

let makeGalleryLoading = (~customerName: string) =>
  <div className="portal-shell">
    <main className="portal-main portal-customer-main">
      <section className="portal-hero portal-customer-hero">
        {appBrandHeader()}
        <h1 className="portal-title"> {React.string(customerName)} </h1>
        <p className="portal-subtitle"> {React.string("Loading tours...")} </p>
      </section>
    </main>
  </div>

let makeGalleryError = (~customerName: string, ~message: string) =>
  <div className="portal-shell">
    <main className="portal-main portal-customer-main">
      <section className="portal-hero portal-customer-hero">
        {appBrandHeader()}
        <h1 className="portal-title"> {React.string(customerName)} </h1>
        <div className="portal-message is-error"> {React.string(message)} </div>
      </section>
    </main>
  </div>

let makeGallery = (~slug: string, ~gallery: PortalTypes.galleryView, ~onSignOut: unit => unit) => {
  let totalTours = gallery.tours->Belt.Array.length
  let openableTours = gallery.tours->Belt.Array.keep(tour => tour.canOpen)->Belt.Array.length
  let expiresLabel = friendlyDateTimeLabel(gallery.accessLink.expiresAt)

  <div className="portal-shell">
    <main className="portal-main portal-customer-main">
      <section className="portal-hero portal-customer-hero">
        <div className="portal-hero-topbar">
          <div className="portal-hero-copy">
            {appBrandHeader()}
            <h1 className="portal-title"> {React.string(gallery.customer.displayName)} </h1>
            <p className="portal-subtitle"> {React.string("Private customer gallery.")} </p>
          </div>
          <div className="portal-inline-actions">
            <button className="site-btn site-btn-ghost" onClick={_ => onSignOut()}>
              {React.string("Sign Out")}
            </button>
          </div>
        </div>
        <div className="portal-customer-meta">
          <span className={"portal-chip " ++ (gallery.canOpenTours ? "is-active" : "is-expired")}>
            {React.string(
              if gallery.canOpenTours {
                "Access active"
              } else {
                "Access expired"
              },
            )}
          </span>
          <span className="portal-customer-meta-item">
            {React.string(Belt.Int.toString(totalTours) ++ " tours assigned")}
          </span>
          <span className="portal-customer-meta-item">
            {React.string(Belt.Int.toString(openableTours) ++ " ready now")}
          </span>
          <span className="portal-customer-meta-item">
            {React.string("Expires " ++ expiresLabel)}
          </span>
        </div>
      </section>
      {!gallery.canOpenTours
        ? <section className="portal-card">
            <h2> {React.string(gallery.settings.renewalHeading)} </h2>
            <p className="portal-card-muted"> {React.string(gallery.settings.renewalMessage)} </p>
            {renewalLines(gallery.settings)}
          </section>
        : React.null}
      <section className="portal-card portal-customer-gallery">
        <div className="portal-section-head portal-customer-section-head">
          <div>
            <h2> {React.string("Assigned tours")} </h2>
          </div>
          <span className="portal-row-muted">
            {React.string(Belt.Int.toString(totalTours) ++ " available")}
          </span>
        </div>
        {if totalTours == 0 {
          <div className="portal-empty-state portal-empty-inline">
            {React.string("No tours have been assigned to this gallery yet.")}
          </div>
        } else {
          <div className="portal-grid-tours">
            {gallery.tours
            ->Belt.Array.map(tour => {
              let shareUrl =
                gallery.accessLink.accessUrl->Option.map(accessUrl =>
                  directTourAccessUrl(~accessUrl, ~tourSlug=tour.slug)
                )
              <article key={tour.id} className="portal-tour-card">
                <div className="portal-tour-cover">
                  {switch tour.coverUrl {
                  | Some(url) => <img src={url} alt={tour.title ++ " cover"} />
                  | None =>
                    <div className="portal-tour-cover-fallback"> {React.string(tour.title)} </div>
                  }}
                </div>
                <div className="portal-tour-copy">
                  <div className="portal-chip-row">
                    <span
                      className={"portal-chip " ++ (
                        tour.status == "published" ? "is-published" : ""
                      )}
                    >
                      {React.string(tour.status)}
                    </span>
                    {if tour.canOpen {
                      <span className="portal-chip is-active"> {React.string("Ready")} </span>
                    } else {
                      <span className="portal-chip is-locked"> {React.string("Locked")} </span>
                    }}
                  </div>
                  <h3> {React.string(tour.title)} </h3>
                  <div className="portal-inline-actions portal-tour-actions">
                    {if tour.canOpen {
                      <a
                        className="site-btn site-btn-primary"
                        href={customerTourPath(~slug, ~tourSlug=tour.slug)}
                      >
                        {React.string("Open Tour")}
                      </a>
                    } else {
                      <button className="site-btn site-btn-ghost" disabled=true>
                        {React.string("Locked")}
                      </button>
                    }}
                    <CopyActionButton
                      className="site-btn site-btn-ghost portal-tour-share-btn portal-copy-btn"
                      url={shareUrl->Option.getOr("")}
                      ariaLabel={"Copy share link for " ++ tour.title}
                      title={"Copy share link for " ++ tour.title}
                      copiedLabel="Copied"
                      iconOnly=true
                      disabled={!tour.canOpen || shareUrl->Option.isNone}
                    />
                  </div>
                </div>
              </article>
            })
            ->React.array}
          </div>
        }}
      </section>
    </main>
  </div>
}
