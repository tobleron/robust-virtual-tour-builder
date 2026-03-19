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

let normalizePath = path => {
  let trimmed = path->String.trim
  if trimmed == "" || trimmed == "/" {
    "/"
  } else {
    let rec stripTrailingSlash = value =>
      if String.length(value) > 1 && String.endsWith(value, "/") {
        stripTrailingSlash(String.slice(value, ~start=0, ~end=String.length(value) - 1))
      } else {
        value
      }
    let normalized = stripTrailingSlash(trimmed)
    if normalized == "" {
      "/"
    } else {
      normalized
    }
  }
}

let parseRoute = () => {
  let path = normalizePath(pathname)
  let segments = path->String.split("/")
  switch Belt.Array.length(segments) {
  | 1 => Landing
  | 2 =>
    switch Belt.Array.get(segments, 1) {
    | Some("index.html") => Landing
    | Some("portal-admin") => AdminDashboard
    | _ => Landing
    }
  | 3 =>
    switch (Belt.Array.get(segments, 1), Belt.Array.get(segments, 2)) {
    | (Some("portal-admin"), Some("signin")) => AdminSignin
    | (Some("portal"), Some(slug)) => CustomerPortal(slug)
    | (Some("u"), Some(slug)) => CustomerPortal(slug)
    | _ => Landing
    }
  | 4 =>
    switch (Belt.Array.get(segments, 1), Belt.Array.get(segments, 2), Belt.Array.get(segments, 3)) {
    | (Some("u"), Some(slug), Some(accessCode)) =>
      assignLocation("/access/" ++ accessCode ++ "?next=/u/" ++ slug)
      Landing
    | _ => Landing
    }
  | 5 =>
    switch (
      Belt.Array.get(segments, 1),
      Belt.Array.get(segments, 2),
      Belt.Array.get(segments, 3),
      Belt.Array.get(segments, 4),
    ) {
    | (Some("portal"), Some(slug), Some("tour"), Some(tourSlug)) => CustomerTour(slug, tourSlug)
    | (Some("u"), Some(slug), Some("tour"), Some(tourSlug)) => CustomerTour(slug, tourSlug)
    | _ => Landing
    }
  | _ => Landing
  }
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

let routeAccessMessage = () => {
  let params = makeUrlSearchParams(search)
  switch getSearchParam(params, "access") {
  | Some("expired") => Some("This private access link has expired or is no longer active.")
  | Some("invalid") => Some("This private access link is invalid.")
  | _ => None
  }
}

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

let directTourAccessUrl = (~accessUrl, ~tourSlug) =>
  accessUrl ++ "/tour/" ++ encodeURIComponent(tourSlug)

let customerPortalPath = slug => "/u/" ++ encodeURIComponent(slug)

let customerTourPath = (~slug, ~tourSlug) =>
  customerPortalPath(slug) ++ "/tour/" ++ encodeURIComponent(tourSlug)

let portalTourEntryBaseUrl = (~slug, ~tourSlug, ~entryDir) =>
  "/portal-assets/" ++
  encodeURIComponent(slug) ++
  "/" ++
  encodeURIComponent(tourSlug) ++
  "/" ++
  entryDir ++ "/"

let portalTourEntryCandidates = () => {
  let shortEdge = if Window.innerWidth <= Window.innerHeight {
    Window.innerWidth
  } else {
    Window.innerHeight
  }
  if shortEdge <= 430 {
    ["tour_2k", "tour_4k", "tour_hd"]
  } else {
    ["tour_4k", "tour_2k", "tour_hd"]
  }
}

let injectBaseHref = (~html, ~baseHref) => {
  let baseTag = "<base href=\"" ++ baseHref ++ "\">"
  if html->String.includes("<base ") {
    html
  } else if html->String.includes("<head>") {
    html->String.replaceRegExp(/<head>/i, "<head>" ++ baseTag)
  } else {
    baseTag ++ html
  }
}

let loadPortalTourDocument = async (~slug, ~tourSlug) => {
  let candidates = portalTourEntryCandidates()
  let rec tryCandidate = async index => {
    switch Belt.Array.get(candidates, index) {
    | None => Error("Unable to load this published tour.")
    | Some(entryDir) =>
      let baseHref = portalTourEntryBaseUrl(~slug, ~tourSlug, ~entryDir)
      let response = await Fetch.fetch(
        baseHref ++ "index.html",
        Fetch.requestInit(~method="GET", ()),
      )
      if Fetch.ok(response) {
        let html = await Fetch.text(response)
        Ok(injectBaseHref(~html, ~baseHref))
      } else if Fetch.status(response) == 404 {
        await tryCandidate(index + 1)
      } else {
        let body = await Fetch.text(response)
        Error(
          if body->String.trim != "" {
            body
          } else {
            "Unable to load this published tour."
          },
        )
      }
    }
  }
  await tryCandidate(0)
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
