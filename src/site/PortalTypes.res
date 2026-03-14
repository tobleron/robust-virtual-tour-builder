module Decode = JsonCombinators.Json.Decode

type recipientType =
  | PropertyOwner
  | Broker
  | PropertyOwnerBroker

type customer = {
  id: string,
  slug: string,
  displayName: string,
  recipientType: recipientType,
  contactName: option<string>,
  contactEmail: option<string>,
  contactPhone: option<string>,
  isActive: bool,
}

type settings = {
  renewalHeading: string,
  renewalMessage: string,
  contactEmail: option<string>,
  contactPhone: option<string>,
  whatsappNumber: option<string>,
}

type accessLink = {
  id: string,
  expiresAt: string,
  revokedAt: option<string>,
  lastOpenedAt: option<string>,
  active: bool,
  accessUrl: option<string>,
}

type customerAccessLink = {
  id: string,
  expiresAt: string,
  revokedAt: option<string>,
  lastOpenedAt: option<string>,
  active: bool,
  accessUrl: option<string>,
}

type customerOverview = {
  customer: customer,
  accessLink: option<accessLink>,
  assignedTourIds: array<string>,
  tourCount: int,
}

type generatedAccessLink = {
  customerId: string,
  customerSlug: string,
  accessUrl: string,
  expiresAt: string,
}

type customerCreateResult = {
  overview: customerOverview,
  accessLink: generatedAccessLink,
}

type customerPublic = {
  slug: string,
  displayName: string,
  isActive: bool,
}

type publicView = {
  customer: customerPublic,
  settings: settings,
}

type customerSession = {
  customer: customerPublic,
  settings: settings,
  accessLink: customerAccessLink,
  expired: bool,
  canOpenTours: bool,
}

type customerSessionResponse = {
  authenticated: bool,
  session: customerSession,
}

type tourCard = {
  id: string,
  title: string,
  slug: string,
  status: string,
  coverUrl: option<string>,
  canOpen: bool,
}

type galleryView = {
  customer: customerPublic,
  settings: settings,
  accessLink: customerAccessLink,
  expired: bool,
  canOpenTours: bool,
  tours: array<tourCard>,
}

type libraryTour = {
  id: string,
  title: string,
  slug: string,
  status: string,
  storagePath: string,
  coverPath: option<string>,
}

type libraryTourOverview = {
  tour: libraryTour,
  assignmentCount: int,
}

type bulkAssignmentResult = {
  customerIds: array<string>,
  tourIds: array<string>,
  requestedCount: int,
  createdCount: int,
  skippedCount: int,
}

let optString = Decode.option(Decode.string)

let recipientTypeDecoder = Decode.custom(json => {
  switch JsonCombinators.Json.decode(json, Decode.string) {
  | Ok("property_owner") => PropertyOwner
  | Ok("broker") => Broker
  | Ok("property_owner_broker") => PropertyOwnerBroker
  | Ok(value) => throw(Decode.DecodeError("Unknown recipient type: " ++ value))
  | Error(message) => throw(Decode.DecodeError(message))
  }
})

let customerDecoder = Decode.object(field => {
  id: field.required("id", Decode.string),
  slug: field.required("slug", Decode.string),
  displayName: field.required("displayName", Decode.string),
  recipientType: field.required("recipientType", recipientTypeDecoder),
  contactName: field.optional("contactName", optString)->Option.flatMap(x => x),
  contactEmail: field.optional("contactEmail", optString)->Option.flatMap(x => x),
  contactPhone: field.optional("contactPhone", optString)->Option.flatMap(x => x),
  isActive: field.required("isActive", Decode.int) == 1,
})

let settingsDecoder = Decode.object(field => {
  renewalHeading: field.required("renewalHeading", Decode.string),
  renewalMessage: field.required("renewalMessage", Decode.string),
  contactEmail: field.optional("contactEmail", optString)->Option.flatMap(x => x),
  contactPhone: field.optional("contactPhone", optString)->Option.flatMap(x => x),
  whatsappNumber: field.optional("whatsappNumber", optString)->Option.flatMap(x => x),
})

