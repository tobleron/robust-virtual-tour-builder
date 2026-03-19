// @efficiency-role: orchestrator
open PortalAppCore

@react.component
let make = () => {
  let route = parseRoute()

  React.useEffect1(
    () => {
      switch route {
      | Landing => setDocumentTitle(documentRef, "Robust Virtual Tour Builder | Portal")
      | AdminSignin => setDocumentTitle(documentRef, "Robust Portal | Admin Sign In")
      | AdminDashboard => setDocumentTitle(documentRef, "Robust Portal | Admin")
      | CustomerPortal(slug) | CustomerTour(slug, _) =>
        setDocumentTitle(documentRef, "Robust Portal | " ++ slug)
      }
      None
    },
    [route],
  )

  switch route {
  | Landing =>
    <div className="portal-shell">
      <main className="portal-main">
        <section className="portal-hero">
          {PortalAppUI.brandLockup()}
          <h1 className="portal-title"> {React.string("Robust Virtual Tour Builder")} </h1>
          <p className="portal-subtitle">
            {React.string(
              "Secure customer tour delivery with reusable 4K tour uploads, expiring private links, and branded presentation pages.",
            )}
          </p>
          <div className="portal-inline-actions">
            <a className="site-btn site-btn-primary" href="/portal-admin/signin">
              {React.string("Portal Admin")}
            </a>
          </div>
        </section>
      </main>
    </div>
  | AdminSignin | AdminDashboard => <PortalAppAdminSurface.make />
  | CustomerPortal(slug) => <PortalAppCustomerSurface.make slug tourSlug=None />
  | CustomerTour(slug, tourSlug) => <PortalAppCustomerSurface.make slug tourSlug=Some(tourSlug) />
  }
}
