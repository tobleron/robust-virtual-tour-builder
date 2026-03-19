// @efficiency-role: ui-component
open PortalAppCore
open ReBindings
open PortalAppUI
open PortalAppAdminSurfaceRefresh

@react.component
let make = () => {
  let (state, setState) = React.useState((): remoteData<adminData> => Loading)
  let (isRefreshing, setIsRefreshing) = React.useState(() => false)
  let (flash, setFlash) = React.useState(() => emptyFlash)
  let (selectedCustomerId, setSelectedCustomerId) = React.useState((): option<string> => None)
  let (assignmentMode, setAssignmentMode) = React.useState(() => SingleRecipientMode)
  let (activeDrawer, setActiveDrawer) = React.useState(() => NoDrawer)
  let (recipientSearch, setRecipientSearch) = React.useState(() => "")
  let (recipientFilter, setRecipientFilter) = React.useState(() => RecipientAll)
  let (recipientTypeFilter, setRecipientTypeFilter) = React.useState(() => RecipientTypeAll)
  let (recipientPage, setRecipientPage) = React.useState(() => 0)
  let (tourSearch, setTourSearch) = React.useState(() => "")
  let (tourFilter, setTourFilter) = React.useState(() => TourAll)
  let (tourPage, setTourPage) = React.useState(() => 0)
  let (selectedBulkCustomerIds, setSelectedBulkCustomerIds) = React.useState((): Belt.Set.String.t =>
    Belt.Set.String.empty
  )
  let (selectedBulkTourIds, setSelectedBulkTourIds) = React.useState((): Belt.Set.String.t =>
    Belt.Set.String.empty
  )
  let (createDraft, setCreateDraft) = React.useState(() => {
    slug: "",
    displayName: "",
    expiresAt: nowPlusDaysIsoLocal(30),
    recipientType: PortalTypes.PropertyOwner,
  })
  let (settingsEdit, setSettingsEdit) = React.useState((): option<settingsDraft> => None)
  let (uploadTitle, setUploadTitle) = React.useState(() => "")
  let (selectedUploadFile, setSelectedUploadFile) = React.useState((): option<File.t> => None)
  let (customerDrafts, setCustomerDrafts) = React.useState((): Belt.Map.String.t<customerDraft> =>
    Belt.Map.String.empty
  )
  let (expiryDrafts, setExpiryDrafts) = React.useState((): Belt.Map.String.t<string> =>
    Belt.Map.String.empty
  )
  let (lastGeneratedLinks, setLastGeneratedLinks) = React.useState((): Belt.Map.String.t<
    string,
  > => Belt.Map.String.empty)
  let (showPasswordPanel, setShowPasswordPanel) = React.useState(() => false)
  let (currentPassword, setCurrentPassword) = React.useState(() => "")
  let (nextPassword, setNextPassword) = React.useState(() => "")
  let (confirmNextPassword, setConfirmNextPassword) = React.useState(() => "")

  let loadAdmin = PortalAppAdminSurfaceRefresh.make(~props={
    setState,
    setIsRefreshing,
    setSelectedCustomerId,
    setSelectedBulkCustomerIds,
    setSelectedBulkTourIds,
    setSettingsEdit,
  })

  let actions = PortalAppAdminSurfaceActions.make(~props={
    setFlash,
    setActiveDrawer,
    setShowPasswordPanel,
    setCurrentPassword,
    setNextPassword,
    setConfirmNextPassword,
    setSelectedBulkCustomerIds,
    setSelectedBulkTourIds,
    setSettingsEdit,
    setCreateDraft,
    setUploadTitle,
    setSelectedUploadFile,
    setCustomerDrafts,
    setExpiryDrafts,
    setLastGeneratedLinks,
    loadAdmin: (~preserveReadyState: bool) => loadAdmin(~preserveReadyState),
    currentPassword,
    nextPassword,
    confirmNextPassword,
    createDraft,
    settingsEdit,
    uploadTitle,
    selectedUploadFile,
    selectedBulkCustomerIds,
    selectedBulkTourIds,
  })

  React.useEffect0(() => {
    loadAdmin(~preserveReadyState=false)
    None
  })

  let updateCustomerDraft = (customerId, updater) =>
    setCustomerDrafts(prev => {
      let current =
        prev
        ->Belt.Map.String.get(customerId)
        ->Option.getOr({
          displayName: "",
          recipientType: PortalTypes.PropertyOwner,
          isActive: true,
        })
      prev->Belt.Map.String.set(customerId, updater(current))
    })

  let updateExpiryDraft = (customerId, value) =>
    setExpiryDrafts(prev => prev->Belt.Map.String.set(customerId, value))

  let toggleBulkCustomerSelection = customerId =>
    setSelectedBulkCustomerIds(prev =>
      prev->Belt.Set.String.has(customerId)
        ? prev->Belt.Set.String.remove(customerId)
        : prev->Belt.Set.String.add(customerId)
    )

  let toggleBulkTourSelection = tourId =>
    setSelectedBulkTourIds(prev =>
      prev->Belt.Set.String.has(tourId)
        ? prev->Belt.Set.String.remove(tourId)
        : prev->Belt.Set.String.add(tourId)
    )

  let clearBulkSelections = () => {
    setSelectedBulkCustomerIds(_ => Belt.Set.String.empty)
    setSelectedBulkTourIds(_ => Belt.Set.String.empty)
  }

  let exitBulkMode = () => {
    clearBulkSelections()
    setAssignmentMode(_ => SingleRecipientMode)
  }

  switch state {
  | Loading =>
    <div className="portal-shell">
      <main className="portal-main">
        <section className="portal-hero">
          {brandLockup()}
          <h1 className="portal-title"> {React.string("Portal Administration")} </h1>
          <p className="portal-subtitle"> {React.string("Loading portal admin...")} </p>
        </section>
      </main>
    </div>
  | Failed("AUTH") => <PortalAppAdminSurfaceAuth.make flash onSignIn={actions.onAdminSignIn} />
  | Failed(message) =>
    <PortalAppAdminSurfaceAuth.make flash={...flash, error: Some(message)} onSignIn={actions.onAdminSignIn} />
  | Idle => React.null
  | Ready(data) =>
    let settingsDraft = settingsEdit->Option.getOr(draftFromSettings(data.settings))
    let selectedOverview =
      selectedCustomerId->Option.flatMap(customerId => findCustomerOverview(data.customers, customerId))
    let drawerNode =
      PortalAppAdminSurfaceDrawer.make({
        activeDrawer,
        setActiveDrawer,
        createDraft,
        setCreateDraft,
        uploadTitle,
        setUploadTitle,
        setSelectedUploadFile,
        settingsDraft,
        setSettingsEdit,
        onCreateCustomer: actions.onCreateCustomer,
        onUploadTour: actions.onUploadTour,
        onSaveSettings: actions.onSaveSettings,
      })
    <div className="portal-shell">
      {drawerNode}
      <main className="portal-main">
        {PortalAppAdminSurfaceHeader.make(~props={
          data,
          flash,
          isRefreshing,
          showPasswordPanel,
          currentPassword,
          nextPassword,
          confirmNextPassword,
          setShowPasswordPanel,
          setCurrentPassword,
          setNextPassword,
          setConfirmNextPassword,
          onChangePassword: actions.onChangePassword,
          onSignOut: actions.onSignOut,
          assignmentMode,
          setAssignmentMode,
          setActiveDrawer,
          exitBulkMode,
        })}
        <div className="portal-admin-main">
          {PortalAppAdminSurfaceLists.make({
            data,
            assignmentMode,
            selectedCustomerId,
            setSelectedCustomerId,
            selectedBulkCustomerIds,
            toggleBulkCustomerSelection,
            recipientSearch,
            setRecipientSearch,
            recipientFilter,
            setRecipientFilter,
            recipientTypeFilter,
            setRecipientTypeFilter,
            recipientPage,
            setRecipientPage,
            selectedBulkTourIds,
            toggleBulkTourSelection,
            tourSearch,
            setTourSearch,
            tourFilter,
            setTourFilter,
            tourPage,
            setTourPage,
            onTourStatus: actions.onTourStatus,
            onDeleteTour: actions.onDeleteTour,
          })}

          {PortalAppAdminSurfaceBulk.make(~props={
            assignmentMode,
            data,
            selectedBulkCustomerIds,
            selectedBulkTourIds,
            setSelectedBulkCustomerIds,
            setSelectedBulkTourIds,
            clearBulkSelections,
            onBulkAssign: actions.onBulkAssign,
          })}

          {PortalAppAdminSurfaceInspector.make(~props={
            data,
            selectedOverview,
            customerDrafts,
            expiryDrafts,
            lastGeneratedLinks,
            updateCustomerDraft,
            updateExpiryDraft,
            onUpdateCustomer: actions.onUpdateCustomer,
            onGenerateLink: actions.onGenerateLink,
            onRevokeLink: actions.onRevokeLink,
            onDeleteAccessLinks: actions.onDeleteAccessLinks,
            onDeleteCustomer: actions.onDeleteCustomer,
            onAssignToggle: actions.onAssignToggle,
            setFlash,
          })}
        </div>
      </main>
    </div>
  }
}
