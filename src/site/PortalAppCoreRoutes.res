// @efficiency-role: util-pure
open ReBindings

type route =
  | Landing
  | AdminSignin
  | AdminDashboard
  | CustomerPortal(string)
  | CustomerTour(string, string)

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
@new external makeUrlSearchParams: string => {..} = "URLSearchParams"
@send @return(nullable) external getSearchParam: ({..}, string) => option<string> = "get"
@val external encodeURIComponent: string => string = "encodeURIComponent"

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

let routeAccessMessage = () => {
  let params = makeUrlSearchParams(search)
  switch getSearchParam(params, "access") {
  | Some("expired") => Some("This private access link has expired or is no longer active.")
  | Some("invalid") => Some("This private access link is invalid.")
  | _ => None
  }
}

let customerPortalPath = slug => "/u/" ++ encodeURIComponent(slug)

let customerTourPath = (~slug, ~tourSlug) =>
  customerPortalPath(slug) ++ "/tour/" ++ encodeURIComponent(tourSlug)

let directTourAccessUrl = (~accessUrl, ~tourSlug) =>
  accessUrl ++ "/tour/" ++ encodeURIComponent(tourSlug)

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
