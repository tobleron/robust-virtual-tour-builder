// @efficiency-role: ui-component
open PortalAppCore
open ReBindings

type props = {
  setFlash: (flash => flash) => unit,
  setActiveDrawer: (adminDrawer => adminDrawer) => unit,
  setShowPasswordPanel: (bool => bool) => unit,
  setCurrentPassword: (string => string) => unit,
  setNextPassword: (string => string) => unit,
  setConfirmNextPassword: (string => string) => unit,
  setSelectedBulkCustomerIds: (Belt.Set.String.t => Belt.Set.String.t) => unit,
  setSelectedBulkTourIds: (Belt.Set.String.t => Belt.Set.String.t) => unit,
  setSettingsEdit: (option<settingsDraft> => option<settingsDraft>) => unit,
  setCreateDraft: (createCustomerDraft => createCustomerDraft) => unit,
  setUploadTitle: (string => string) => unit,
  setSelectedUploadFile: (option<File.t> => option<File.t>) => unit,
  setCustomerDrafts: (Belt.Map.String.t<customerDraft> => Belt.Map.String.t<customerDraft>) => unit,
  setExpiryDrafts: (Belt.Map.String.t<string> => Belt.Map.String.t<string>) => unit,
  setLastGeneratedLinks: (Belt.Map.String.t<string> => Belt.Map.String.t<string>) => unit,
  loadAdmin: (~preserveReadyState: bool) => unit,
  currentPassword: string,
  nextPassword: string,
  confirmNextPassword: string,
  createDraft: createCustomerDraft,
  settingsEdit: option<settingsDraft>,
  uploadTitle: string,
  selectedUploadFile: option<File.t>,
  selectedBulkCustomerIds: Belt.Set.String.t,
  selectedBulkTourIds: Belt.Set.String.t,
}

type t = {
  onAdminSignIn: (string, string) => promise<unit>,
  onChangePassword: unit => promise<unit>,
  onSaveSettings: unit => promise<unit>,
  onCreateCustomer: unit => promise<unit>,
  onUpdateCustomer: (string, customerDraft) => promise<unit>,
  onGenerateLink: (string, string) => promise<unit>,
  onRevokeLink: string => promise<unit>,
  onDeleteAccessLinks: string => promise<unit>,
  onDeleteCustomer: string => promise<unit>,
  onUploadTour: unit => promise<unit>,
  onAssignToggle: (~customerId: string, ~tourId: string, ~assigned: bool) => promise<unit>,
  onBulkAssign: unit => promise<unit>,
  onTourStatus: (~tourId: string, ~status: string) => promise<unit>,
  onDeleteTour: (~tourId: string, ~title: string) => promise<unit>,
  onSignOut: unit => promise<unit>,
}

