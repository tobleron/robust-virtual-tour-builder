open ReBindings

module Encode = JsonCombinators.Json.Encode
module Decode = JsonCombinators.Json.Decode

type adminSession = {
  authenticated: bool,
  email: option<string>,
}

type apiErrorPayload = {
  details: option<string>,
  error: option<string>,
  message: option<string>,
}

type signInPayload = {
  token: option<string>,
  challengeRequired: bool,
  message: option<string>,
}

type okPayload = {ok: bool}

type sessionUser = {email: option<string>}

let devHosts = Belt.Set.String.fromArray(["localhost", "127.0.0.1", "0.0.0.0"])

@val @scope("window.location") external hostname: string = "hostname"
@val @scope("window.location") external assignLocation: string => unit = "assign"
@val @scope("window.location") external replaceLocation: string => unit = "replace"

let apiErrorDecoder = Decode.object((field): apiErrorPayload => {
  details: field.optional("details", Decode.string),
  error: field.optional("error", Decode.string),
  message: field.optional("message", Decode.string),
})

let adminSessionDecoder = Decode.object((field): adminSession => {
  authenticated: field.optional("authenticated", Decode.bool)->Option.getOr(false),
  email: field.optional(
    "user",
    Decode.object((inner): sessionUser => {
      email: inner.optional("email", Decode.string),
    }),
  )->Option.flatMap(result => result.email),
})

let signInDecoder = Decode.object((field): signInPayload => {
  token: field.optional("token", Decode.string),
  challengeRequired: field.optional("challengeRequired", Decode.bool)->Option.getOr(false),
  message: field.optional("message", Decode.string),
})

let okDecoder = Decode.object((field): okPayload => {
  ok: field.optional("ok", Decode.bool)->Option.getOr(false),
})

let authHeaderValue = () => {
  switch Dom.Storage2.localStorage->Dom.Storage2.getItem("auth_token") {
  | Some(token) if token->String.trim != "" => Some("Bearer " ++ token)
  | _ if devHosts->Belt.Set.String.has(hostname->String.toLowerCase) => Some("Bearer dev-token")
  | _ => None
  }
}

let maybeErrorMessage = json =>
  switch JsonCombinators.Json.decode(json, apiErrorDecoder) {
  | Ok(payload) =>
    payload.details
    ->Option.orElse(payload.error)
    ->Option.orElse(payload.message)
  | Error(_) => None
  }

let decodeResponse = (response, decoder) =>
  Fetch.json(response)->Promise.then(json => {
    switch JsonCombinators.Json.decode(json, decoder) {
    | Ok(payload) => Promise.resolve(Ok(payload))
    | Error(message) => Promise.resolve(Error("Portal decode failed: " ++ message))
    }
  })

let decodeErrorResponse = response =>
  Fetch.json(response)
  ->Promise.then(json => {
    let message =
      maybeErrorMessage(json)->Option.getOr("HTTP_" ++ Belt.Int.toString(Fetch.status(response)))
    Promise.resolve(message)
  })
  ->Promise.catch(_ => Promise.resolve("HTTP_" ++ Belt.Int.toString(Fetch.status(response))))

let request = async (
  url: string,
  ~method="GET",
  ~jsonBody: option<JSON.t>=?,
  ~formData: option<FormData.t>=?,
  ~decoder,
  ~authenticated=false,
  ~includeCredentials=false,
) => {
  let headers = Dict.make()
  if jsonBody->Option.isSome {
    Dict.set(headers, "Content-Type", "application/json")
  }
  if authenticated {
    authHeaderValue()->Option.forEach(value => Dict.set(headers, "Authorization", value))
  }

  let credentials = if includeCredentials { "include" } else { "same-origin" }

  let response = switch (jsonBody, formData) {
  | (Some(body), _) =>
    await Fetch.fetch(
      url,
      Fetch.requestInit(~method, ~body=JsonCombinators.Json.stringify(body), ~headers, ~credentials, ()),
    )
  | (None, Some(fd)) => await Fetch.fetch(url, Fetch.requestInit(~method, ~body=fd, ~headers, ~credentials, ()))
  | (None, None) => await Fetch.fetch(url, Fetch.requestInit(~method, ~headers, ~credentials, ()))
  }

  if Fetch.ok(response) {
    await decodeResponse(response, decoder)
  } else {
    let message = await decodeErrorResponse(response)
    Error(message)
  }
}

let getAdminSession = async () => {
  switch await request("/api/auth/me", ~decoder=adminSessionDecoder, ~authenticated=true) {
  | Ok(session) => session
  | Error(_) => {authenticated: false, email: None}
  }
}

