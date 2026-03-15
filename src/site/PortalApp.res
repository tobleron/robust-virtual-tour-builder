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
    // Handle /u/{slug}/{accessCode}
    switch (Belt.Array.get(segments, 1), Belt.Array.get(segments, 2), Belt.Array.get(segments, 3)) {
    | (Some("u"), Some(slug), Some(accessCode)) =>
      // Redirect to /access/{accessCode} to establish session
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

let messageNode = (~flash: flash) => <>
  {switch flash.error {
  | Some(message) => <div className="portal-message is-error"> {React.string(message)} </div>
  | None => React.null
  }}
  {switch flash.success {
  | Some(message) => <div className="portal-message is-success"> {React.string(message)} </div>
  | None => React.null
  }}
</>

let brandLockup = (~title="ROBUST", ()) =>
  <span className="portal-brand-mark">
    <svg viewBox="0 0 24 24" fill="none" ariaHidden=true>
      <path
        d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" stroke="currentColor" strokeWidth="2"
      />
      <path d="M9 22V12h6v10" stroke="currentColor" strokeWidth="2" />
    </svg>
    <span> {React.string(title)} </span>
  </span>

let appBrandHeader = () =>
  <div className="portal-brand-stack">
    <span className="portal-brand-logo-lockup">
      <img
        className="portal-brand-logo" src="/images/logo.webp" alt="Robust Virtual Tour Builder logo"
      />
      <span className="portal-brand-product"> {React.string("Robust Virtual Tour Builder")} </span>
    </span>
  </div>

type adminIcon =
  | AddIcon
  | UploadIcon
  | SettingsIcon
  | DetailIcon
  | CopyIcon
  | CheckIcon
  | OpenIcon
  | PublishIcon
  | DraftIcon
  | ArchiveIcon
  | DeleteIcon
  | SaveIcon
  | LinkIcon
  | RevokeIcon

let adminActionIcon = icon =>
  <span className="portal-action-icon" ariaHidden=true>
    <svg viewBox="0 0 24 24" fill="none">
      {switch icon {
      | AddIcon =>
        <>
          <path d="M12 5v14" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
          <path d="M5 12h14" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
        </>
      | UploadIcon =>
        <>
          <path
            d="M12 15V5"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          <path
            d="m8 9 4-4 4 4"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          <path
            d="M5 19h14"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </>
      | SettingsIcon =>
        <>
          <path
            d="M12 8.5A3.5 3.5 0 1 0 12 15.5A3.5 3.5 0 1 0 12 8.5Z"
            stroke="currentColor"
            strokeWidth="2"
          />
          <path
            d="M19 12a7 7 0 0 0-.08-1l2.03-1.58-2-3.46-2.43.73a7.08 7.08 0 0 0-1.72-1l-.43-2.5h-4l-.43 2.5a7.08 7.08 0 0 0-1.72 1l-2.43-.73-2 3.46L5.08 11a7 7 0 0 0 0 2l-2.03 1.58 2 3.46 2.43-.73a7.08 7.08 0 0 0 1.72 1l.43 2.5h4l.43-2.5a7.08 7.08 0 0 0 1.72-1l2.43.73 2-3.46L18.92 13c.05-.33.08-.66.08-1Z"
            stroke="currentColor"
            strokeWidth="1.7"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </>
      | DetailIcon =>
        <>
          <path
            d="M4 12h16"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          <path
            d="m13 5 7 7-7 7"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </>
      | CopyIcon =>
        <>
          <rect x="9" y="9" width="10" height="10" rx="2" stroke="currentColor" strokeWidth="2" />
          <path
            d="M7 15H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h7a2 2 0 0 1 2 2v1"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </>
      | CheckIcon =>
        <>
          <path
            d="M6.5 12.5 10.2 16.2 17.5 8.9"
            stroke="currentColor"
            strokeWidth="2.2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </>
      | OpenIcon =>
        <>
          <path
            d="M14 5h5v5"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          <path
            d="m10 14 9-9"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          <path
            d="M19 14v3a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2h3"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </>
      | PublishIcon =>
        <>
          <path
            d="M7 13.5 10.5 17 17 8"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </>
      | DraftIcon =>
        <>
          <path d="M6 5h12" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
          <path d="M6 12h12" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
          <path d="M6 19h8" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
        </>
      | ArchiveIcon =>
        <>
          <path
            d="M4 7h16"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          <path
            d="M6 7h12v10a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2Z"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinejoin="round"
          />
          <path d="M10 11h4" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
        </>
      | DeleteIcon =>
        <>
          <path d="M5 7h14" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
          <path
            d="M9 7V5h6v2"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          <path
            d="M8 7v11a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1V7"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinejoin="round"
          />
          <path d="M10 11v4" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
          <path d="M14 11v4" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
        </>
      | SaveIcon =>
        <>
          <path
            d="M5 5h11l3 3v11H5Z" stroke="currentColor" strokeWidth="2" strokeLinejoin="round"
          />
          <path d="M8 5v5h7" stroke="currentColor" strokeWidth="2" strokeLinejoin="round" />
          <path d="M9 19v-5h6v5" stroke="currentColor" strokeWidth="2" strokeLinejoin="round" />
        </>
      | LinkIcon =>
        <>
          <path
            d="M10.5 13.5 13.5 10.5" stroke="currentColor" strokeWidth="2" strokeLinecap="round"
          />
          <path
            d="M8.5 15.5H7a4 4 0 1 1 0-8h1.5"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          <path
            d="M15.5 8.5H17a4 4 0 1 1 0 8h-1.5"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </>
      | RevokeIcon =>
        <>
          <path d="M8 8 16 16" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
          <path d="m16 8-8 8" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
          <circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="2" />
        </>
      }}
    </svg>
  </span>

let actionLabel = (~icon, ~label) => <>
  {adminActionIcon(icon)}
  <span> {React.string(label)} </span>
</>

module CopyActionButton = {
  @react.component
  let make = (
    ~url,
    ~className,
    ~ariaLabel,
    ~title,
    ~label="Copy",
    ~copiedLabel="Copied",
    ~disabled=false,
    ~iconOnly=false,
    ~onCopyError: option<string => unit>=?,
  ) => {
    let (isCopied, setIsCopied) = React.useState(() => false)
    let timeoutRef: React.ref<option<int>> = React.useRef(None)

    React.useEffect0(() => {
      Some(() => timeoutRef.current->Option.forEach(id => Window.clearTimeout(id)))
    })

    let handleClick = _ =>
      if !disabled {
        ignore(
          (
            async () => {
              try {
                let _ = await Clipboard.writeText(url)
                timeoutRef.current->Option.forEach(id => Window.clearTimeout(id))
                setIsCopied(_ => true)
                let timeoutId = Window.setTimeout(() => {
                  timeoutRef.current = None
                  setIsCopied(_ => false)
                }, 1600)
                timeoutRef.current = Some(timeoutId)
              } catch {
              | _ =>
                onCopyError->Option.forEach(report => report("Unable to copy link automatically."))
              }
            }
          )(),
        )
      }

    let icon = if isCopied {
      CheckIcon
    } else {
      CopyIcon
    }
    let resolvedLabel = if isCopied {
      copiedLabel
    } else {
      label
    }
    let resolvedTitle = if isCopied {
      copiedLabel
    } else {
      title
    }
    <button
      className={className ++ if isCopied {
        " is-copied"
      } else {
        ""
      }}
      disabled={disabled}
      ariaLabel
      title={resolvedTitle}
      onClick={handleClick}
    >
      {if iconOnly {
        adminActionIcon(icon)
      } else {
        actionLabel(~icon, ~label=resolvedLabel)
      }}
    </button>
  }
}

let mobileLabel = label => <small className="portal-mobile-label"> {React.string(label)} </small>

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

module AdminSignIn = {
  @react.component
  let make = (~flash, ~onSignIn) => {
    let (email, setEmail) = React.useState(() => "")
    let (password, setPassword) = React.useState(() => "")
    let (showPassword, setShowPassword) = React.useState(() => false)

    let submit = event => {
      ReactEvent.Form.preventDefault(event)
      ignore(onSignIn(email, password))
    }

    <div className="portal-shell">
      <main className="portal-main portal-auth-main">
        <section className="portal-hero portal-auth-card">
          {brandLockup()}
          <h1 className="portal-title"> {React.string("Portal Administration")} </h1>
          <p className="portal-subtitle">
            {React.string(
              "Sign in with your internal Robust account to manage portal recipients and tours.",
            )}
          </p>
          {messageNode(~flash)}
          <form className="portal-form" onSubmit={submit}>
            <div className="portal-form-grid">
              <label>
                {React.string("Email")}
                <input
                  value={email}
                  autoComplete="username"
                  onChange={e => setEmail(_ => ReactEvent.Form.target(e)["value"])}
                />
              </label>
              <label>
                {React.string("Password")}
                <div className="portal-password-input">
                  <input
                    type_={showPassword ? "text" : "password"}
                    value={password}
                    autoComplete="current-password"
                    onChange={e => setPassword(_ => ReactEvent.Form.target(e)["value"])}
                  />
                  <button
                    type_="button"
                    className="portal-password-toggle"
                    ariaLabel={showPassword ? "Hide password" : "Show password"}
                    title={showPassword ? "Hide password" : "Show password"}
                    onClick={_ => setShowPassword(isVisible => !isVisible)}
                  >
                    {React.string(showPassword ? "Hide" : "Show")}
                  </button>
                </div>
              </label>
            </div>
            <div className="portal-form-actions">
              <button className="site-btn site-btn-primary" type_="submit">
                {React.string("Sign In")}
              </button>
              <a className="site-btn site-btn-ghost" href="/forgot-password">
                {React.string("Reset Password")}
              </a>
            </div>
          </form>
        </section>
      </main>
    </div>
  }
}

module AdminSurface = {
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
    let (
      selectedBulkCustomerIds,
      setSelectedBulkCustomerIds,
    ) = React.useState((): Belt.Set.String.t => Belt.Set.String.empty)
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

    let fetchAdminData = async (): adminRefreshResult => {
      let session = await PortalApi.getAdminSession()
      if !session.authenticated {
        RefreshAuth
      } else {
        switch await PortalApi.loadSettings() {
        | Error(message) => RefreshError(message)
        | Ok(settings) =>
          switch await PortalApi.listCustomers() {
          | Error(message) => RefreshError(message)
          | Ok(customers) =>
            switch await PortalApi.listLibraryTours() {
            | Error(message) => RefreshError(message)
            | Ok(tours) => RefreshOk({session, settings, customers, tours})
            }
          }
        }
      }
    }

    let applyAdminData = payload => {
      setSelectedCustomerId(prev =>
        switch prev {
        | Some(customerId)
          if payload.customers->Belt.Array.some(customer => customer.customer.id == customerId) =>
          Some(customerId)
        | _ => payload.customers->Belt.Array.get(0)->Option.map(customer => customer.customer.id)
        }
      )
      setSelectedBulkCustomerIds(prev =>
        prev
        ->Belt.Set.String.toArray
        ->Belt.Array.keep(customerId =>
          payload.customers->Belt.Array.some(customer => customer.customer.id == customerId)
        )
        ->Belt.Array.reduce(Belt.Set.String.empty, (acc, customerId) =>
          acc->Belt.Set.String.add(customerId)
        )
      )
      setSelectedBulkTourIds(prev =>
        prev
        ->Belt.Set.String.toArray
        ->Belt.Array.keep(tourId => payload.tours->Belt.Array.some(tour => tour.tour.id == tourId))
        ->Belt.Array.reduce(Belt.Set.String.empty, (acc, tourId) =>
          acc->Belt.Set.String.add(tourId)
        )
      )
      setSettingsEdit(_ => Some(draftFromSettings(payload.settings)))
      setState(_ => Ready(payload))
    }

    let loadAdmin = (~preserveReadyState=false) => {
      if preserveReadyState {
        setIsRefreshing(_ => true)
      } else {
        setState(_ => Loading)
      }
      ignore(
        (
          async () => {
            switch await fetchAdminData() {
            | RefreshAuth => setState(_ => Failed("AUTH"))
            | RefreshError(message) => setState(_ => Failed(message))
            | RefreshOk(payload) => applyAdminData(payload)
            }
            setIsRefreshing(_ => false)
          }
        )(),
      )
    }

    React.useEffect0(() => {
      loadAdmin()
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

    let onAdminSignIn = async (email, password) => {
      switch await PortalApi.signInAdmin(~email, ~password) {
      | Ok() =>
        setFlash(_ => {error: None, success: Some("Signed in.")})
        loadAdmin()
      | Error(message) => setFlash(_ => {error: Some(message), success: None})
      }
    }

    let onChangePassword = async () => {
      if currentPassword->String.trim == "" || nextPassword->String.trim == "" {
        setFlash(_ => {
          success: None,
          error: Some("Current password and new password are required."),
        })
      } else if nextPassword != confirmNextPassword {
        setFlash(_ => {
          success: None,
          error: Some("New password confirmation does not match."),
        })
      } else {
        switch await PortalApi.changeAdminPassword(~currentPassword, ~newPassword=nextPassword) {
        | Ok() =>
          setCurrentPassword(_ => "")
          setNextPassword(_ => "")
          setConfirmNextPassword(_ => "")
          setShowPasswordPanel(_ => false)
          setFlash(_ => {
            success: Some("Password updated successfully."),
            error: None,
          })
        | Error(message) =>
          setFlash(_ => {
            success: None,
            error: Some(message),
          })
        }
      }
    }

    let onSaveSettings = async () => {
      switch settingsEdit {
      | None => ()
      | Some(draft) =>
        switch await PortalApi.updateSettings(
          ~settings={
            renewalHeading: draft.renewalHeading,
            renewalMessage: draft.renewalMessage,
            contactEmail: draft.contactEmail->String.trim == "" ? None : Some(draft.contactEmail),
            contactPhone: draft.contactPhone->String.trim == "" ? None : Some(draft.contactPhone),
            whatsappNumber: draft.whatsappNumber->String.trim == ""
              ? None
              : Some(draft.whatsappNumber),
          },
        ) {
        | Ok(settings) =>
          setSettingsEdit(_ => Some(draftFromSettings(settings)))
          setActiveDrawer(_ => NoDrawer)
          setFlash(_ => {error: None, success: Some("Renewal settings updated.")})
          loadAdmin(~preserveReadyState=true)
        | Error(message) => setFlash(_ => {error: Some(message), success: None})
        }
      }
    }

    let onCreateCustomer = async () => {
      let slug = createDraft.slug->String.trim
      let displayName = createDraft.displayName->String.trim
      let expiresAt = localDateTimeToIso(createDraft.expiresAt)
      switch await PortalApi.createCustomer(
        ~slug,
        ~displayName,
        ~expiresAt,
        ~recipientType=createDraft.recipientType,
        ~contactName=None,
        ~contactEmail=None,
        ~contactPhone=None,
      ) {
      | Ok(result) =>
        setLastGeneratedLinks(prev =>
          prev->Belt.Map.String.set(result.overview.customer.id, result.accessLink.accessUrl)
        )
        setCreateDraft(_ => {
          slug: "",
          displayName: "",
          expiresAt: nowPlusDaysIsoLocal(30),
          recipientType: PortalTypes.PropertyOwner,
        })
        setActiveDrawer(_ => NoDrawer)
        setFlash(_ => {error: None, success: Some("Customer created and access link generated.")})
        loadAdmin(~preserveReadyState=true)
      | Error(message) => setFlash(_ => {error: Some(message), success: None})
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
        setFlash(_ => {error: None, success: Some("Customer updated.")})
        loadAdmin(~preserveReadyState=true)
      | Error(message) => setFlash(_ => {error: Some(message), success: None})
      }
    }

    let onGenerateLink = async (customerId, expiryLocal) => {
      switch await PortalApi.regenerateAccessLink(
        ~customerId,
        ~expiresAt=localDateTimeToIso(expiryLocal),
      ) {
      | Ok(result) =>
        setLastGeneratedLinks(prev => prev->Belt.Map.String.set(customerId, result.accessUrl))
        setFlash(_ => {error: None, success: Some("New access link generated.")})
        loadAdmin(~preserveReadyState=true)
      | Error(message) => setFlash(_ => {error: Some(message), success: None})
      }
    }

    let onRevokeLink = async customerId => {
      switch await PortalApi.revokeAccessLink(~customerId) {
      | Ok(_) =>
        setLastGeneratedLinks(prev => prev->Belt.Map.String.remove(customerId))
        setFlash(_ => {error: None, success: Some("Access link revoked.")})
        loadAdmin(~preserveReadyState=true)
      | Error(message) => setFlash(_ => {error: Some(message), success: None})
      }
    }

    let onDeleteAccessLinks = async customerId => {
      if (
        Window.confirm("Delete all saved access links for this recipient? This cannot be undone.")
      ) {
        switch await PortalApi.deleteAccessLinks(~customerId) {
        | Ok(_) =>
          setLastGeneratedLinks(prev => prev->Belt.Map.String.remove(customerId))
          setFlash(_ => {error: None, success: Some("Access links deleted.")})
          loadAdmin(~preserveReadyState=true)
        | Error(message) => setFlash(_ => {error: Some(message), success: None})
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
          setLastGeneratedLinks(prev => prev->Belt.Map.String.remove(customerId))
          setCustomerDrafts(prev => prev->Belt.Map.String.remove(customerId))
          setExpiryDrafts(prev => prev->Belt.Map.String.remove(customerId))
          setSelectedCustomerId(_ => None)
          setFlash(_ => {error: None, success: Some("Recipient deleted.")})
          loadAdmin(~preserveReadyState=true)
        | Error(message) => setFlash(_ => {error: Some(message), success: None})
        }
      }
    }

    let onUploadTour = async () => {
      switch selectedUploadFile {
      | Some(file) =>
        Logger.info(~module_="PortalApp", ~message="Starting tour upload", ~data=Some({"title": uploadTitle, "fileSize": BrowserBindings.File.size(file)}), ())
        setFlash(_ => {error: None, success: Some("Starting upload...")})
        switch await PortalApi.uploadTour(~title=uploadTitle->String.trim, ~file) {
        | Ok(_) =>
          Logger.info(~module_="PortalApp", ~message="Tour upload successful", ~data=Some({"title": uploadTitle}), ())
          setUploadTitle(_ => "")
          setSelectedUploadFile(_ => None)
          setActiveDrawer(_ => NoDrawer)
          setFlash(_ => {error: None, success: Some("Tour uploaded to the library.")})
          loadAdmin(~preserveReadyState=true)
        | Error(message) =>
          Logger.error(~module_="PortalApp", ~message="Tour upload failed", ~data=Some({"error": message}), ())
          setFlash(_ => {error: Some(message), success: None})
        }
      | None => setFlash(_ => {error: Some("Choose a ZIP file first."), success: None})
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
        setFlash(_ => {
          error: None,
          success: Some(
            if assigned {
              "Tour unassigned."
            } else {
              "Tour assigned."
            },
          ),
        })
        loadAdmin(~preserveReadyState=true)
      | Error(message) => setFlash(_ => {error: Some(message), success: None})
      }
    }

    let onBulkAssign = async () => {
      let customerIds = selectedBulkCustomerIds->Belt.Set.String.toArray
      let tourIds = selectedBulkTourIds->Belt.Set.String.toArray
      switch await PortalApi.bulkAssignTours(~customerIds, ~tourIds) {
      | Ok(result) =>
        let message = if result.skippedCount > 0 {
          Belt.Int.toString(result.createdCount) ++
          " assignments created, " ++
          Belt.Int.toString(result.skippedCount) ++ " already existed."
        } else {
          Belt.Int.toString(result.createdCount) ++ " assignments created."
        }
        clearBulkSelections()
        setFlash(_ => {error: None, success: Some(message)})
        loadAdmin(~preserveReadyState=true)
      | Error(message) => setFlash(_ => {error: Some(message), success: None})
      }
    }

    let onTourStatus = async (~tourId, ~status) => {
      switch await PortalApi.updateTourStatus(~tourId, ~status) {
      | Ok(_) =>
        setFlash(_ => {error: None, success: Some("Tour status updated.")})
        loadAdmin(~preserveReadyState=true)
      | Error(message) => setFlash(_ => {error: Some(message), success: None})
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
          setFlash(_ => {error: None, success: Some("Tour deleted from library.")})
          loadAdmin(~preserveReadyState=true)
        | Error(message) => setFlash(_ => {error: Some(message), success: None})
        }
      }
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
    | Failed("AUTH") => <AdminSignIn.make flash onSignIn={onAdminSignIn} />
    | Failed(message) =>
      <AdminSignIn.make flash={...flash, error: Some(message)} onSignIn={onAdminSignIn} />
    | Idle => React.null
    | Ready(data) =>
      let settingsDraft = settingsEdit->Option.getOr(draftFromSettings(data.settings))
      let selectedOverview =
        selectedCustomerId->Option.flatMap(customerId =>
          findCustomerOverview(data.customers, customerId)
        )
      let filteredRecipients =
        data.customers->Belt.Array.keep(customerOverview =>
          matchesRecipientSearch(customerOverview, recipientSearch) &&
          matchesRecipientFilter(customerOverview, recipientFilter) &&
          matchesRecipientTypeFilter(customerOverview, recipientTypeFilter)
        )
      let (visibleRecipients, recipientTotal, recipientHasPrev, recipientHasNext) = paginateArray(
        filteredRecipients,
        recipientPage,
      )
      let filteredTours =
        data.tours->Belt.Array.keep(tourOverview =>
          matchesTourSearch(tourOverview, tourSearch) && matchesTourFilter(tourOverview, tourFilter)
        )
      let (visibleTours, tourTotal, tourHasPrev, tourHasNext) = paginateArray(
        filteredTours,
        tourPage,
      )
      let recipientPageCount = totalPages(recipientTotal)
      let tourPageCount = totalPages(tourTotal)
      let bulkCustomerIds = selectedBulkCustomerIds->Belt.Set.String.toArray
      let bulkTourIds = selectedBulkTourIds->Belt.Set.String.toArray
      let bulkSelectionCount = bulkCustomerIds->Belt.Array.length
      let bulkTourSelectionCount = bulkTourIds->Belt.Array.length
      let bulkRequestedAssignments = bulkSelectionCount * bulkTourSelectionCount
      let selectedBulkRecipients =
        data.customers->Belt.Array.keep(overview =>
          selectedBulkCustomerIds->Belt.Set.String.has(overview.customer.id)
        )
      let selectedBulkTours =
        data.tours->Belt.Array.keep(overview =>
          selectedBulkTourIds->Belt.Set.String.has(overview.tour.id)
        )
      let activeRecipientCount =
        data.customers->Belt.Array.keep(customer => customer.customer.isActive)->Belt.Array.length
      let publishedTourCount =
        data.tours->Belt.Array.keep(tour => tour.tour.status == "published")->Belt.Array.length
      let totalAssignments =
        data.tours->Belt.Array.reduce(0, (count, tour) => count + tour.assignmentCount)
      let drawerNode = switch activeDrawer {
      | NoDrawer => React.null
      | RecipientDrawer =>
        <div className="portal-drawer-backdrop" onClick={_ => setActiveDrawer(_ => NoDrawer)}>
          <aside
            className="portal-drawer" onClick={event => ReactEvent.Mouse.stopPropagation(event)}
          >
            <div className="portal-drawer-head">
              <div>
                <h2> {React.string("New recipient")} </h2>
                <p className="portal-card-muted">
                  {React.string("Create a private gallery link without re-uploading tours.")}
                </p>
              </div>
              <button
                className="site-btn site-btn-ghost" onClick={_ => setActiveDrawer(_ => NoDrawer)}
              >
                {React.string("Close")}
              </button>
            </div>
            <div className="portal-form-grid">
              <label>
                {React.string("Slug")}
                <input
                  value={createDraft.slug}
                  onChange={e =>
                    setCreateDraft(prev => {...prev, slug: ReactEvent.Form.target(e)["value"]})}
                />
              </label>
              <label>
                {React.string("Display name")}
                <input
                  value={createDraft.displayName}
                  onChange={e =>
                    setCreateDraft(prev => {
                      ...prev,
                      displayName: ReactEvent.Form.target(e)["value"],
                    })}
                />
              </label>
              <label>
                {React.string("Recipient type")}
                <select
                  value={createDraft.recipientType->recipientTypeValue}
                  onChange={e =>
                    setCreateDraft(prev => {
                      ...prev,
                      recipientType: ReactEvent.Form.target(e)["value"]->recipientTypeFromValue,
                    })}
                >
                  <option value="property_owner"> {React.string("Property owner")} </option>
                  <option value="broker"> {React.string("Broker")} </option>
                  <option value="property_owner_broker">
                    {React.string("Property owner & broker")}
                  </option>
                </select>
              </label>
              <label>
                {React.string("Access expiry")}
                <input
                  type_="datetime-local"
                  value={createDraft.expiresAt}
                  onChange={e =>
                    setCreateDraft(prev => {
                      ...prev,
                      expiresAt: ReactEvent.Form.target(e)["value"],
                    })}
                />
              </label>
            </div>
            <div className="portal-form-actions">
              <button
                className="site-btn site-btn-primary" onClick={_ => ignore(onCreateCustomer())}
              >
                {React.string("Create Recipient")}
              </button>
            </div>
          </aside>
        </div>
      | UploadDrawer =>
        <div className="portal-drawer-backdrop" onClick={_ => setActiveDrawer(_ => NoDrawer)}>
          <aside
            className="portal-drawer" onClick={event => ReactEvent.Mouse.stopPropagation(event)}
          >
            <div className="portal-drawer-head">
              <div>
                <h2> {React.string("Upload tour")} </h2>
                <p className="portal-card-muted">
                  {React.string("Add one reusable web_only ZIP containing 4K and 2K tours.")}
                </p>
              </div>
              <button
                className="site-btn site-btn-ghost" onClick={_ => setActiveDrawer(_ => NoDrawer)}
              >
                {React.string("Close")}
              </button>
            </div>
            <div className="portal-form-grid">
              <label>
                {React.string("Tour title")}
                <input
                  value={uploadTitle}
                  onChange={e => setUploadTitle(_ => ReactEvent.Form.target(e)["value"])}
                />
              </label>
              <label>
                {React.string("web_only ZIP")}
                <input
                  type_="file"
                  accept=".zip"
                  onChange={e => {
                    let fileOpt = switch filesFromInputTarget(ReactEvent.Form.target(e)) {
                    | Some(files) => FileList.item(files, 0)
                    | None => None
                    }
                    setSelectedUploadFile(_ => fileOpt)
                  }}
                />
              </label>
            </div>
            <div className="portal-form-actions">
              <button className="site-btn site-btn-primary" onClick={_ => ignore(onUploadTour())}>
                {React.string("Upload To Library")}
              </button>
            </div>
          </aside>
        </div>
      | SettingsDrawer =>
        <div className="portal-drawer-backdrop" onClick={_ => setActiveDrawer(_ => NoDrawer)}>
          <aside
            className="portal-drawer" onClick={event => ReactEvent.Mouse.stopPropagation(event)}
          >
            <div className="portal-drawer-head">
              <div>
                <h2> {React.string("Renewal settings")} </h2>
                <p className="portal-card-muted">
                  {React.string("This renewal message is shared by all expired links.")}
                </p>
              </div>
              <button
                className="site-btn site-btn-ghost" onClick={_ => setActiveDrawer(_ => NoDrawer)}
              >
                {React.string("Close")}
              </button>
            </div>
            <div className="portal-form-grid">
              <label>
                {React.string("Heading")}
                <input
                  value={settingsDraft.renewalHeading}
                  onChange={e =>
                    setSettingsEdit(_ => Some({
                      ...settingsDraft,
                      renewalHeading: ReactEvent.Form.target(e)["value"],
                    }))}
                />
              </label>
              <label>
                {React.string("Email")}
                <input
                  value={settingsDraft.contactEmail}
                  onChange={e =>
                    setSettingsEdit(_ => Some({
                      ...settingsDraft,
                      contactEmail: ReactEvent.Form.target(e)["value"],
                    }))}
                />
              </label>
              <label>
                {React.string("Phone")}
                <input
                  value={settingsDraft.contactPhone}
                  onChange={e =>
                    setSettingsEdit(_ => Some({
                      ...settingsDraft,
                      contactPhone: ReactEvent.Form.target(e)["value"],
                    }))}
                />
              </label>
              <label>
                {React.string("WhatsApp")}
                <input
                  value={settingsDraft.whatsappNumber}
                  onChange={e =>
                    setSettingsEdit(_ => Some({
                      ...settingsDraft,
                      whatsappNumber: ReactEvent.Form.target(e)["value"],
                    }))}
                />
              </label>
            </div>
            <label className="portal-form-field">
              <span> {React.string("Message")} </span>
              <textarea
                value={settingsDraft.renewalMessage}
                onChange={e =>
                  setSettingsEdit(_ => Some({
                    ...settingsDraft,
                    renewalMessage: ReactEvent.Form.target(e)["value"],
                  }))}
              />
            </label>
            <div className="portal-form-actions">
              <button className="site-btn site-btn-primary" onClick={_ => ignore(onSaveSettings())}>
                {React.string("Save Renewal Settings")}
              </button>
            </div>
          </aside>
        </div>
      }
      <div className="portal-shell">
        {drawerNode}
        <main className="portal-main">
          <section className="portal-hero">
            <div className="portal-hero-topbar">
              <div className="portal-hero-copy">
                {brandLockup()}
                <h1 className="portal-title">
                  {React.string("Customer Tour Portal Administration")}
                </h1>
                <p className="portal-subtitle">
                  {React.string(
                    "Manage recipients, shared tours, and expiring access links from one branded workspace.",
                  )}
                </p>
              </div>
              <div className="portal-inline-actions">
                <span className="portal-chip is-active">
                  {React.string(data.session.email->Option.getOr("portal-admin"))}
                </span>
                <button
                  className="site-btn site-btn-ghost"
                  onClick={_ => setShowPasswordPanel(isOpen => !isOpen)}
                >
                  {React.string(showPasswordPanel ? "Close Password" : "Change Password")}
                </button>
                <button
                  className="site-btn site-btn-ghost"
                  onClick={_ => {
                    ignore(
                      (
                        async () => {
                          let _ = await PortalApi.signOutAdmin()
                          assignLocation("/portal-admin/signin")
                        }
                      )(),
                    )
                  }}
                >
                  {React.string("Sign Out")}
                </button>
              </div>
            </div>
            <div className="portal-hero-status">
              {messageNode(~flash)}
              {isRefreshing
                ? <span className="portal-chip portal-refresh-indicator">
                    {React.string("Updating")}
                  </span>
                : React.null}
            </div>
            {showPasswordPanel
              ? <div className="portal-password-panel">
                  <div className="portal-form-grid">
                    <label>
                      {React.string("Current Password")}
                      <input
                        type_="password"
                        value={currentPassword}
                        onChange={e => setCurrentPassword(_ => ReactEvent.Form.target(e)["value"])}
                      />
                    </label>
                    <label>
                      {React.string("New Password")}
                      <input
                        type_="password"
                        value={nextPassword}
                        onChange={e => setNextPassword(_ => ReactEvent.Form.target(e)["value"])}
                      />
                    </label>
                    <label>
                      {React.string("Confirm New Password")}
                      <input
                        type_="password"
                        value={confirmNextPassword}
                        onChange={e =>
                          setConfirmNextPassword(_ => ReactEvent.Form.target(e)["value"])}
                      />
                    </label>
                  </div>
                  <div className="portal-form-actions">
                    <button
                      className="site-btn site-btn-primary"
                      onClick={_ => ignore(onChangePassword())}
                    >
                      {React.string("Update Password")}
                    </button>
                  </div>
                </div>
              : React.null}
            <div className="portal-stat-grid">
              <article className="portal-stat-card">
                <span className="portal-stat-label"> {React.string("Recipients")} </span>
                <strong className="portal-stat-value">
                  {React.string(Belt.Int.toString(data.customers->Belt.Array.length))}
                </strong>
              </article>
              <article className="portal-stat-card">
                <span className="portal-stat-label"> {React.string("Active")} </span>
                <strong className="portal-stat-value">
                  {React.string(Belt.Int.toString(activeRecipientCount))}
                </strong>
              </article>
              <article className="portal-stat-card">
                <span className="portal-stat-label"> {React.string("Published tours")} </span>
                <strong className="portal-stat-value">
                  {React.string(Belt.Int.toString(publishedTourCount))}
                </strong>
              </article>
              <article className="portal-stat-card">
                <span className="portal-stat-label"> {React.string("Assignments")} </span>
                <strong className="portal-stat-value">
                  {React.string(Belt.Int.toString(totalAssignments))}
                </strong>
              </article>
            </div>
          </section>

          <section className="portal-admin-dashboard">
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
                    onClick={_ => setActiveDrawer(_ => RecipientDrawer)}
                  >
                    {actionLabel(~icon=AddIcon, ~label="New recipient")}
                  </button>
                  <button
                    className="site-btn site-btn-ghost portal-toolbar-btn"
                    onClick={_ => setActiveDrawer(_ => UploadDrawer)}
                  >
                    {actionLabel(~icon=UploadIcon, ~label="Upload tour")}
                  </button>
                  <button
                    className="site-btn site-btn-ghost portal-toolbar-btn"
                    onClick={_ => setActiveDrawer(_ => SettingsDrawer)}
                  >
                    {actionLabel(~icon=SettingsIcon, ~label="Renewals")}
                  </button>
                  <button
                    className={"site-btn portal-toolbar-btn " ++ (
                      assignmentMode == BulkAssignMode ? "site-btn-primary" : "site-btn-ghost"
                    )}
                    onClick={_ =>
                      assignmentMode == BulkAssignMode
                        ? exitBulkMode()
                        : setAssignmentMode(_ => BulkAssignMode)}
                  >
                    {actionLabel(
                      ~icon=assignmentMode == BulkAssignMode ? RevokeIcon : AddIcon,
                      ~label=assignmentMode == BulkAssignMode ? "Exit bulk mode" : "Bulk assign",
                    )}
                  </button>
                </div>
                <div className="portal-toolbar-filters">
                  <label className="portal-search-field">
                    <span> {React.string("Search recipients")} </span>
                    <input
                      placeholder="Name or slug"
                      value={recipientSearch}
                      onChange={e => {
                        setRecipientSearch(_ => ReactEvent.Form.target(e)["value"])
                        setRecipientPage(_ => 0)
                      }}
                    />
                  </label>
                  <label className="portal-inline-field">
                    <span> {React.string("Status")} </span>
                    <select
                      value={switch recipientFilter {
                      | RecipientAll => "all"
                      | RecipientActive => "active"
                      | RecipientAttention => "attention"
                      }}
                      onChange={e => {
                        let value = ReactEvent.Form.target(e)["value"]
                        setRecipientFilter(_ =>
                          switch value {
                          | "active" => RecipientActive
                          | "attention" => RecipientAttention
                          | _ => RecipientAll
                          }
                        )
                        setRecipientPage(_ => 0)
                      }}
                    >
                      <option value="all"> {React.string("All")} </option>
                      <option value="active"> {React.string("Active")} </option>
                      <option value="attention"> {React.string("Revoked / Missing")} </option>
                    </select>
                  </label>
                  <label className="portal-inline-field">
                    <span> {React.string("Type")} </span>
                    <select
                      value={switch recipientTypeFilter {
                      | RecipientTypeAll => "all"
                      | RecipientTypePropertyOwner => "property_owner"
                      | RecipientTypeBroker => "broker"
                      | RecipientTypePropertyOwnerBroker => "property_owner_broker"
                      }}
                      onChange={e => {
                        let value = ReactEvent.Form.target(e)["value"]
                        setRecipientTypeFilter(_ =>
                          switch value {
                          | "property_owner" => RecipientTypePropertyOwner
                          | "broker" => RecipientTypeBroker
                          | "property_owner_broker" => RecipientTypePropertyOwnerBroker
                          | _ => RecipientTypeAll
                          }
                        )
                        setRecipientPage(_ => 0)
                      }}
                    >
                      <option value="all"> {React.string("All types")} </option>
                      <option value="property_owner"> {React.string("Property owner")} </option>
                      <option value="broker"> {React.string("Broker")} </option>
                      <option value="property_owner_broker">
                        {React.string("Property owner & broker")}
                      </option>
                    </select>
                  </label>
                </div>
              </div>
            </article>

            <div className="portal-admin-main">
              <article className="portal-card">
                <div className="portal-section-head">
                  <div>
                    <h2> {React.string("Recipient directory")} </h2>
                    <p className="portal-card-muted">
                      {React.string(
                        "Scan status, expiry, and recent activity in one full-width workspace table.",
                      )}
                    </p>
                  </div>
                  <div className="portal-inline-actions">
                    <span className="portal-chip">
                      {React.string(
                        "Showing " ++
                        Belt.Int.toString(visibleRecipients->Belt.Array.length) ++
                        " of " ++
                        Belt.Int.toString(recipientTotal),
                      )}
                    </span>
                    {assignmentMode == BulkAssignMode && bulkSelectionCount > 0
                      ? <span className="portal-chip is-active">
                          {React.string(Belt.Int.toString(bulkSelectionCount) ++ " selected")}
                        </span>
                      : React.null}
                  </div>
                </div>
                <div className="portal-table-scroll">
                  <div className="portal-recipient-table">
                    <div className="portal-table-head portal-recipient-table-head">
                      <span> {React.string("Recipient")} </span>
                      <span> {React.string("Tours")} </span>
                      <span> {React.string("Access")} </span>
                      <span> {React.string("Expiry")} </span>
                      <span> {React.string("Last opened")} </span>
                      <span>
                        {React.string(assignmentMode == BulkAssignMode ? "Select" : "Open")}
                      </span>
                    </div>
                    {switch recipientTotal {
                    | 0 =>
                      <div className="portal-empty-inline">
                        {React.string("No recipients match the current filters.")}
                      </div>
                    | _ =>
                      visibleRecipients
                      ->Belt.Array.map(customerOverview => {
                        let isSelected =
                          selectedCustomerId
                          ->Option.map(id => id == customerOverview.customer.id)
                          ->Option.getOr(false)
                        let isBulkSelected =
                          selectedBulkCustomerIds->Belt.Set.String.has(customerOverview.customer.id)
                        let expiryText =
                          customerOverview.accessLink
                          ->Option.map(link => isoToLocalDateTime(link.expiresAt))
                          ->Option.getOr("Not generated")
                        let lastOpenedText =
                          customerOverview.accessLink
                          ->Option.flatMap(link => link.lastOpenedAt)
                          ->Option.map(isoToLocalDateTime)
                          ->Option.getOr("Never")
                        let (accessLabel, accessClass) = recipientAccessLabel(customerOverview)
                        <button
                          key={customerOverview.customer.id}
                          className={"portal-recipient-row " ++ (
                            assignmentMode == BulkAssignMode
                              ? isBulkSelected ? "is-selected" : ""
                              : isSelected
                              ? "is-selected"
                              : ""
                          )}
                          ariaLabel={(
                            assignmentMode == BulkAssignMode
                              ? "Select recipient "
                              : "Open recipient "
                          ) ++
                          customerOverview.customer.displayName}
                          onClick={_ =>
                            assignmentMode == BulkAssignMode
                              ? toggleBulkCustomerSelection(customerOverview.customer.id)
                              : setSelectedCustomerId(_ => Some(customerOverview.customer.id))}
                        >
                          <span className="portal-table-cell portal-table-cell-primary">
                            {mobileLabel("Recipient")}
                            <span className="portal-row-primary">
                              <span className="portal-row-primary-title">
                                {assignmentMode == BulkAssignMode
                                  ? <input
                                      type_="checkbox" checked={isBulkSelected} readOnly=true
                                    />
                                  : React.null}
                                <strong>
                                  {React.string(customerOverview.customer.displayName)}
                                </strong>
                              </span>
                              <span className="portal-chip-row portal-chip-row-compact">
                                <span className="portal-chip portal-chip-subtle">
                                  {React.string(
                                    customerOverview.customer.recipientType->recipientTypeLabel,
                                  )}
                                </span>
                                <small> {React.string(customerOverview.customer.slug)} </small>
                              </span>
                            </span>
                          </span>
                          <span className="portal-table-cell portal-table-cell-number">
                            {mobileLabel("Tours")}
                            <strong className="portal-row-number">
                              {React.string(Belt.Int.toString(customerOverview.tourCount))}
                            </strong>
                          </span>
                          <span className="portal-table-cell">
                            {mobileLabel("Access")}
                            <span className={"portal-chip " ++ accessClass}>
                              {React.string(accessLabel)}
                            </span>
                          </span>
                          <span className="portal-table-cell">
                            {mobileLabel("Expiry")}
                            <span className="portal-row-muted"> {React.string(expiryText)} </span>
                          </span>
                          <span className="portal-table-cell">
                            {mobileLabel("Last opened")}
                            <span className="portal-row-muted">
                              {React.string(lastOpenedText)}
                            </span>
                          </span>
                          <span className="portal-table-cell portal-table-cell-action">
                            {mobileLabel(assignmentMode == BulkAssignMode ? "Select" : "Open")}
                            <span className="portal-table-action-chip">
                              {actionLabel(
                                ~icon=assignmentMode == BulkAssignMode
                                  ? isBulkSelected ? CheckIcon : AddIcon
                                  : DetailIcon,
                                ~label=assignmentMode == BulkAssignMode
                                  ? isBulkSelected ? "Selected" : "Select"
                                  : "Details",
                              )}
                            </span>
                          </span>
                        </button>
                      })
                      ->React.array
                    }}
                  </div>
                </div>
                <div className="portal-pagination">
                  <button
                    className="site-btn site-btn-ghost"
                    disabled={!recipientHasPrev}
                    onClick={_ => recipientHasPrev ? setRecipientPage(prev => prev - 1) : ()}
                  >
                    {React.string("Previous")}
                  </button>
                  <span className="portal-row-muted">
                    {React.string(
                      "Page " ++
                      Belt.Int.toString(recipientPage + 1) ++
                      " of " ++
                      Belt.Int.toString(recipientPageCount),
                    )}
                  </span>
                  <button
                    className="site-btn site-btn-ghost"
                    disabled={!recipientHasNext}
                    onClick={_ => recipientHasNext ? setRecipientPage(prev => prev + 1) : ()}
                  >
                    {React.string("Next")}
                  </button>
                </div>
              </article>

              {assignmentMode == BulkAssignMode
                ? <article className="portal-card portal-bulk-inspector-card">
                    <div className="portal-section-head">
                      <div>
                        <h2> {React.string("Bulk assignment")} </h2>
                        <p className="portal-card-muted">
                          {React.string(
                            "Select recipients on the left and tours below, then assign that full combination in one action.",
                          )}
                        </p>
                      </div>
                      <div className="portal-chip-row">
                        <span className="portal-chip is-active">
                          {React.string(Belt.Int.toString(bulkSelectionCount) ++ " recipients")}
                        </span>
                        <span className="portal-chip is-active">
                          {React.string(Belt.Int.toString(bulkTourSelectionCount) ++ " tours")}
                        </span>
                        <span className="portal-chip">
                          {React.string(
                            Belt.Int.toString(bulkRequestedAssignments) ++ " assignments",
                          )}
                        </span>
                      </div>
                    </div>
                    <div className="portal-bulk-inspector-grid">
                      <div className="portal-detail-card">
                        <span className="portal-link-label">
                          {React.string("Recipients selected")}
                        </span>
                        {switch selectedBulkRecipients->Belt.Array.length {
                        | 0 =>
                          <div className="portal-empty-inline">
                            {React.string(
                              "Pick one or more recipients from the directory to start the assignment set.",
                            )}
                          </div>
                        | _ =>
                          <div className="portal-selection-chip-list">
                            {selectedBulkRecipients
                            ->Belt.Array.map(overview =>
                              <span key={overview.customer.id} className="portal-selection-chip">
                                {React.string(
                                  overview.customer.displayName ++
                                  " · " ++
                                  overview.customer.recipientType->recipientTypeLabel,
                                )}
                              </span>
                            )
                            ->React.array}
                          </div>
                        }}
                      </div>
                      <div className="portal-detail-card">
                        <span className="portal-link-label">
                          {React.string("Tours selected")}
                        </span>
                        {switch selectedBulkTours->Belt.Array.length {
                        | 0 =>
                          <div className="portal-empty-inline">
                            {React.string(
                              "Pick one or more tours from the library to build the assignment set.",
                            )}
                          </div>
                        | _ =>
                          <div className="portal-selection-chip-list">
                            {selectedBulkTours
                            ->Belt.Array.map(overview =>
                              <span key={overview.tour.id} className="portal-selection-chip">
                                {React.string(overview.tour.title)}
                              </span>
                            )
                            ->React.array}
                          </div>
                        }}
                      </div>
                    </div>
                    <div className="portal-bulk-inspector-preview">
                      <span className="portal-link-label"> {React.string("Preview")} </span>
                      <p className="portal-card-muted">
                        {React.string(
                          "Existing assignments are left untouched and skipped automatically. Only missing links are created.",
                        )}
                      </p>
                    </div>
                  </article>
                : switch selectedOverview {
                  | None =>
                    <article className="portal-card portal-empty-state">
                      <h2> {React.string("No recipient selected")} </h2>
                      <p className="portal-card-muted">
                        {React.string(
                          "Select a recipient from the directory to manage links, status, and assignments.",
                        )}
                      </p>
                    </article>
                  | Some(customerOverview) =>
                    let customerId = customerOverview.customer.id
                    let customerDraft =
                      customerDrafts
                      ->Belt.Map.String.get(customerId)
                      ->Option.getOr(customerDraftFromOverview(customerOverview))
                    let expiryDraft =
                      expiryDrafts
                      ->Belt.Map.String.get(customerId)
                      ->Option.getOr(
                        customerOverview.accessLink
                        ->Option.map(link => isoToLocalDateTime(link.expiresAt))
                        ->Option.getOr(nowPlusDaysIsoLocal(30)),
                      )
                    let lastLink = lastGeneratedLinks->Belt.Map.String.get(customerId)
                    let activeAccessUrl =
                      lastLink->Option.orElse(
                        customerOverview.accessLink->Option.flatMap(link => link.accessUrl),
                      )
                    let galleryExpiryLabel = if expiryDraft == "" {
                      "Set an expiry before sharing."
                    } else {
                      "Expires " ++ expiryDraft
                    }
                    <article className="portal-card portal-recipient-detail-card">
                      <div className="portal-section-head">
                        <div>
                          <h2> {React.string("Recipient detail")} </h2>
                          <p className="portal-card-muted">
                            {React.string("Recipient ID: " ++ customerId)}
                          </p>
                        </div>
                        <div className="portal-chip-row">
                          <span
                            className={"portal-chip " ++ (
                              customerDraft.isActive ? "is-active" : "is-expired"
                            )}
                          >
                            {React.string(
                              if customerDraft.isActive {
                                "Active"
                              } else {
                                "Inactive"
                              },
                            )}
                          </span>
                          <span className="portal-chip portal-chip-subtle">
                            {React.string(customerDraft.recipientType->recipientTypeLabel)}
                          </span>
                          <span className="portal-chip">
                            {React.string(
                              Belt.Int.toString(customerOverview.tourCount) ++ " tours",
                            )}
                          </span>
                        </div>
                      </div>
                      <div className="portal-detail-grid">
                        <div className="portal-detail-card">
                          <div className="portal-form-grid">
                            <label>
                              {React.string("Display name")}
                              <input
                                value={customerDraft.displayName}
                                onChange={e =>
                                  updateCustomerDraft(customerId, draft => {
                                    ...draft,
                                    displayName: ReactEvent.Form.target(e)["value"],
                                  })}
                              />
                            </label>
                            <label>
                              {React.string("Recipient type")}
                              <select
                                value={customerDraft.recipientType->recipientTypeValue}
                                onChange={e =>
                                  updateCustomerDraft(customerId, draft => {
                                    ...draft,
                                    recipientType: ReactEvent.Form.target(
                                      e,
                                    )["value"]->recipientTypeFromValue,
                                  })}
                              >
                                <option value="property_owner">
                                  {React.string("Property owner")}
                                </option>
                                <option value="broker"> {React.string("Broker")} </option>
                                <option value="property_owner_broker">
                                  {React.string("Property owner & broker")}
                                </option>
                              </select>
                            </label>
                            <label>
                              {React.string("Slug")}
                              <input readOnly=true value={customerOverview.customer.slug} />
                            </label>
                            <label>
                              {React.string("Access expiry")}
                              <input
                                type_="datetime-local"
                                value={expiryDraft}
                                onChange={e =>
                                  updateExpiryDraft(customerId, ReactEvent.Form.target(e)["value"])}
                              />
                            </label>
                            <label className="portal-toggle-field">
                              <span> {React.string("Recipient status")} </span>
                              <span className="portal-toggle-control">
                                <input
                                  type_="checkbox"
                                  checked={customerDraft.isActive}
                                  onChange={_ =>
                                    updateCustomerDraft(customerId, draft => {
                                      ...draft,
                                      isActive: !draft.isActive,
                                    })}
                                />
                                <strong>
                                  {React.string(
                                    if customerDraft.isActive {
                                      "Recipient active"
                                    } else {
                                      "Recipient inactive"
                                    },
                                  )}
                                </strong>
                              </span>
                            </label>
                          </div>
                          <div className="portal-inline-actions portal-inline-actions-compact">
                            <button
                              className="site-btn site-btn-ghost portal-compact-btn"
                              onClick={_ => ignore(onUpdateCustomer(customerId, customerDraft))}
                            >
                              {actionLabel(~icon=SaveIcon, ~label="Save")}
                            </button>
                            <button
                              className="site-btn site-btn-primary portal-compact-btn"
                              onClick={_ => ignore(onGenerateLink(customerId, expiryDraft))}
                            >
                              {actionLabel(~icon=LinkIcon, ~label="Generate")}
                            </button>
                            <button
                              className="site-btn site-btn-ghost portal-compact-btn"
                              onClick={_ => ignore(onRevokeLink(customerId))}
                            >
                              {actionLabel(~icon=RevokeIcon, ~label="Revoke")}
                            </button>
                          </div>
                        </div>
                        <div className="portal-detail-card portal-detail-card-danger">
                          <span className="portal-link-label"> {React.string("Danger zone")} </span>
                          <p className="portal-card-muted">
                            {React.string(
                              "Remove links or recipients only when cleaning invalid data or test records.",
                            )}
                          </p>
                          <div className="portal-inline-actions portal-inline-actions-compact">
                            <button
                              className="site-btn site-btn-ghost portal-compact-btn is-destructive"
                              onClick={_ => ignore(onDeleteAccessLinks(customerId))}
                            >
                              {actionLabel(~icon=DeleteIcon, ~label="Delete link")}
                            </button>
                            <button
                              className="site-btn site-btn-ghost portal-compact-btn is-destructive"
                              onClick={_ => ignore(onDeleteCustomer(customerId))}
                            >
                              {actionLabel(~icon=DeleteIcon, ~label="Delete recipient")}
                            </button>
                          </div>
                        </div>
                      </div>
                      <div className="portal-section-head portal-section-head-tight">
                        <div>
                          <h3> {React.string("Access delivery")} </h3>
                          <p className="portal-card-muted">
                            {React.string(
                              "Share the gallery with the client, or use direct broker links for assigned tours.",
                            )}
                          </p>
                        </div>
                      </div>
                      {switch activeAccessUrl {
                      | Some(url) =>
                        <div className="portal-link-panel">
                          <div className="portal-link-card">
                            <div className="portal-link-copy">
                              <span className="portal-link-label">
                                {React.string("Gallery access")}
                              </span>
                              <a
                                className="portal-link-anchor"
                                href={url}
                                target="_blank"
                                rel="noreferrer"
                              >
                                {React.string("Open secure gallery")}
                              </a>
                              <span className="portal-link-meta">
                                {React.string(galleryExpiryLabel)}
                              </span>
                              <span className="portal-link-value">
                                {React.string(
                                  "Copy to share the private gallery URL, or open it to verify the experience first.",
                                )}
                              </span>
                            </div>
                            <div className="portal-inline-actions portal-inline-actions-compact">
                              <CopyActionButton
                                className="site-btn site-btn-ghost portal-compact-btn portal-copy-btn"
                                url
                                label="Copy"
                                copiedLabel="Copied"
                                ariaLabel="Copy gallery link"
                                title="Copy gallery link"
                                onCopyError={message =>
                                  setFlash(_ => {error: Some(message), success: None})}
                              />
                              <button
                                className="site-btn site-btn-ghost portal-compact-btn"
                                onClick={_ => Window.openWindow(url, "_blank")}
                              >
                                {actionLabel(~icon=OpenIcon, ~label="Open")}
                              </button>
                            </div>
                          </div>
                        </div>
                      | None =>
                        <div className="portal-empty-inline">
                          {React.string(
                            "Generate an access link to start sharing this recipient gallery.",
                          )}
                        </div>
                      }}
                      <div className="portal-section-head">
                        <div>
                          <h3> {React.string("Tour assignments")} </h3>
                          <p className="portal-card-muted">
                            {React.string(
                              "Assign tours here, then use copy/open actions once a gallery link is active.",
                            )}
                          </p>
                        </div>
                      </div>
                      <div className="portal-table-scroll">
                        <div className="portal-assignment-table">
                          <div className="portal-table-head portal-assignment-table-head">
                            <span> {React.string("Tour")} </span>
                            <span> {React.string("Status")} </span>
                            <span> {React.string("Direct link")} </span>
                            <span> {React.string("Action")} </span>
                          </div>
                          {data.tours
                          ->Belt.Array.map(tourOverview => {
                            let assigned =
                              customerOverview.assignedTourIds->Belt.Array.some(id =>
                                id == tourOverview.tour.id
                              )
                            <div key={tourOverview.tour.id} className="portal-assignment-row">
                              <span className="portal-table-cell portal-table-cell-primary">
                                {mobileLabel("Tour")}
                                <span className="portal-row-primary">
                                  <strong> {React.string(tourOverview.tour.title)} </strong>
                                  <small> {React.string("ID: " ++ tourOverview.tour.id)} </small>
                                </span>
                              </span>
                              <span className="portal-table-cell">
                                {mobileLabel("Status")}
                                <span
                                  className={"portal-chip " ++ (
                                    tourOverview.tour.status == "published" ? "is-published" : ""
                                  )}
                                >
                                  {React.string(tourOverview.tour.status)}
                                </span>
                              </span>
                              <span className="portal-table-cell">
                                {mobileLabel("Direct link")}
                                {switch activeAccessUrl {
                                | Some(accessUrl) if assigned => {
                                    let directUrl = directTourAccessUrl(
                                      ~accessUrl,
                                      ~tourSlug=tourOverview.tour.slug,
                                    )
                                    <div className="portal-link-summary">
                                      <a
                                        className="portal-link-anchor is-inline"
                                        href={directUrl}
                                        target="_blank"
                                        rel="noreferrer"
                                      >
                                        {React.string("Open direct access link")}
                                      </a>
                                      <small className="portal-row-muted">
                                        {React.string(
                                          "Bypasses the gallery and opens this assigned tour immediately.",
                                        )}
                                      </small>
                                      <div
                                        className="portal-inline-actions portal-inline-actions-compact"
                                      >
                                        <CopyActionButton
                                          className="site-btn site-btn-ghost portal-compact-btn portal-copy-btn"
                                          url={directUrl}
                                          label="Copy"
                                          copiedLabel="Copied"
                                          ariaLabel={"Copy direct tour link for " ++
                                          tourOverview.tour.title}
                                          title={"Copy direct tour link for " ++
                                          tourOverview.tour.title}
                                          onCopyError={message =>
                                            setFlash(_ => {error: Some(message), success: None})}
                                        />
                                        <button
                                          className="site-btn site-btn-ghost portal-compact-btn"
                                          onClick={_ => Window.openWindow(directUrl, "_blank")}
                                        >
                                          {actionLabel(~icon=OpenIcon, ~label="Open")}
                                        </button>
                                      </div>
                                    </div>
                                  }
                                | _ =>
                                  <span className="portal-row-muted">
                                    {React.string(
                                      if assigned {
                                        "Generate link first"
                                      } else {
                                        "Assign to enable"
                                      },
                                    )}
                                  </span>
                                }}
                              </span>
                              <span className="portal-table-cell portal-table-cell-action">
                                {mobileLabel("Action")}
                                <div className="portal-table-action-cluster">
                                  <button
                                    className={"site-btn site-btn-ghost portal-compact-btn " ++ (
                                      assigned ? "is-active-state" : ""
                                    )}
                                    onClick={_ =>
                                      ignore(
                                        onAssignToggle(
                                          ~customerId,
                                          ~tourId=tourOverview.tour.id,
                                          ~assigned,
                                        ),
                                      )}
                                  >
                                    {actionLabel(
                                      ~icon=assigned ? RevokeIcon : AddIcon,
                                      ~label=assigned ? "Remove" : "Assign",
                                    )}
                                  </button>
                                </div>
                              </span>
                            </div>
                          })
                          ->React.array}
                        </div>
                      </div>
                    </article>
                  }}

              <article className="portal-card">
                <div className="portal-section-head">
                  <div>
                    <h2> {React.string("Tour library")} </h2>
                    <p className="portal-card-muted">
                      {React.string(
                        "Keep the tour library dense and reusable so assignments stay quick to operate.",
                      )}
                    </p>
                  </div>
                  <div className="portal-section-tools">
                    {assignmentMode == BulkAssignMode && bulkTourSelectionCount > 0
                      ? <span className="portal-chip is-active portal-selection-count-chip">
                          {React.string(Belt.Int.toString(bulkTourSelectionCount) ++ " selected")}
                        </span>
                      : React.null}
                    <label className="portal-search-field">
                      <span> {React.string("Search tours")} </span>
                      <input
                        placeholder="Title, slug, or ID"
                        value={tourSearch}
                        onChange={e => {
                          setTourSearch(_ => ReactEvent.Form.target(e)["value"])
                          setTourPage(_ => 0)
                        }}
                      />
                    </label>
                    <label className="portal-inline-field">
                      <span> {React.string("Status")} </span>
                      <select
                        value={switch tourFilter {
                        | TourAll => "all"
                        | TourPublished => "published"
                        | TourDraft => "draft"
                        | TourArchived => "archived"
                        }}
                        onChange={e => {
                          let value = ReactEvent.Form.target(e)["value"]
                          setTourFilter(_ =>
                            switch value {
                            | "published" => TourPublished
                            | "draft" => TourDraft
                            | "archived" => TourArchived
                            | _ => TourAll
                            }
                          )
                          setTourPage(_ => 0)
                        }}
                      >
                        <option value="all"> {React.string("All")} </option>
                        <option value="published"> {React.string("Published")} </option>
                        <option value="draft"> {React.string("Draft")} </option>
                        <option value="archived"> {React.string("Archived")} </option>
                      </select>
                    </label>
                  </div>
                </div>
                <div className="portal-table-scroll">
                  <div className="portal-library-table">
                    <div className="portal-table-head portal-library-table-head">
                      <span> {React.string("Tour")} </span>
                      <span> {React.string("Status")} </span>
                      <span> {React.string("Assignments")} </span>
                      <span>
                        {React.string(assignmentMode == BulkAssignMode ? "Select" : "Actions")}
                      </span>
                    </div>
                    {visibleTours
                    ->Belt.Array.map(tourOverview => {
                      let isPublished = tourOverview.tour.status == "published"
                      let isDraft = tourOverview.tour.status == "draft"
                      let isArchived = tourOverview.tour.status == "archived"
                      let isBulkSelected =
                        selectedBulkTourIds->Belt.Set.String.has(tourOverview.tour.id)
                      <div key={tourOverview.tour.id} className="portal-library-row">
                        <span className="portal-table-cell portal-table-cell-primary">
                          {mobileLabel("Tour")}
                          <span className="portal-row-primary">
                            <span className="portal-row-primary-title">
                              {assignmentMode == BulkAssignMode
                                ? <input type_="checkbox" checked={isBulkSelected} readOnly=true />
                                : React.null}
                              <strong> {React.string(tourOverview.tour.title)} </strong>
                            </span>
                            <small>
                              {React.string(
                                "ID: " ++ tourOverview.tour.id ++ " · " ++ tourOverview.tour.slug,
                              )}
                            </small>
                          </span>
                        </span>
                        <span className="portal-table-cell">
                          {mobileLabel("Status")}
                          <span className={"portal-chip " ++ (isPublished ? "is-published" : "")}>
                            {React.string(tourOverview.tour.status)}
                          </span>
                        </span>
                        <span className="portal-table-cell portal-table-cell-number">
                          {mobileLabel("Assignments")}
                          <strong className="portal-row-number">
                            {React.string(Belt.Int.toString(tourOverview.assignmentCount))}
                          </strong>
                        </span>
                        <span className="portal-table-cell portal-table-cell-action">
                          {mobileLabel(assignmentMode == BulkAssignMode ? "Select" : "Actions")}
                          {assignmentMode == BulkAssignMode
                            ? <button
                                className={"site-btn site-btn-ghost portal-compact-btn " ++ (
                                  isBulkSelected ? "is-active-state" : ""
                                )}
                                onClick={_ => toggleBulkTourSelection(tourOverview.tour.id)}
                              >
                                {actionLabel(
                                  ~icon=isBulkSelected ? CheckIcon : AddIcon,
                                  ~label=isBulkSelected ? "Selected" : "Select",
                                )}
                              </button>
                            : <div className="portal-table-action-cluster">
                                <button
                                  className={"site-btn site-btn-ghost portal-compact-btn " ++ (
                                    isPublished ? "is-current-status" : ""
                                  )}
                                  disabled={isPublished}
                                  onClick={_ =>
                                    ignore(
                                      onTourStatus(
                                        ~tourId=tourOverview.tour.id,
                                        ~status="published",
                                      ),
                                    )}
                                >
                                  {actionLabel(~icon=PublishIcon, ~label="Pub")}
                                </button>
                                <button
                                  className={"site-btn site-btn-ghost portal-compact-btn " ++ (
                                    isDraft ? "is-current-status" : ""
                                  )}
                                  disabled={isDraft}
                                  onClick={_ =>
                                    ignore(
                                      onTourStatus(~tourId=tourOverview.tour.id, ~status="draft"),
                                    )}
                                >
                                  {actionLabel(~icon=DraftIcon, ~label="Draft")}
                                </button>
                                <button
                                  className={"site-btn site-btn-ghost portal-compact-btn " ++ (
                                    isArchived ? "is-current-status" : ""
                                  )}
                                  disabled={isArchived}
                                  onClick={_ =>
                                    ignore(
                                      onTourStatus(
                                        ~tourId=tourOverview.tour.id,
                                        ~status="archived",
                                      ),
                                    )}
                                >
                                  {actionLabel(~icon=ArchiveIcon, ~label="Arch")}
                                </button>
                                <button
                                  className="site-btn site-btn-ghost portal-compact-btn is-destructive"
                                  ariaLabel={"Delete tour " ++ tourOverview.tour.title}
                                  onClick={_ =>
                                    ignore(
                                      onDeleteTour(
                                        ~tourId=tourOverview.tour.id,
                                        ~title=tourOverview.tour.title,
                                      ),
                                    )}
                                >
                                  {actionLabel(~icon=DeleteIcon, ~label="Delete")}
                                </button>
                              </div>}
                        </span>
                      </div>
                    })
                    ->React.array}
                  </div>
                </div>
                <div className="portal-pagination">
                  <button
                    className="site-btn site-btn-ghost"
                    disabled={!tourHasPrev}
                    onClick={_ => tourHasPrev ? setTourPage(prev => prev - 1) : ()}
                  >
                    {React.string("Previous")}
                  </button>
                  <span className="portal-row-muted">
                    {React.string(
                      "Page " ++
                      Belt.Int.toString(tourPage + 1) ++
                      " of " ++
                      Belt.Int.toString(tourPageCount) ++
                      " · " ++
                      Belt.Int.toString(visibleTours->Belt.Array.length) ++ " visible",
                    )}
                  </span>
                  <button
                    className="site-btn site-btn-ghost"
                    disabled={!tourHasNext}
                    onClick={_ => tourHasNext ? setTourPage(prev => prev + 1) : ()}
                  >
                    {React.string("Next")}
                  </button>
                </div>
              </article>
              {assignmentMode == BulkAssignMode
                ? <div className="portal-bulk-bar">
                    <div className="portal-bulk-bar-copy">
                      <strong>
                        {React.string(
                          Belt.Int.toString(bulkSelectionCount) ++
                          " recipients x " ++
                          Belt.Int.toString(bulkTourSelectionCount) ++ " tours",
                        )}
                      </strong>
                      <span className="portal-row-muted">
                        {React.string(
                          Belt.Int.toString(
                            bulkRequestedAssignments,
                          ) ++ " assignments will be created or skipped if they already exist.",
                        )}
                      </span>
                    </div>
                    <div className="portal-inline-actions portal-inline-actions-compact">
                      <button
                        className="site-btn site-btn-ghost portal-toolbar-btn"
                        onClick={_ => setSelectedBulkCustomerIds(_ => Belt.Set.String.empty)}
                      >
                        {React.string("Clear recipients")}
                      </button>
                      <button
                        className="site-btn site-btn-ghost portal-toolbar-btn"
                        onClick={_ => setSelectedBulkTourIds(_ => Belt.Set.String.empty)}
                      >
                        {React.string("Clear tours")}
                      </button>
                      <button
                        className="site-btn site-btn-ghost portal-toolbar-btn"
                        onClick={_ => clearBulkSelections()}
                      >
                        {React.string("Clear all")}
                      </button>
                      <button
                        className="site-btn site-btn-primary portal-toolbar-btn"
                        disabled={bulkRequestedAssignments == 0}
                        onClick={_ => ignore(onBulkAssign())}
                      >
                        {React.string("Assign selected")}
                      </button>
                    </div>
                  </div>
                : React.null}
            </div>
          </section>
        </main>
      </div>
    }
  }
}

module CustomerSurface = {
  @react.component
  let make = (~slug, ~tourSlug: option<string>) => {
    let (publicState, setPublicState) = React.useState((): remoteData<PortalTypes.publicView> =>
      Loading
    )
    let (sessionState, setSessionState) = React.useState((): remoteData<
      PortalTypes.customerSession,
    > => Idle)
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
        | Some(value) =>
          <span className="portal-chip"> {React.string("WhatsApp: " ++ value)} </span>
        | None => React.null
        }}
      </div>

    let renderGate = (publicView: PortalTypes.publicView) =>
      <div className="portal-shell">
        <main className="portal-main portal-customer-main">
          <section className="portal-hero portal-customer-hero">
            {appBrandHeader()}
            <h1 className="portal-title"> {React.string(publicView.customer.displayName)} </h1>
            <p className="portal-subtitle"> {React.string("Private customer gallery.")} </p>
            {switch accessMessage {
            | Some(message) =>
              <div className="portal-message is-error"> {React.string(message)} </div>
            | None =>
              <div className="portal-message">
                {React.string("Open this portal through your private access link.")}
              </div>
            }}
          </section>
          <section className="portal-card">
            <h2> {React.string(publicView.settings.renewalHeading)} </h2>
            <p className="portal-card-muted">
              {React.string(publicView.settings.renewalMessage)}
            </p>
            {renewalLines(publicView.settings)}
          </section>
        </main>
      </div>

    switch publicState {
    | Loading =>
      <div className="portal-shell">
        <main className="portal-main portal-customer-main">
          <section className="portal-hero portal-customer-hero">
            {appBrandHeader()}
            <h1 className="portal-title"> {React.string("Loading portal...")} </h1>
          </section>
        </main>
      </div>
    | Failed(message) =>
      <div className="portal-shell">
        <main className="portal-main portal-customer-main">
          <section className="portal-hero portal-customer-hero">
            {appBrandHeader()}
            <h1 className="portal-title"> {React.string("Portal unavailable")} </h1>
            <div className="portal-message is-error"> {React.string(message)} </div>
          </section>
        </main>
      </div>
    | Idle => React.null
    | Ready(publicView) =>
      switch sessionState {
      | Failed("NO_SESSION") => renderGate(publicView)
      | Failed(_) => renderGate(publicView)
      | Loading =>
        <div className="portal-shell">
          <main className="portal-main portal-customer-main">
            <section className="portal-hero portal-customer-hero">
              {appBrandHeader()}
              <h1 className="portal-title"> {React.string("Loading access...")} </h1>
            </section>
          </main>
        </div>
      | Idle => renderGate(publicView)
      | Ready(session) =>
        switch tourSlug {
        | Some(_) =>
          if session.canOpenTours {
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
                  <button className="site-btn site-btn-ghost" onClick={_ => signOut()}>
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
          } else {
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
          }
        | None =>
          switch galleryState {
          | Loading =>
            <div className="portal-shell">
              <main className="portal-main portal-customer-main">
                <section className="portal-hero portal-customer-hero">
                  {appBrandHeader()}
                  <h1 className="portal-title"> {React.string(session.customer.displayName)} </h1>
                  <p className="portal-subtitle"> {React.string("Loading tours...")} </p>
                </section>
              </main>
            </div>
          | Failed(message) =>
            <div className="portal-shell">
              <main className="portal-main portal-customer-main">
                <section className="portal-hero portal-customer-hero">
                  {appBrandHeader()}
                  <h1 className="portal-title"> {React.string(session.customer.displayName)} </h1>
                  <div className="portal-message is-error"> {React.string(message)} </div>
                </section>
              </main>
            </div>
          | Idle => renderGate(publicView)
          | Ready(gallery) =>
            let totalTours = gallery.tours->Belt.Array.length
            let openableTours =
              gallery.tours->Belt.Array.keep(tour => tour.canOpen)->Belt.Array.length
            let expiresLabel = friendlyDateTimeLabel(gallery.accessLink.expiresAt)
            <div className="portal-shell">
              <main className="portal-main portal-customer-main">
                <section className="portal-hero portal-customer-hero">
                  <div className="portal-hero-topbar">
                    <div className="portal-hero-copy">
                      {appBrandHeader()}
                      <h1 className="portal-title">
                        {React.string(gallery.customer.displayName)}
                      </h1>
                      <p className="portal-subtitle">
                        {React.string("Private customer gallery.")}
                      </p>
                    </div>
                    <div className="portal-inline-actions">
                      <button className="site-btn site-btn-ghost" onClick={_ => signOut()}>
                        {React.string("Sign Out")}
                      </button>
                    </div>
                  </div>
                  <div className="portal-customer-meta">
                    <span
                      className={"portal-chip " ++ (
                        gallery.canOpenTours ? "is-active" : "is-expired"
                      )}
                    >
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
                      <p className="portal-card-muted">
                        {React.string(gallery.settings.renewalMessage)}
                      </p>
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
                              <div className="portal-tour-cover-fallback">
                                {React.string(tour.title)}
                              </div>
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
                                <span className="portal-chip is-active">
                                  {React.string("Ready")}
                                </span>
                              } else {
                                <span className="portal-chip is-locked">
                                  {React.string("Locked")}
                                </span>
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
        }
      }
    }
  }
}

@react.component
let make = () => {
  let route = parseRoute()

  React.useEffect1(() => {
    switch route {
    | Landing => setDocumentTitle(documentRef, "Robust Virtual Tour Builder | Portal")
    | AdminSignin => setDocumentTitle(documentRef, "Robust Portal | Admin Sign In")
    | AdminDashboard => setDocumentTitle(documentRef, "Robust Portal | Admin")
    | CustomerPortal(slug) | CustomerTour(slug, _) =>
      setDocumentTitle(documentRef, "Robust Portal | " ++ slug)
    }
    None
  }, [route])

  switch route {
  | Landing =>
    <div className="portal-shell">
      <main className="portal-main">
        <section className="portal-hero">
          {brandLockup()}
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
  | AdminSignin | AdminDashboard => <AdminSurface />
  | CustomerPortal(slug) => <CustomerSurface slug tourSlug=None />
  | CustomerTour(slug, tourSlug) => <CustomerSurface slug tourSlug=Some(tourSlug) />
  }
}
