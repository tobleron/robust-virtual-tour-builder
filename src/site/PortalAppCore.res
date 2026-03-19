// @efficiency-role: util-pure
open ReBindings

type route =
  | Landing
  | AdminSignin
  | AdminDashboard
  | CustomerPortal(string)
  | CustomerTour(string, string)

type remoteData<'a> =
  | Idle
  | Loading
  | Ready('a)
  | Failed(string)

type flash = {
  error: option<string>,
  success: option<string>,
}

type createCustomerDraft = {
  slug: string,
  displayName: string,
  expiresAt: string,
  recipientType: PortalTypes.recipientType,
}

type settingsDraft = {
  renewalHeading: string,
  renewalMessage: string,
  contactEmail: string,
  contactPhone: string,
  whatsappNumber: string,
}

type customerDraft = {
  displayName: string,
  recipientType: PortalTypes.recipientType,
  isActive: bool,
}

type adminData = {
  session: PortalApi.adminSession,
  settings: PortalTypes.settings,
  customers: array<PortalTypes.customerOverview>,
  tours: array<PortalTypes.libraryTourOverview>,
}

type adminRefreshResult =
  | RefreshOk(adminData)
  | RefreshAuth
  | RefreshError(string)

type adminDrawer =
  | NoDrawer
  | RecipientDrawer
  | UploadDrawer
  | SettingsDrawer

type recipientStatusFilter =
  | RecipientAll
  | RecipientActive
  | RecipientAttention

type recipientTypeFilter =
  | RecipientTypeAll
  | RecipientTypePropertyOwner
  | RecipientTypeBroker
  | RecipientTypePropertyOwnerBroker

type tourStatusFilter =
  | TourAll
  | TourPublished
  | TourDraft
  | TourArchived

type assignmentMode =
  | SingleRecipientMode
  | BulkAssignMode

let findCustomerOverview = (
  customers: array<PortalTypes.customerOverview>,
  customerId: string,
): option<PortalTypes.customerOverview> =>
  customers->Belt.Array.getBy((customer: PortalTypes.customerOverview) =>
    customer.customer.id == customerId
  )

@val @scope("window.location") external pathname: string = "pathname"
@val @scope("window.location") external search: string = "search"
@val @scope("window.location") external assignLocation: string => unit = "assign"
@val @scope("window") external documentRef: {..} = "document"
@set external setDocumentTitle: ({..}, string) => unit = "title"
@val external encodeURIComponent: string => string = "encodeURIComponent"
@new external makeUrlSearchParams: string => {..} = "URLSearchParams"
@send @return(nullable) external getSearchParam: ({..}, string) => option<string> = "get"
@new external makeDate: string => {..} = "Date"
@send external toISOString: {..} => string = "toISOString"
@send external toLocaleStringValue: {..} => string = "toLocaleString"
@get external checked: Dom.element => bool = "checked"
@get external filesFromInputTarget: {..} => option<FileList.t> = "files"

let parseRoute = () =>
  switch PortalAppCoreRoutes.parseRoute() {
  | PortalAppCoreRoutes.Landing => Landing
  | PortalAppCoreRoutes.AdminSignin => AdminSignin
  | PortalAppCoreRoutes.AdminDashboard => AdminDashboard
  | PortalAppCoreRoutes.CustomerPortal(slug) => CustomerPortal(slug)
  | PortalAppCoreRoutes.CustomerTour(slug, tourSlug) => CustomerTour(slug, tourSlug)
  }

let nowPlusDaysIsoLocal = days => {
  let millis = Date.now() +. Float.fromInt(days) *. 24.0 *. 60.0 *. 60.0 *. 1000.0
  Date.fromTime(millis)->Date.toISOString->String.slice(~start=0, ~end=16)
}

let isoToLocalDateTime = value => {
  if value == "" {
    ""
  } else {
    try {
      makeDate(value)->toISOString->String.slice(~start=0, ~end=16)
    } catch {
    | _ => ""
    }
  }
}

let localDateTimeToIso = value => {
  if value == "" {
    ""
  } else {
    try {
      makeDate(value)->toISOString
    } catch {
    | _ => ""
    }
  }
}

let friendlyDateTimeLabel = value => {
  if value == "" {
    ""
  } else {
    try {
      makeDate(value)->toLocaleStringValue
    } catch {
    | _ => value
    }
  }
}

let routeAccessMessage = PortalAppCoreRoutes.routeAccessMessage

let customerPortalPath = PortalAppCoreRoutes.customerPortalPath
let customerTourPath = PortalAppCoreRoutes.customerTourPath
let directTourAccessUrl = PortalAppCoreRoutes.directTourAccessUrl
let portalTourEntryBaseUrl = PortalAppCoreRoutes.portalTourEntryBaseUrl
let portalTourEntryCandidates = PortalAppCoreRoutes.portalTourEntryCandidates
let injectBaseHref = PortalAppCoreRoutes.injectBaseHref
let loadPortalTourDocument = PortalAppCoreRoutes.loadPortalTourDocument

let emptyFlash = {error: None, success: None}

let draftFromSettings = (settings: PortalTypes.settings): settingsDraft => {
  renewalHeading: settings.renewalHeading,
  renewalMessage: settings.renewalMessage,
  contactEmail: settings.contactEmail->Option.getOr(""),
  contactPhone: settings.contactPhone->Option.getOr(""),
  whatsappNumber: settings.whatsappNumber->Option.getOr(""),
}

let customerDraftFromOverview = (overview: PortalTypes.customerOverview): customerDraft => {
  displayName: overview.customer.displayName,
  recipientType: overview.customer.recipientType,
  isActive: overview.customer.isActive,
}

let recipientTypeValue = (recipientType: PortalTypes.recipientType) =>
  switch recipientType {
  | PortalTypes.PropertyOwner => "property_owner"
  | PortalTypes.Broker => "broker"
  | PortalTypes.PropertyOwnerBroker => "property_owner_broker"
  }

let recipientTypeLabel = (recipientType: PortalTypes.recipientType) =>
  switch recipientType {
  | PortalTypes.PropertyOwner => "Property owner"
  | PortalTypes.Broker => "Broker"
  | PortalTypes.PropertyOwnerBroker => "Property owner & broker"
  }

let recipientTypeFromValue = value =>
  switch value {
  | "broker" => PortalTypes.Broker
  | "property_owner_broker" => PortalTypes.PropertyOwnerBroker
  | _ => PortalTypes.PropertyOwner
  }


let summarizedLink = value =>
  if String.length(value) <= 68 {
    value
  } else {
    String.slice(value, ~start=0, ~end=46) ++
    "..." ++
    String.slice(value, ~start=String.length(value) - 18, ~end=String.length(value))
  }

let pageSize = 10

let paginateArray = (items: array<'a>, page: int) => {
  let safePage = if page < 0 {
    0
  } else {
    page
  }
  let startIndex = safePage * pageSize
  let paged =
    items->Belt.Array.keepWithIndex((_, index) =>
      index >= startIndex && index < startIndex + pageSize
    )
  let total = items->Belt.Array.length
  let hasPrev = safePage > 0
  let hasNext = startIndex + pageSize < total
  (paged, total, hasPrev, hasNext)
}

let totalPages = total =>
  if total <= 0 {
    1
  } else {
    (total - 1) / pageSize + 1
  }

let recipientAccessLabel = (overview: PortalTypes.customerOverview) =>
  switch overview.accessLink {
  | Some(link) =>
    if !overview.customer.isActive {
      ("Inactive", "is-locked")
    } else if link.active {
      ("Active", "is-published")
    } else {
      ("Revoked", "is-expired")
    }
  | None =>
    if overview.customer.isActive {
      ("No link", "is-locked")
    } else {
      ("Inactive", "is-locked")
    }
  }

let customerNeedsAttention = (overview: PortalTypes.customerOverview) =>
  switch overview.accessLink {
  | Some(link) => !link.active
  | None => true
  }

let matchesRecipientSearch = (overview: PortalTypes.customerOverview, query: string) => {
  let normalizedQuery = query->String.trim->String.toLowerCase
  if normalizedQuery == "" {
    true
  } else {
    let displayName = overview.customer.displayName->String.toLowerCase
    let slug = overview.customer.slug->String.toLowerCase
    let recipientType = overview.customer.recipientType->recipientTypeLabel->String.toLowerCase
    displayName->String.includes(normalizedQuery) ||
    slug->String.includes(normalizedQuery) ||
    recipientType->String.includes(normalizedQuery)
  }
}

let matchesRecipientFilter = (
  overview: PortalTypes.customerOverview,
  filter: recipientStatusFilter,
) =>
  switch filter {
  | RecipientAll => true
  | RecipientActive => !customerNeedsAttention(overview)
  | RecipientAttention => customerNeedsAttention(overview)
  }

let matchesRecipientTypeFilter = (
  overview: PortalTypes.customerOverview,
  filter: recipientTypeFilter,
) =>
  switch filter {
  | RecipientTypeAll => true
  | RecipientTypePropertyOwner => overview.customer.recipientType == PortalTypes.PropertyOwner
  | RecipientTypeBroker => overview.customer.recipientType == PortalTypes.Broker
  | RecipientTypePropertyOwnerBroker =>
    overview.customer.recipientType == PortalTypes.PropertyOwnerBroker
  }

let matchesTourSearch = (overview: PortalTypes.libraryTourOverview, query: string) => {
  let normalizedQuery = query->String.trim->String.toLowerCase
  if normalizedQuery == "" {
    true
  } else {
    let title = overview.tour.title->String.toLowerCase
    let slug = overview.tour.slug->String.toLowerCase
    let id = overview.tour.id->String.toLowerCase
    title->String.includes(normalizedQuery) ||
    slug->String.includes(normalizedQuery) ||
    id->String.includes(normalizedQuery)
  }
}

let matchesTourFilter = (overview: PortalTypes.libraryTourOverview, filter: tourStatusFilter) =>
  switch filter {
  | TourAll => true
  | TourPublished => overview.tour.status == "published"
  | TourDraft => overview.tour.status == "draft"
  | TourArchived => overview.tour.status == "archived"
  }