let signInAdmin = async (~email, ~password) => {
  let body = Encode.object([("email", Encode.string(email)), ("password", Encode.string(password))])
  switch await request(
    "/api/auth/signin",
    ~method="POST",
    ~jsonBody=?Some(body),
    ~decoder=signInDecoder,
  ) {
  | Ok(result) =>
    if result.challengeRequired {
      Error(result.message->Option.getOr("Verification code is required for this sign-in."))
    } else {
      result.token->Option.forEach(token =>
        Dom.Storage2.localStorage->Dom.Storage2.setItem("auth_token", token)
      )
      Ok()
    }
  | Error(message) => Error(message)
  }
}

let signOutAdmin = async () => {
  let _ = await request(
    "/api/auth/signout",
    ~method="POST",
    ~decoder=Decode.object(_ => {"ok": true}),
  )
  Dom.Storage2.localStorage->Dom.Storage2.removeItem("auth_token")
  Ok()
}

let changeAdminPassword = async (~currentPassword, ~newPassword) => {
  let body = Encode.object([
    ("currentPassword", Encode.string(currentPassword)),
    ("newPassword", Encode.string(newPassword)),
  ])
  switch await request(
    "/api/auth/change-password",
    ~method="POST",
    ~jsonBody=?Some(body),
    ~decoder=okDecoder,
    ~authenticated=true,
  ) {
  | Ok(_) => Ok()
  | Error(message) => Error(message)
  }
}

let loadSettings = async () =>
  await request(
    "/api/portal/admin/settings",
    ~decoder=PortalTypes.settingsDecoder,
    ~authenticated=true,
  )

let updateSettings = async (~settings: PortalTypes.settings) => {
  let body = Encode.object([
    ("renewalHeading", Encode.string(settings.renewalHeading)),
    ("renewalMessage", Encode.string(settings.renewalMessage)),
    ("contactEmail", Encode.option(Encode.string)(settings.contactEmail)),
    ("contactPhone", Encode.option(Encode.string)(settings.contactPhone)),
    ("whatsappNumber", Encode.option(Encode.string)(settings.whatsappNumber)),
  ])
  await request(
    "/api/portal/admin/settings",
    ~method="PATCH",
    ~jsonBody=?Some(body),
    ~decoder=PortalTypes.settingsDecoder,
    ~authenticated=true,
  )
}

let listCustomers = async () =>
  await request(
    "/api/portal/admin/customers",
    ~decoder=Decode.array(PortalTypes.customerOverviewDecoder),
    ~authenticated=true,
  )

let listLibraryTours = async () =>
  await request(
    "/api/portal/admin/tours",
    ~decoder=Decode.array(PortalTypes.libraryTourOverviewDecoder),
    ~authenticated=true,
  )

let encodeRecipientType = (recipientType: PortalTypes.recipientType) =>
  Encode.string(
    switch recipientType {
    | PortalTypes.PropertyOwner => "property_owner"
    | PortalTypes.Broker => "broker"
    | PortalTypes.PropertyOwnerBroker => "property_owner_broker"
    },
  )

let createCustomer = async (
  ~slug,
  ~displayName,
  ~expiresAt,
  ~recipientType,
  ~contactName,
  ~contactEmail,
  ~contactPhone,
) => {
  let body = Encode.object([
    ("slug", Encode.string(slug)),
    ("displayName", Encode.string(displayName)),
    ("expiresAt", Encode.string(expiresAt)),
    ("recipientType", encodeRecipientType(recipientType)),
    ("contactName", Encode.option(Encode.string)(contactName)),
    ("contactEmail", Encode.option(Encode.string)(contactEmail)),
    ("contactPhone", Encode.option(Encode.string)(contactPhone)),
  ])
  await request(
    "/api/portal/admin/customers",
    ~method="POST",
    ~jsonBody=?Some(body),
    ~decoder=PortalTypes.customerCreateResultDecoder,
    ~authenticated=true,
  )
}

let updateCustomer = async (
  ~customerId,
  ~displayName,
  ~recipientType,
  ~contactName,
  ~contactEmail,
  ~contactPhone,
  ~isActive,
) => {
  let body = Encode.object([
    ("displayName", Encode.string(displayName)),
    ("recipientType", encodeRecipientType(recipientType)),
    ("contactName", Encode.option(Encode.string)(contactName)),
    ("contactEmail", Encode.option(Encode.string)(contactEmail)),
    ("contactPhone", Encode.option(Encode.string)(contactPhone)),
    ("isActive", Encode.bool(isActive)),
  ])
  await request(
    "/api/portal/admin/customers/" ++ customerId,
    ~method="PATCH",
    ~jsonBody=?Some(body),
    ~decoder=PortalTypes.customerOverviewDecoder,
    ~authenticated=true,
  )
}