let make = (~props: props) => {
  let passwordChangeError = (currentPassword, nextPassword, confirmNextPassword) =>
    if currentPassword->String.trim == "" || nextPassword->String.trim == "" {
      Some("Current password and new password are required.")
    } else if nextPassword != confirmNextPassword {
      Some("New password confirmation does not match.")
    } else {
      None
    }

  let reportPasswordChangeError = message =>
    props.setFlash(_ => {
      success: None,
      error: Some(message),
    })

  let resetPasswordForm = () => {
    props.setCurrentPassword(_ => "")
    props.setNextPassword(_ => "")
    props.setConfirmNextPassword(_ => "")
    props.setShowPasswordPanel(_ => false)
  }

  let submitPasswordChange = async () => {
    switch await PortalApi.changeAdminPassword(
      ~currentPassword=props.currentPassword,
      ~newPassword=props.nextPassword,
    ) {
    | Ok() =>
      resetPasswordForm()
      props.setFlash(_ => {
        success: Some("Password updated successfully."),
        error: None,
      })
    | Error(message) =>
      props.setFlash(_ => {
        success: None,
        error: Some(message),
      })
    }
  }

  let createCustomerPayload = () => {
    slug: props.createDraft.slug->String.trim,
    displayName: props.createDraft.displayName->String.trim,
    expiresAt: localDateTimeToIso(props.createDraft.expiresAt),
    recipientType: props.createDraft.recipientType,
  }

  let settingsPayloadFromDraft = (draft: settingsDraft): PortalTypes.settings => {
    renewalHeading: draft.renewalHeading,
    renewalMessage: draft.renewalMessage,
    contactEmail: draft.contactEmail->String.trim == "" ? None : Some(draft.contactEmail),
    contactPhone: draft.contactPhone->String.trim == "" ? None : Some(draft.contactPhone),
    whatsappNumber: draft.whatsappNumber->String.trim == "" ? None : Some(draft.whatsappNumber),
  }

  let resetCreateCustomerForm = () => {
    props.setCreateDraft(_ => {
      slug: "",
      displayName: "",
      expiresAt: nowPlusDaysIsoLocal(30),
      recipientType: PortalTypes.PropertyOwner,
    })
  }

  let finishCreateCustomer = (result: PortalTypes.customerCreateResult) => {
    props.setLastGeneratedLinks(prev =>
      prev->Belt.Map.String.set(result.overview.customer.id, result.accessLink.accessUrl)
    )
    resetCreateCustomerForm()
    props.setActiveDrawer(_ => NoDrawer)
    props.setFlash(_ => {error: None, success: Some("Customer created and access link generated.")})
    props.loadAdmin(~preserveReadyState=true)
  }

  let removeGeneratedLink = customerId => {
    props.setLastGeneratedLinks(prev => prev->Belt.Map.String.remove(customerId))
  }

  let finishSettingsSave = settings => {
    props.setSettingsEdit(_ => Some(draftFromSettings(settings)))
    props.setActiveDrawer(_ => NoDrawer)
    props.setFlash(_ => {error: None, success: Some("Renewal settings updated.")})
    props.loadAdmin(~preserveReadyState=true)
  }

  let submitSettingsSave = async draft => {
    switch await PortalApi.updateSettings(~settings=settingsPayloadFromDraft(draft)) {
    | Ok(settings) => finishSettingsSave(settings)
    | Error(message) => props.setFlash(_ => {error: Some(message), success: None})
    }
  }

  let onAdminSignIn = async (email, password) => {
    switch await PortalApi.signInAdmin(~email, ~password) {
    | Ok() =>
      props.setFlash(_ => {error: None, success: Some("Signed in.")})
      props.loadAdmin(~preserveReadyState=false)
    | Error(message) => props.setFlash(_ => {error: Some(message), success: None})
    }
  }

  let onChangePassword = async () => {
    switch passwordChangeError(
      props.currentPassword,
      props.nextPassword,
      props.confirmNextPassword,
    ) {
    | Some(message) => reportPasswordChangeError(message)
    | None => await submitPasswordChange()
    }
  }

  let onSaveSettings = async () => {
    switch props.settingsEdit {
    | None => ()
    | Some(draft) => await submitSettingsSave(draft)
    }
  }

  let onCreateCustomer = async () => {
    let payload = createCustomerPayload()
    switch await PortalApi.createCustomer(
      ~slug=payload.slug,
      ~displayName=payload.displayName,
      ~expiresAt=payload.expiresAt,
      ~recipientType=payload.recipientType,
      ~contactName=None,
      ~contactEmail=None,
      ~contactPhone=None,
    ) {
    | Ok(result) => finishCreateCustomer(result)
    | Error(message) => props.setFlash(_ => {error: Some(message), success: None})
    }
  }

  let onUpdateCustomer = async (customerId, draft: customerDraft) => {
    switch await PortalApi.updateCustomer(
      ~customerId,
      ~displayName=draft.displayName->String.trim,
      ~recipientType=draft.recipientType,
      ~contactName=None,
      ~contactEmail=None,
      ~contactPhone=None,
      ~isActive=draft.isActive,
    ) {
    | Ok(_) =>
      props.setFlash(_ => {error: None, success: Some("Customer updated.")})
      props.loadAdmin(~preserveReadyState=true)
    | Error(message) => props.setFlash(_ => {error: Some(message), success: None})
    }
  }

  let onGenerateLink = async (customerId, expiryLocal) => {
    switch await PortalApi.regenerateAccessLink(
      ~customerId,
      ~expiresAt=localDateTimeToIso(expiryLocal),
    ) {
    | Ok(result) =>
      props.setLastGeneratedLinks(prev => prev->Belt.Map.String.set(customerId, result.accessUrl))
      props.setFlash(_ => {error: None, success: Some("New access link generated.")})
      props.loadAdmin(~preserveReadyState=true)
    | Error(message) => props.setFlash(_ => {error: Some(message), success: None})
    }
  }

  let onRevokeLink = async customerId => {
    switch await PortalApi.revokeAccessLink(~customerId) {
    | Ok(_) =>
      removeGeneratedLink(customerId)
      props.setFlash(_ => {error: None, success: Some("Access link revoked.")})
      props.loadAdmin(~preserveReadyState=true)
    | Error(message) => props.setFlash(_ => {error: Some(message), success: None})
    }
  }

  let onDeleteAccessLinks = async customerId => {
    if Window.confirm("Delete all saved access links for this recipient? This cannot be undone.") {
      switch await PortalApi.deleteAccessLinks(~customerId) {
      | Ok(_) =>
        removeGeneratedLink(customerId)
        props.setFlash(_ => {error: None, success: Some("Access links deleted.")})
        props.loadAdmin(~preserveReadyState=true)
      | Error(message) => props.setFlash(_ => {error: Some(message), success: None})
      }
    }
  }

  let onDeleteCustomer = async customerId => {
    if (
      Window.confirm(
        "Force delete this recipient, all their links, and all tour assignments? This cannot be undone.",
      )
    ) {
      switch await PortalApi.deleteCustomer(~customerId) {
      | Ok(_) =>
        removeGeneratedLink(customerId)
        props.setCustomerDrafts(prev => prev->Belt.Map.String.remove(customerId))
        props.setExpiryDrafts(prev => prev->Belt.Map.String.remove(customerId))
        props.setFlash(_ => {error: None, success: Some("Recipient deleted.")})
        props.loadAdmin(~preserveReadyState=true)
      | Error(message) => props.setFlash(_ => {error: Some(message), success: None})
      }
    }
  }

  let onUploadTour = async () => {
    switch props.selectedUploadFile {
    | Some(file) =>
      Logger.info(
        ~module_="PortalApp",
        ~message="Starting tour upload",
        ~data=Some({"title": props.uploadTitle, "fileSize": BrowserBindings.File.size(file)}),
        (),
      )
      props.setFlash(_ => {error: None, success: Some("Starting upload...")})
      switch await PortalApi.uploadTour(~title=props.uploadTitle->String.trim, ~file) {
      | Ok(_) =>
        Logger.info(
          ~module_="PortalApp",
          ~message="Tour upload successful",
          ~data=Some({"title": props.uploadTitle}),
          (),
        )
        props.setUploadTitle(_ => "")
        props.setSelectedUploadFile(_ => None)
        props.setActiveDrawer(_ => NoDrawer)
        props.setFlash(_ => {error: None, success: Some("Tour uploaded to the library.")})
        props.loadAdmin(~preserveReadyState=true)
      | Error(message) =>
        Logger.error(
          ~module_="PortalApp",
          ~message="Tour upload failed",
          ~data=Some({"error": message}),
          (),
        )
        props.setFlash(_ => {error: Some(message), success: None})
      }
    | None => props.setFlash(_ => {error: Some("Choose a ZIP file first."), success: None})
    }
  }

  let onAssignToggle = async (~customerId, ~tourId, ~assigned) => {
    let result = if assigned {
      await PortalApi.unassignTour(~customerId, ~tourId)
    } else {
      await PortalApi.assignTour(~customerId, ~tourId)
    }
    switch result {
    | Ok(_) =>
      props.setFlash(_ => {
        error: None,
        success: Some(
          if assigned {
            "Tour unassigned."
          } else {
            "Tour assigned."
          },
        ),
      })
      props.loadAdmin(~preserveReadyState=true)
    | Error(message) => props.setFlash(_ => {error: Some(message), success: None})
    }
  }

  let onBulkAssign = async () => {
    let customerIds = props.selectedBulkCustomerIds->Belt.Set.String.toArray
    let tourIds = props.selectedBulkTourIds->Belt.Set.String.toArray
    switch await PortalApi.bulkAssignTours(~customerIds, ~tourIds) {
    | Ok(result) =>
      let message = if result.skippedCount > 0 {
        Belt.Int.toString(result.createdCount) ++
        " assignments created, " ++
        Belt.Int.toString(result.skippedCount) ++ " already existed."
      } else {
        Belt.Int.toString(result.createdCount) ++ " assignments created."
      }
      props.setSelectedBulkCustomerIds(_ => Belt.Set.String.empty)
      props.setSelectedBulkTourIds(_ => Belt.Set.String.empty)
      props.setFlash(_ => {error: None, success: Some(message)})
      props.loadAdmin(~preserveReadyState=true)
    | Error(message) => props.setFlash(_ => {error: Some(message), success: None})
    }
  }

  let onTourStatus = async (~tourId, ~status) => {
    switch await PortalApi.updateTourStatus(~tourId, ~status) {
    | Ok(_) =>
      props.setFlash(_ => {error: None, success: Some("Tour status updated.")})
      props.loadAdmin(~preserveReadyState=true)
    | Error(message) => props.setFlash(_ => {error: Some(message), success: None})
    }
  }

  let onDeleteTour = async (~tourId, ~title) => {
    if (
      Window.confirm(
        "Force delete \"" ++
        title ++ "\" from the library and remove all assignments? This cannot be undone.",
      )
    ) {
      switch await PortalApi.deleteTour(~tourId) {
      | Ok(_) =>
        props.setFlash(_ => {error: None, success: Some("Tour deleted from library.")})
        props.loadAdmin(~preserveReadyState=true)
      | Error(message) => props.setFlash(_ => {error: Some(message), success: None})
      }
    }
  }

  let onSignOut = async () => {
    let _ = await PortalApi.signOutAdmin()
    assignLocation("/portal-admin/signin")
  }

  {
    onAdminSignIn,
    onChangePassword,
    onSaveSettings,
    onCreateCustomer,
    onUpdateCustomer,
    onGenerateLink,
    onRevokeLink,
    onDeleteAccessLinks,
    onDeleteCustomer,
    onUploadTour,
    onAssignToggle,
    onBulkAssign,
    onTourStatus,
    onDeleteTour,
    onSignOut,
  }
}
