// @efficiency-role: ui-component
open PortalAppCore

@react.component
let make = (~slug, ~tourSlug: option<string>) => {
  let (publicState, setPublicState) = React.useState((): remoteData<PortalTypes.publicView> =>
    Loading
  )
  let (sessionState, setSessionState) = React.useState((): remoteData<PortalTypes.customerSession> =>
    Idle
  )
  let (galleryState, setGalleryState) = React.useState((): remoteData<PortalTypes.galleryView> =>
    Idle
  )
  let (tourDocumentState, setTourDocumentState) = React.useState((): remoteData<string> => Idle)
  let accessMessage = routeAccessMessage()

  React.useEffect2(
    () => {
      setPublicState(_ => Loading)
      setSessionState(_ => Loading)
      setGalleryState(_ => Idle)
      setTourDocumentState(_ => Idle)
      ignore(
        (
          async () => {
            switch await PortalApi.loadCustomerPublic(slug) {
            | Error(message) => setPublicState(_ => Failed(message))
            | Ok(publicView) =>
              setPublicState(_ => Ready(publicView))
              switch await PortalApi.loadCustomerSession(slug) {
              | Ok(payload) =>
                setSessionState(_ => Ready(payload.session))
                switch tourSlug {
                | Some(value) =>
                  if payload.session.canOpenTours {
                    setTourDocumentState(_ => Loading)
                    switch await loadPortalTourDocument(~slug, ~tourSlug=value) {
                    | Ok(document) => setTourDocumentState(_ => Ready(document))
                    | Error(message) => setTourDocumentState(_ => Failed(message))
                    }
                  }
                | None =>
                  setGalleryState(_ => Loading)
                  switch await PortalApi.loadCustomerTours(slug) {
                  | Ok(gallery) => setGalleryState(_ => Ready(gallery))
                  | Error(message) => setGalleryState(_ => Failed(message))
                  }
                }
              | Error(_) => setSessionState(_ => Failed("NO_SESSION"))
              }
            }
          }
        )(),
      )
      None
    },
    (
      slug,
      switch tourSlug {
      | Some(value) => value
      | None => ""
      },
    ),
  )

  let signOut = () =>
    ignore(
      (
        async () => {
          let _ = await PortalApi.signOutCustomer(slug)
          assignLocation(customerPortalPath(slug))
        }
      )(),
    )

  switch publicState {
  | Loading => PortalAppCustomerSurfaceViews.makeLoading()
  | Failed(message) => PortalAppCustomerSurfaceViews.makeError(~message)
  | Idle => React.null
  | Ready(publicView) =>
    switch sessionState {
    | Failed("NO_SESSION") => PortalAppCustomerSurfaceViews.makeGate(~publicView, ~accessMessage)
    | Failed(_) => PortalAppCustomerSurfaceViews.makeGate(~publicView, ~accessMessage)
    | Loading => PortalAppCustomerSurfaceViews.makeLoading()
    | Idle => PortalAppCustomerSurfaceViews.makeGate(~publicView, ~accessMessage)
    | Ready(session) =>
      switch tourSlug {
      | Some(_) =>
        if session.canOpenTours {
          PortalAppCustomerSurfaceViews.makeTourViewer(
            ~slug,
            ~session,
            ~tourDocumentState,
            ~onSignOut=signOut,
          )
        } else {
          PortalAppCustomerSurfaceViews.makeLocked(~session, ~slug)
        }
      | None =>
        switch galleryState {
        | Loading => PortalAppCustomerSurfaceViews.makeGalleryLoading(~customerName=session.customer.displayName)
        | Failed(message) =>
          PortalAppCustomerSurfaceViews.makeGalleryError(
            ~customerName=session.customer.displayName,
            ~message,
          )
        | Idle => PortalAppCustomerSurfaceViews.makeGate(~publicView, ~accessMessage)
        | Ready(gallery) => PortalAppCustomerSurfaceViews.makeGallery(~slug, ~gallery, ~onSignOut=signOut)
        }
      }
    }
  }
}