let regenerateAccessLink = async (~customerId, ~expiresAt) => {
  let body = Encode.object([("expiresAt", Encode.string(expiresAt))])
  await request(
    "/api/portal/admin/customers/" ++ customerId ++ "/access-links/regenerate",
    ~method="POST",
    ~jsonBody=?Some(body),
    ~decoder=PortalTypes.generatedAccessLinkDecoder,
    ~authenticated=true,
  )
}

let revokeAccessLink = async (~customerId) =>
  await request(
    "/api/portal/admin/customers/" ++ customerId ++ "/access-links/revoke",
    ~method="POST",
    ~decoder=PortalTypes.customerOverviewDecoder,
    ~authenticated=true,
  )

let deleteAccessLinks = async (~customerId) =>
  await request(
    "/api/portal/admin/customers/" ++ customerId ++ "/access-links",
    ~method="DELETE",
    ~decoder=PortalTypes.customerOverviewDecoder,
    ~authenticated=true,
  )

let assignTour = async (~customerId, ~tourId) => {
  let body = Encode.object([("tourId", Encode.string(tourId))])
  await request(
    "/api/portal/admin/customers/" ++ customerId ++ "/assignments",
    ~method="POST",
    ~jsonBody=?Some(body),
    ~decoder=PortalTypes.customerOverviewDecoder,
    ~authenticated=true,
  )
}

let unassignTour = async (~customerId, ~tourId) =>
  await request(
    "/api/portal/admin/customers/" ++ customerId ++ "/assignments/" ++ tourId,
    ~method="DELETE",
    ~decoder=PortalTypes.customerOverviewDecoder,
    ~authenticated=true,
  )

let bulkAssignTours = async (~customerIds, ~tourIds) => {
  let body = Encode.object([
    ("customerIds", Encode.array(Encode.string)(customerIds)),
    ("tourIds", Encode.array(Encode.string)(tourIds)),
  ])
  await request(
    "/api/portal/admin/assignments/bulk",
    ~method="POST",
    ~jsonBody=?Some(body),
    ~decoder=PortalTypes.bulkAssignmentResultDecoder,
    ~authenticated=true,
  )
}

let updateTourStatus = async (~tourId, ~status) => {
  let body = Encode.object([("status", Encode.string(status))])
  await request(
    "/api/portal/admin/tours/" ++ tourId ++ "/status",
    ~method="POST",
    ~jsonBody=?Some(body),
    ~decoder=PortalTypes.libraryTourDecoder,
    ~authenticated=true,
  )
}

let deleteCustomer = async (~customerId) =>
  await request(
    "/api/portal/admin/customers/" ++ customerId,
    ~method="DELETE",
    ~decoder=Decode.object(_ => {"ok": true}),
    ~authenticated=true,
  )

let deleteTour = async (~tourId) =>
  await request(
    "/api/portal/admin/tours/" ++ tourId,
    ~method="DELETE",
    ~decoder=Decode.object(_ => {"ok": true}),
    ~authenticated=true,
  )

let uploadTour = async (~title, ~file: File.t) => {
  let formData = FormData.newFormData()
  FormData.append(formData, "title", title)
  FormData.append(formData, "zip", file)
  await request(
    "/api/portal/admin/tours/upload",
    ~method="POST",
    ~formData=?Some(formData),
    ~decoder=PortalTypes.libraryTourDecoder,
    ~authenticated=true,
  )
}

let loadCustomerPublic = async slug =>
  await request(
    "/api/portal/customers/" ++ slug ++ "/public",
    ~decoder=PortalTypes.publicViewDecoder,
  )

let loadCustomerSession = async slug =>
  await request(
    "/api/portal/customers/" ++ slug ++ "/session",
    ~decoder=PortalTypes.customerSessionResponseDecoder,
    ~includeCredentials=true,
  )

let loadCustomerTours = async slug =>
  await request(
    "/api/portal/customers/" ++ slug ++ "/tours",
    ~decoder=PortalTypes.galleryViewDecoder,
    ~includeCredentials=true,
  )

let signOutCustomer = async slug =>
  await request(
    "/api/portal/customers/" ++ slug ++ "/signout",
    ~method="POST",
    ~decoder=Decode.object(_ => {"ok": true}),
    ~includeCredentials=true,
  )