let accessLinkDecoder = Decode.object((field): accessLink => {
  id: field.required("id", Decode.string),
  expiresAt: field.required("expiresAt", Decode.string),
  revokedAt: field.optional("revokedAt", optString)->Option.flatMap(x => x),
  lastOpenedAt: field.optional("lastOpenedAt", optString)->Option.flatMap(x => x),
  active: field.required("active", Decode.bool),
  accessUrl: field.optional("accessUrl", optString)->Option.flatMap(x => x),
})

let customerAccessLinkDecoder = Decode.object((field): customerAccessLink => {
  id: field.required("id", Decode.string),
  expiresAt: field.required("expiresAt", Decode.string),
  revokedAt: field.optional("revokedAt", optString)->Option.flatMap(x => x),
  lastOpenedAt: field.optional("lastOpenedAt", optString)->Option.flatMap(x => x),
  active: field.required("active", Decode.bool),
  accessUrl: field.optional("accessUrl", optString)->Option.flatMap(x => x),
})

let customerOverviewDecoder = Decode.object(field => {
  customer: field.required("customer", customerDecoder),
  accessLink: field.optional("accessLink", Decode.option(accessLinkDecoder))->Option.flatMap(x =>
    x
  ),
  assignedTourIds: field.required("assignedTourIds", Decode.array(Decode.string)),
  tourCount: field.required("tourCount", Decode.int),
})

let generatedAccessLinkDecoder = Decode.object(field => {
  customerId: field.required("customerId", Decode.string),
  customerSlug: field.required("customerSlug", Decode.string),
  accessUrl: field.required("accessUrl", Decode.string),
  expiresAt: field.required("expiresAt", Decode.string),
})

let customerCreateResultDecoder = Decode.object(field => {
  overview: field.required("overview", customerOverviewDecoder),
  accessLink: field.required("accessLink", generatedAccessLinkDecoder),
})

let customerPublicDecoder = Decode.object(field => {
  slug: field.required("slug", Decode.string),
  displayName: field.required("displayName", Decode.string),
  isActive: field.required("isActive", Decode.bool),
})

let publicViewDecoder = Decode.object(field => {
  customer: field.required("customer", customerPublicDecoder),
  settings: field.required("settings", settingsDecoder),
})

let customerSessionDecoder = Decode.object(field => {
  customer: field.required("customer", customerPublicDecoder),
  settings: field.required("settings", settingsDecoder),
  accessLink: field.required("accessLink", customerAccessLinkDecoder),
  expired: field.required("expired", Decode.bool),
  canOpenTours: field.required("canOpenTours", Decode.bool),
})

let customerSessionResponseDecoder = Decode.object(field => {
  authenticated: field.required("authenticated", Decode.bool),
  session: field.required("session", customerSessionDecoder),
})

let tourCardDecoder = Decode.object(field => {
  id: field.required("id", Decode.string),
  title: field.required("title", Decode.string),
  slug: field.required("slug", Decode.string),
  status: field.required("status", Decode.string),
  coverUrl: field.optional("coverUrl", optString)->Option.flatMap(x => x),
  canOpen: field.required("canOpen", Decode.bool),
})

let galleryViewDecoder = Decode.object(field => {
  customer: field.required("customer", customerPublicDecoder),
  settings: field.required("settings", settingsDecoder),
  accessLink: field.required("accessLink", customerAccessLinkDecoder),
  expired: field.required("expired", Decode.bool),
  canOpenTours: field.required("canOpenTours", Decode.bool),
  tours: field.required("tours", Decode.array(tourCardDecoder)),
})

let libraryTourDecoder = Decode.object(field => {
  id: field.required("id", Decode.string),
  title: field.required("title", Decode.string),
  slug: field.required("slug", Decode.string),
  status: field.required("status", Decode.string),
  storagePath: field.required("storagePath", Decode.string),
  coverPath: field.optional("coverPath", optString)->Option.flatMap(x => x),
})

let libraryTourOverviewDecoder = Decode.object(field => {
  tour: field.required("tour", libraryTourDecoder),
  assignmentCount: field.required("assignmentCount", Decode.int),
})

let bulkAssignmentResultDecoder = Decode.object(field => {
  customerIds: field.required("customerIds", Decode.array(Decode.string)),
  tourIds: field.required("tourIds", Decode.array(Decode.string)),
  requestedCount: field.required("requestedCount", Decode.int),
  createdCount: field.required("createdCount", Decode.int),
  skippedCount: field.required("skippedCount", Decode.int),
})
